#include "Index/LCTermVectorsWriter.h"
#include "Store/LCIndexOutput.h"
#include "Index/LCFieldInfos.h"
#include "Index/LCFieldInfo.h"
#include "Index/LCTermFreqVector.h"
#include "Index/LCTermPositionVector.h"
#include "Index/LCTermVectorOffsetInfo.h"
#include "Util/NSString+Additions.h"
#include "GNUstep/GNUstep.h"

/**
 * Writer works by opening a document and then opening the fields within the document and then
 * writing out the vectors for each field.
 * 
 * Rough usage:
 *
 <CODE>
 for each document
 {
 writer.openDocument();
 for each field on the document
 {
 writer.openField(field);
 for all of the terms
 {
 writer.addTerm(...)
 }
 writer.closeField
 }
 writer.closeDocument()    
 }
 </CODE>
 *
 * @version $Id$
 * 
 */
@implementation LCTermVectorsWriter
- (id) initWithDirectory: (id <LCDirectory>) directory
               segment: (NSString *) segment
               fieldInfos: (LCFieldInfos *) fis
{
  self = [super init];
    // Open files for TermVector storage
    NSString *file;
    file = [segment stringByAppendingPathExtension: TVX_EXTENSION];
    tvx = [directory createOutput: file];
    [tvx writeInt: (long)TERM_VECTORS_WRITER_FORMAT_VERSION];
    file = [segment stringByAppendingPathExtension: TVD_EXTENSION];
    tvd = [directory createOutput: file];
    [tvd writeInt: (long)TERM_VECTORS_WRITER_FORMAT_VERSION];
    file = [segment stringByAppendingPathExtension: TVF_EXTENSION];
    tvf = [directory createOutput: file];
    [tvf writeInt: (long)TERM_VECTORS_WRITER_FORMAT_VERSION];

    ASSIGN(fieldInfos, fis);
    fields = [[NSMutableArray alloc] init];
    terms = [[NSMutableArray alloc] init];
    currentDocPointer = -1;
    return self;
}

- (void) openDocument
{
  [self closeDocument];
  currentDocPointer = [tvd filePointer];
}

- (void) closeDocument
{
  if ([self isDocumentOpen]) {
    [self closeField];
    [self writeDoc];
    [fields removeAllObjects];
    currentDocPointer = -1;
  }
}

- (BOOL) isDocumentOpen
{
  return currentDocPointer != -1;
}

  /** Start processing a field. This can be followed by a number of calls to
   *  addTerm, and a final call to closeField to indicate the end of
   *  processing of this field. If a field was previously open, it is
   *  closed automatically.
   */
- (void) openField: (NSString *) field
{
  LCFieldInfo *fieldInfo = [fieldInfos fieldInfo: field];
  [self openField: [fieldInfo number]
	isPositionWithTermVectorStored: [fieldInfo isPositionWithTermVectorStored]
	isOffsetWithTermVectorStored: [fieldInfo isOffsetWithTermVectorStored]];
}
  
- (void) openField: (int) fieldNumber
         isPositionWithTermVectorStored: (BOOL) storePositionWithTermVector
         isOffsetWithTermVectorStored: (BOOL) storeOffsetWithTermVector
{
  if (![self isDocumentOpen]) 
  {
    NSLog(@"Cannot open field when no document is open.");
  }
  [self closeField];
  currentField = [[LCTVField alloc] initWithNumber: fieldNumber
	                 storePosition: storePositionWithTermVector
			 storeOffset: storeOffsetWithTermVector];
}

  /** Finished processing current field. This should be followed by a call to
   *  openField before future calls to addTerm.
   */
- (void) closeField
{
  if ([self isFieldOpen]) {
      /* DEBUG */
      //System.out.println("closeField()");
      /* DEBUG */

      // save field and terms
      [self writeField];
      [fields addObject: currentField];
      [terms removeAllObjects];
      currentField = nil;
    }
  }

  /** Return true if a field is currently open. */
- (BOOL) isFieldOpen
{
    return currentField != nil;
  }

  /** Add term to the field's term vector. Field must already be open.
   *  Terms should be added in
   *  increasing order of terms, one call per unique termNum. ProxPointer
   *  is a pointer into the TermPosition file (prx). Freq is the number of
   *  times this term appears in this field, in this document.
   * @throws IllegalStateException if document or field is not open
   */
