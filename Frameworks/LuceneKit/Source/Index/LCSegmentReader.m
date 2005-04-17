#include "index/LCSegmentReader.h"
#include "index/LCSegmentTermPositions.h"
#include "Document/LCDocument.h"
#include "Store/LCIndexInput.h"
#include "Store/LCIndexOutput.h"
#include "Store/LCDirectory.h"
#include "Index/LCFieldsReader.h"
#include "Index/LCTermVectorsReader.h"
#include "Index/LCTermInfo.h"
#include "GNUstep/GNUstep.h"

/**
 * FIXME: Describe class <code>SegmentReader</code> here.
 *
 * @version $Id$
 */
@interface LCNorm: NSObject
{
	  LCSegmentReader *reader;
	    LCIndexInput *input;
	      NSMutableData *bytes;
	        BOOL dirty;
		  int number;
}

- (id) initWithSegmentReader: (LCSegmentReader *) r
        indexInput: (LCIndexInput *) input number: (int) number;
	- (void) rewrite;
	- (LCIndexInput *) input;
	- (BOOL) dirty;
	- (void) setDirty: (BOOL) d;
	- (NSData *) bytes;
	- (void) setBytes: (NSData *) bytes;
	@end


@implementation LCNorm

- (id) initWithSegmentReader: (LCSegmentReader *) r
                  indexInput: (LCIndexInput *) inp number: (int) num
{
  self = [super init];
  ASSIGN(reader, r);
  ASSIGN(input, inp);
  bytes = [[NSMutableData alloc] init];
  number = num;
  return self;
}

- (void) dealloc
{
  RELEASE(reader);
  RELEASE(input);
  RELEASE(bytes);
  [super dealloc];
}
	
- (void) rewrite
{
  // NOTE: norms are re-written in regular directory, not cfs
  LCIndexOutput *out = [[reader directory] createOutput: [[reader segment] stringByAppendingPathExtension: @"tmp"]];
  [out writeBytes: bytes length: [reader maxDoc]];
  [out close];
      
  NSString *fileName;
  if([reader cfsReader] == nil)
    fileName = [NSString stringWithFormat: @"%@.f%d", [reader segment], number];
  else{ 
          // use a different file name if we have compound format
        fileName = [NSString stringWithFormat: @"%@.s%d", [reader segment], number];
      }
  [[reader directory] renameFile: [[reader segment] stringByAppendingPathExtension: @"tmp"]
	              to: fileName];
  dirty = NO;
}

- (BOOL) dirty
{
  return dirty;
}

- (void) setDirty: (BOOL) b
{
  dirty = b;
}

- (NSData *) bytes
{
  return bytes;
}

- (void) setBytes: (NSData *) b
{
  [bytes setData: b];
}

- (LCIndexInput *) input
{
  return input;
}

@end

@interface LCSegmentReader (LCPrivate)
- (void) initWithSegmentInfo: (LCSegmentInfo *) si;
- (void) openNorms: (id <LCDirectory>) cfsDir;
- (void) closeNorms;
- (LCTermVectorsReader *) termVectorsReader;

@end

@implementation LCSegmentReader: LCIndexReader

- (id) init
{
  self = [super init];
  deletedDocsDirty = NO;
  normsDirty = NO;
  undeleteAll = NO;
  norms = [[NSMutableDictionary alloc] init];
  termVectorsReaderOrig = nil;
  return self;
}

- (void) dealloc
{
  RELEASE(norms);
  RELEASE(segment);
  RELEASE(fieldInfos);
  RELEASE(fieldsReader);
  RELEASE(tis);
  RELEASE(termVectorsReaderOrig);
  RELEASE(deletedDocs);
  RELEASE(freqStream);
  RELEASE(proxStream);
  RELEASE(cfsReader);
  [super dealloc];
}

+ (id) segmentReaderWithInfo: (LCSegmentInfo *) si
{
  return [LCSegmentReader segmentReaderWithDirectory: [si directory]
	                    info: si
			    infos: nil
			    close: NO
			    owner: NO];
}