- (void) addTerm: (NSString *) termText freq: (int) freq
{
  [self addTerm: termText freq: freq
	positions: nil offsets: nil];
}
  
- (void) addTerm: (NSString *) termText freq: (int) freq
         positions: (NSArray *) positions offsets: (NSArray *) offsets
{
    if (![self isDocumentOpen]) 
    {
      NSLog(@"Cannot add terms when document is not open");
      return;
    }
    if (![self isFieldOpen]) 
    {
      NSLog(@"Cannot add terms when field is not open");
      return;
    }
    
    [self addTermInternal: termText freq: freq
	     positions: positions offsets: offsets];
  }

- (void) addTermInternal: (NSString *) text freq: (int) freq
         positions: (NSArray *) positions offsets: (NSArray *) offsets
{
    LCTVTerm *term = [[LCTVTerm alloc] init];
    [term setTermText: text];
    [term setFreq: freq];
    [term setPositions: positions];
    [term setOffsets: offsets];
    [terms addObject: term];
}

  /**
   * Add a complete document specified by all its term vectors. If document has no
   * term vectors, add value for tvx.
   * 
   * @param vectors
   * @throws IOException
   */
- (void) addAllDocVectors: (NSArray *) vectors
{
  [self openDocument];

  if (vectors != nil) {
    int i;
    for (i = 0; i < [vectors count]; i++) {
        BOOL storePositionWithTermVector = NO;
        BOOL storeOffsetWithTermVector = NO;

	if ([[vectors objectAtIndex: i] conformsToProtocol: @protocol(LCTermPositionVector)])
         {

          id <LCTermPositionVector> tpVector = [vectors objectAtIndex: i];

          if ([tpVector size] > 0 && [tpVector termPositions: 0] != nil)
            storePositionWithTermVector = YES;
          if ([tpVector size] > 0 && [tpVector offsets: 0] != nil)
            storeOffsetWithTermVector = YES;

          LCFieldInfo *fieldInfo = [fieldInfos fieldInfo: [tpVector field]];
          [self openField: [fieldInfo number] 
		isPositionWithTermVectorStored: storePositionWithTermVector
		isOffsetWithTermVectorStored: storeOffsetWithTermVector];

	  int j;
          for (j = 0; j < [tpVector size]; j++)
	    [self addTermInternal: [[tpVector terms] objectAtIndex: j]
		  freq: [[[tpVector termFrequencies] objectAtIndex: j] intValue]
		  positions: [tpVector termPositions: j]
		  offsets: [tpVector offsets: j]];

          [self closeField];

        }
	else
        {

          id <LCTermFreqVector> tfVector = [vectors objectAtIndex: i];

          LCFieldInfo *fieldInfo = [fieldInfos fieldInfo: [tfVector field]];
	  [self openField: [fieldInfo number]
		isPositionWithTermVectorStored: storePositionWithTermVector
		isOffsetWithTermVectorStored: storeOffsetWithTermVector];

	  int j;
          for (j = 0; j < [tfVector size]; j++)
	  [self addTermInternal: [[tfVector terms] objectAtIndex: j]
		freq: [[[tfVector termFrequencies] objectAtIndex: j] intValue]
		positions: nil offsets: nil];

          [self closeField];

        }
      }
    }

    [self closeDocument];
  }
  
  /** Close all streams. */
- (void) close
{
  [self closeDocument];
  // make an effort to close all streams we can but remember and re-throw
  // the first exception encountered in this process
  if (tvx != nil) [tvx close];
  if (tvd != nil) [tvd close];
  if (tvf != nil) [tvf close];
}