+ (id) segmentReaderWithInfos: (LCSegmentInfos *) sis
                         info: (LCSegmentInfo *) si
                        close: (BOOL) closeDir
{
  return [LCSegmentReader segmentReaderWithDirectory: [si directory]
	          info: si
		  infos: sis
		  close: closeDir
		  owner: YES];
}

+ (id) segmentReaderWithDirectory: (id <LCDirectory>) dir
                            info: (LCSegmentInfo *) si
                            infos: (LCSegmentInfos *) sis
                            close: (BOOL) closeDir
                            owner: (BOOL) ownDir
{
    LCSegmentReader *instance = [[LCSegmentReader alloc] initWithDirectory: dir
	                    segmentInfos: sis
			    closeDirectory: closeDir
			    directoryOwner: ownDir];
    [instance initWithSegmentInfo: si];
    return instance;
}
          
- (void) initWithSegmentInfo: (LCSegmentInfo *) si
{
  ASSIGN(segment, [si name]);
  // Use compound file directory for some files, if it exists
  id <LCDirectory> cfsDir;
  ASSIGN(cfsDir, [self directory]);
  NSString *file = [segment stringByAppendingPathExtension: @"cfs"];
    if ([directory fileExists: file]) {
      cfsReader = [[LCCompoundFileReader alloc] initWithDirectory: [self directory] name: file];
      ASSIGN(cfsDir, cfsReader);
    }

    // No compound file exists - use the multi-file format
    file = [segment stringByAppendingPathExtension: @"fnm"];
    fieldInfos = [[LCFieldInfos alloc] initWithDirectory: cfsDir name: file];
    fieldsReader = [[LCFieldsReader alloc] initWithDirectory: cfsDir
	                                    segment: segment
					    fieldInfos: fieldInfos];
					 
    tis = [[LCTermInfosReader alloc] initWithDirectory: cfsDir
	                             segment: segment
				     fieldInfos: fieldInfos];

    // NOTE: the bitvector is stored using the regular directory, not cfs
    if ([LCSegmentReader hasDeletions: si])
    {
      file = [segment stringByAppendingPathExtension: @"del"];
      deletedDocs = [[LCBitVector alloc] initWithDirectory: [self directory]
	                                     andName: file];
    }

    // make sure that all index files have been read or are kept open
    // so that if an index update removes them we'll still have them
    file = [segment stringByAppendingPathExtension: @"frq"];
    freqStream = [cfsDir openInput: file];
    file = [segment stringByAppendingPathExtension: @"prx"];
    proxStream = [cfsDir openInput: file];
    [self openNorms: cfsDir];

    if ([fieldInfos hasVectors]) { // open term vector files only as needed
      termVectorsReaderOrig = [[LCTermVectorsReader alloc] initWithDirectory: cfsDir segment: segment fieldInfos: fieldInfos];
    }
  }
   
- (void) doCommit
{
  NSString *file;
  if (deletedDocsDirty) {               // re-write deleted 
    file = [segment stringByAppendingPathExtension: @"tmp"];
    [deletedDocs writeToDirectory: [self directory]
	               withName: file];
    [[self directory] renameFile: file
	    to: [segment stringByAppendingPathExtension: @"del"]];
    }

    file = [segment stringByAppendingPathExtension: @"del"];
    if(undeleteAll && [[self directory] fileExists:  file]){
      [[self directory] deleteFile: file];
    }
    if (normsDirty) {               // re-write norms 
      NSEnumerator *values = [norms objectEnumerator];
      LCNorm *norm;
      while ((norm = [values nextObject])) {
        if ([norm dirty]) {
          [norm rewrite];
        }
      }
    }

    deletedDocsDirty = NO;
    normsDirty = NO;
    undeleteAll = NO;
  }
  
- (void) doClose
{
    [fieldsReader close];
    [tis close];

    if (freqStream != nil)
      [freqStream close];
    if (proxStream != nil)
      [proxStream close];

    [self closeNorms];
    
    if (termVectorsReaderOrig != nil) 
      [termVectorsReaderOrig close];

    if (cfsReader != nil)
      [cfsReader close];
  }