- (void) writeField
{
    // remember where this field is written
    [currentField setTVFPointer: [tvf filePointer]];
    //System.out.println("Field Pointer: " + currentField.tvfPointer);
    
    long size = (long)[terms count];
    [tvf writeVInt: size];
    
    BOOL storePositions = [currentField storePositions];
    BOOL storeOffsets = [currentField storeOffsets];
    char bits = 0x0;
    if (storePositions) 
      bits |= STORE_POSITIONS_WITH_TERMVECTOR;
    if (storeOffsets) 
      bits |= STORE_OFFSET_WITH_TERMVECTOR;
    [tvf writeByte: bits];
    
    NSString *lastTermText = @"";
    int i;
    for (i = 0; i < size; i++) {
      LCTVTerm *term = (LCTVTerm *)[terms objectAtIndex: i];
      long start = (long)[lastTermText positionOfDifference: [term termText]];
      long length = (long)([[term termText] length] - start);
      [tvf writeVInt: start];       // write shared prefix length
      [tvf writeVInt: length];        // write delta length
      [tvf writeChars: [term termText] start: start length: length];  // write delta chars
      [tvf writeVInt: [term freq]];
      lastTermText = [term termText];
      
      if(storePositions){
        if([term positions] == nil)
	{
          NSLog(@"Trying to write positions that are null!");
	}
        
        // use delta encoding for positions
        int j;
        long position = 0;
        for (j = 0; j < [term freq]; j++){
          [tvf writeVInt: (long)([[[term positions] objectAtIndex: j] longValue]- position)];
          position = [[[term positions] objectAtIndex: j] longValue];
        }
      }
      
      if(storeOffsets){
        if([term offsets] == nil)
	{
          NSLog(@"Trying to write offsets that are null!");
	}
        
        // use delta encoding for offsets
        int j;
        long position = 0;
        for (j = 0; j < [term freq]; j++) {
          [tvf writeVInt: (long)([[[term offsets] objectAtIndex: j] startOffset] - position)];
          [tvf writeVInt: (long)([[[term offsets] objectAtIndex: j] endOffset] - [[[term offsets] objectAtIndex: j] startOffset])]; //Save the diff between the two.
          position = [[[term offsets] objectAtIndex: j] endOffset];
        }
      }
    }
  }

- (void) writeDoc
{
    if ([self isFieldOpen]) 
    {
      NSLog(@"Field is still open while writing document");
    }
    //System.out.println("Writing doc pointer: " + currentDocPointer);
    // write document index record
    [tvx writeLong: currentDocPointer];

    // write document data record
    long size = (long)[fields count];

    // write the number of fields
    [tvd writeVInt: size];

    // write field numbers
    int i;
    for (i = 0; i < size; i++) {
      LCTVField *field = (LCTVField *) [fields objectAtIndex: i];
      [tvd writeVInt: (long)[field number]];
    }

    // write field pointers
    long lastFieldPointer = 0;
    for (i = 0; i < size; i++) {
      LCTVField *field = (LCTVField *) [fields objectAtIndex: i];
      [tvd writeVLong: [field tvfPointer] - lastFieldPointer];
      lastFieldPointer = [field tvfPointer];
    }
    //System.out.println("After writing doc pointer: " + tvx.getFilePointer());
  }
@end

@implementation LCTVField
- (id) init
{
  self = [super init];
  tvfPointer = 0;
  storePositions = NO;
  storeOffsets = NO;
  return self;
}

- (id) initWithNumber: (long) n storePosition: (BOOL) storePos
            storeOffset: (BOOL) storeOff
{
  self = [self init];
  number = n;
  storePositions = storePos;
  storeOffsets = storeOff;
  return self;
}

- (void) setTVFPointer: (long long) p
{
  tvfPointer = p;
}
  
- (long long) tvfPointer
{
  return tvfPointer;
}

- (BOOL) storePositions
{
  return storePositions;
}

- (BOOL) storeOffsets
{
  return storeOffsets;
}

- (long) number
{
  return number;
}

- (NSString *) description
{
    return [NSString stringWithFormat: @"LCTVField: %ld", number];
}

@end

@implementation LCTVTerm
- (id) init
{
  self = [super init];
  freq = 0;
  positions = nil;
  offsets = nil;
  return self;
}

- (void) setTermText: (NSString *) text
{
  ASSIGN(termText, text);
}

- (void) setFreq: (long) f
{
  freq = f;
}

- (void) setPositions: (NSArray *) p
{
  ASSIGN(positions, p);
}

- (void) setOffsets: (NSArray *) o
{
  ASSIGN(offsets, o);
}

- (NSString *) termText
{
  return termText;
}

- (long) freq
{
  return freq;
}

- (NSArray *) positions
{
  return positions;
}

- (NSArray *) offsets
{
  return offsets;
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"LCTVTerm %@: %ld", termText, freq];
}

@end