+ (BOOL) hasDeletions: (LCSegmentInfo *) si
{
  return [[si directory] fileExists: [[si name] stringByAppendingPathExtension: @"del"]];
}

- (BOOL) hasDeletions
{
    return deletedDocs != nil;
}

+ (BOOL) usesCompoundFile: (LCSegmentInfo *) si
{
  return [[si directory] fileExists: [[si name] stringByAppendingPathExtension: @"cfs"]];
  }
  
+ (BOOL) hasSeparateNorms: (LCSegmentInfo *) si
{
  NSArray *result = [[si directory] list];
  NSString *pattern = [[si name] stringByAppendingPathExtension: @"s"];
  int patternLength = [pattern length];
  int i;
  for(i = 0; i < [result count]; i++){
    unichar ch = [[result objectAtIndex: i] characterAtIndex: patternLength];
    if (([[result objectAtIndex: i] hasPrefix: pattern]) &&
		    ((ch >= '0') && (ch <= '9') /* isDigit */))
        return YES;
    }
    return NO;
  }

- (void) doDelete: (int) docNum
{
    if (deletedDocs == nil)
      deletedDocs = [[LCBitVector alloc] initWithSize: [self maxDoc]];
    deletedDocsDirty = YES;
    undeleteAll = NO;
    [deletedDocs setBit: docNum];
  }

- (void) doUndeleteAll
{
      deletedDocs = nil;
      deletedDocsDirty = NO;
      undeleteAll = YES;
  }

- (NSArray *) files
{
  NSMutableArray *files = [[NSMutableArray alloc] init];
  NSArray *ext = [NSArray arrayWithObjects: @"cfs", @"fnm",
      @"fdx", @"fdt", @"tii", @"tis", @"frq", @"prx", @"del",
      @"tvx", @"tvd", @"tvf", @"tvp", nil];

  int i;
  for (i = 0; i < [ext count]; i++) {
      NSString *name = [NSString stringWithFormat: @"%@.%@", segment, [ext objectAtIndex: i]];
      if ([[self directory] fileExists: name])
        [files addObject: name];
    }

    for (i = 0; i < [fieldInfos size]; i++) {
      LCFieldInfo *fi = [fieldInfos fieldInfoWithNumber: i];
      if ([fi isIndexed]){
        NSString *name;
        if(cfsReader == nil)
            name = [NSString stringWithFormat: @"%@.f%d", segment, i];
        else
            name = [NSString stringWithFormat: @"%@.s%d", segment, i];
        if ([[self directory] fileExists: name])
            [files addObject: name];
      }
    }
    return files;
  }

- (LCTermEnum *) terms
{
    return (LCTermEnum *)[tis terms];
}

- (LCTermEnum *) termsWithTerm: (LCTerm *) t
{
    return (LCTermEnum *)[tis termsWithTerm: t];
}

- (LCDocument *) document: (int) n
{
    if ([self isDeleted: n])
    {
      NSLog(@"attempt to access a deleted document");
      return nil;
    }
    return [fieldsReader document: n];
  }

- (BOOL) isDeleted: (int) n
{
    return (deletedDocs != nil && [deletedDocs getBit: n]);
  }

- (id <LCTermDocs>) termDocs
{
  return [[LCSegmentTermDocs alloc] initWithSegmentReader: self];
}

- (id <LCTermPositions>) termPositions
{
  return [[LCSegmentTermPositions alloc] initWithSegmentReader: self];
}

- (long) documentFrequency: (LCTerm *) t
{
    LCTermInfo *ti = [tis termInfo: t];
    if (ti != nil)
    {
      return [ti documentFrequency];
    }
    else
      return 0;
  }

- (int) numDocs
{
    int n = [self maxDoc];
    if (deletedDocs != nil)
    {
      n -= [deletedDocs count];
    }
    return n;
  }

- (int) maxDoc
{
  if (fieldsReader)
    return [fieldsReader size];
  else
  {
    NSLog(@"No FieldsReader");
    return 0;
    }
  }

  /**
   * @see IndexReader#getFieldNames(IndexReader.FieldOption fldOption)
   */
- (NSArray *) fieldNames: (LCFieldOption) fieldOption
{
  NSMutableArray *fieldSet = [[NSMutableArray alloc] init];
  int i;
  for (i = 0; i < [fieldInfos size]; i++) {
      LCFieldInfo *fi = [fieldInfos fieldInfoWithNumber: i];
      if (fieldOption == LCFieldOption_ALL) {
        [fieldSet addObject: [fi name]];
      }
      else if (![fi isIndexed] && fieldOption == LCFieldOption_UNINDEXED) {
        [fieldSet addObject: [fi name]];
      }
      else if ([fi isIndexed] && fieldOption == LCFieldOption_INDEXED) {
        [fieldSet addObject: [fi name]];
      }
      else if ([fi isIndexed] && [fi isTermVectorStored] == NO && 
         fieldOption == LCFieldOption_INDEXED_NO_TERMVECTOR) {
        [fieldSet addObject: [fi name]];
      }
      else if ([fi isTermVectorStored] == YES &&
               [fi isPositionWithTermVectorStored] == NO &&
               [fi isOffsetWithTermVectorStored] == NO &&
               fieldOption == LCFieldOption_TERMVECTOR) {
        [fieldSet addObject: [fi name]];
      }
      else if ([fi isIndexed] && [fi isTermVectorStored] && fieldOption == LCFieldOption_INDEXED_WITH_TERMVECTOR) {
        [fieldSet addObject: [fi name]];
      }
      else if ([fi isPositionWithTermVectorStored] && [fi isOffsetWithTermVectorStored] == NO && fieldOption == LCFieldOption_TERMVECTOR_WITH_POSITION) {
        [fieldSet addObject: [fi name]];
      }
      else if ([fi isOffsetWithTermVectorStored] && [fi isPositionWithTermVectorStored] == NO && fieldOption == LCFieldOption_TERMVECTOR_WITH_OFFSET) {
        [fieldSet addObject: [fi name]];
      }
      else if (([fi isOffsetWithTermVectorStored] && [fi isPositionWithTermVectorStored]) &&
                fieldOption == LCFieldOption_TERMVECTOR_WITH_POSITION_OFFSET) {
        [fieldSet addObject: [fi name]];
      }
    }
    return fieldSet;
  }
  
- (NSData *) norms: (NSString *) field
{
    LCNorm *norm = (LCNorm *) [norms objectForKey: field];
    if (norm == nil)                             // not an indexed field
      return nil;
    if ([norm bytes] == nil) {                     // value not yet read
      NSMutableData *bytes = [[NSMutableData alloc] init];
      [self setNorms: field bytes: bytes offset: 0];
      [norm setBytes: bytes]; // cache it
    }
    return [norm bytes];
  }

- (void) doSetNorm: (int) doc field: (NSString *) field charValue: (char) value
{
  LCNorm *norm = (LCNorm *) [norms objectForKey: field];
    if (norm == nil)                             // not an indexed field
      return;
    [norm setDirty: YES];                            // mark it dirty
    normsDirty = YES;

#if 0 // FIXME: don't know what it do
    norms(field)[doc] = value;                    // set the value
#endif
  }

  /** Read norms into a pre-allocated array. */
- (void) setNorms: (NSString *) field
            bytes: (NSMutableData *) bytes offset: (int) offset
{
    LCNorm *norm = (LCNorm *) [norms objectForKey: field];
    if (norm == nil)
      return;					  // use zeros in array

    if ([norm bytes] != nil) {                     // can copy from cache
      NSRange r = NSMakeRange(offset, [self maxDoc]);
      [bytes replaceBytesInRange: r withBytes: [norm bytes]];
      return;
    }

    LCIndexInput *normStream = (LCIndexInput *) [[norm input] copy];
                                       // read from disk
    [normStream seek: 0];
    [normStream readBytes: bytes offset: offset length: [self maxDoc]];
    [normStream close];
  }

- (void) openNorms: (id <LCDirectory>) cfsDir
{
  int i;
  id <LCDirectory> d;
  NSString *fileName;
  for (i = 0; i < [fieldInfos size]; i++) {
    LCFieldInfo *fi = [fieldInfos fieldInfoWithNumber: i];
    if ([fi isIndexed]) {
      // look first if there are separate norms in compound f%ormat
      fileName = [NSString stringWithFormat: @"%@.s%d", segment, [fi number]];
      d = [self directory];
      if([d fileExists: fileName] == NO){
        fileName = [NSString stringWithFormat: @"%@.f%d", segment, [fi number]];
	d = cfsDir;
      }
      [norms setObject: [[LCNorm alloc] initWithSegmentReader: self
		  indexInput: [d openInput: fileName] number: [fi number]]
		forKey: [fi name]];
      }
    }
  }

- (void) closeNorms
{
  NSEnumerator *e = [norms objectEnumerator];
  LCNorm *norm;
      while ((norm = [e nextObject])) {
        [[norm input] close];
      }
  }
  
  /**
   * Create a clone from the initial TermVectorsReader and store it in the ThreadLocal.
   * @return TermVectorsReader
   */
- (LCTermVectorsReader *) termVectorsReader
{
#if 0
  TermVectorsReader tvReader = (TermVectorsReader)termVectorsLocal.get();
  if (tvReader == null) {
    tvReader = (TermVectorsReader)termVectorsReaderOrig.clone();
    termVectorsLocal.set(tvReader);
  }
#else
  // FIXME: Not thread safe
  return termVectorsReaderOrig;
#endif
#if 0
    if (tvReader == nil) {
      tvReader = (LCTermVectorsReader *)[termVectorsReaderOrig copy];
    }
    return tvReader;
#endif
}
  
  /** Return a term frequency vector for the specified document and field. The
   *  vector returned contains term numbers and frequencies for all terms in
   *  the specified field of this document, if the field had storeTermVector
   *  flag set.  If the flag was not set, the method returns null.
   * @throws IOException
   */
- (id <LCTermFreqVector>) termFreqVector: (int) docNumber
             field: (NSString *) field
{
    // Check if this field is invalid or has no stored term vector
    LCFieldInfo *fi = [fieldInfos fieldInfo: field];
    if (fi == nil|| ![fi isTermVectorStored] || termVectorsReaderOrig == nil) 
      return nil;
    
    LCTermVectorsReader *termVectorsReader = [self termVectorsReader];
    if (termVectorsReader == nil)
      return nil;
    
    return [termVectorsReader termFreqVectorWithDocument: docNumber
	                       field: field];
  }


  /** Return an array of term frequency vectors for the specified document.
   *  The array contains a vector for each vectorized field in the document.
   *  Each vector vector contains term numbers and frequencies for all terms
   *  in a given vectorized field.
   *  If no such fields existed, the method returns null.
   * @throws IOException
   */
- (NSArray *) termFreqVectors: (int) docNumber
{
    if (termVectorsReaderOrig == nil)
      return nil;
    
    LCTermVectorsReader *termVectorsReader = [self termVectorsReader];
    if (termVectorsReader == nil)
      return nil;
    
    return [termVectorsReader termFreqVectorsWithDocument: docNumber];
}

- (NSString *) segment
{
  return segment;
}

- (LCCompoundFileReader *) cfsReader
{
  return cfsReader;
}

- (LCIndexInput *) freqStream
{
  return freqStream;
}

- (LCIndexInput *) proxStream
{
  return proxStream;
}

- (LCFieldInfos *) fieldInfos
{
  return fieldInfos;
}

- (LCBitVector *) deletedDocs
{
  return deletedDocs;
}

- (LCTermInfosReader *) termInfosReader
{
  return tis;
}

@end
