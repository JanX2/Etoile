#include "Index/LCSegmentMerger.h"
#include "Index/LCSegmentMergeInfo.h"
#include "Index/LCSegmentMergeQueue.h"
#include "Index/LCFieldInfos.h"
#include "Index/LCFieldInfo.h"
#include "Index/LCFieldsWriter.h"
#include "Index/LCTermInfosWriter.h"
#include "Index/LCTermInfo.h"
#include "Index/LCTerm.h"
#include "Index/LCTermVectorsWriter.h"
#include "Index/LCIndexReader.h"
#include "Index/LCIndexWriter.h"
#include "Index/LCCompoundFileWriter.h"
#include "Document/LCField.h"
#include "Store/LCIndexOutput.h"
#include "Store/LCRAMOutputStream.h"
#include "GNUstep/GNUstep.h"

/**
 * The SegmentMerger class combines two or more Segments, represented by an IndexReader ({@link #add},
 * into a single Segment.  After adding the appropriate readers, call the merge method to combine the 
 * segments.
 *<P> 
 * If the compoundFile flag is set, then the segments will be merged into a compound file.
 *   
 * 
 * @see #merge
 * @see #add
 */
@implementation LCSegmentMerger

- (id) init
{
  self = [super init];
  termIndexInterval = DEFAULT_TERM_INDEX_INTERVAL;
  readers = [[NSMutableArray alloc] init];

  // File extensions of old-style index files
  COMPOUND_EXTENSIONS = [[NSArray alloc] initWithObjects: 
    @"fnm", @"frq", @"prx", @"fdx", @"fdt", @"tii", @"tis", nil];
  VECTOR_EXTENSIONS = [[NSArray alloc] initWithObjects:
    @"tvx", @"tvd", @"tvf", nil];

  skipBuffer = [[LCRAMOutputStream alloc] init];
  termInfo = [[LCTermInfo alloc] init];
  return self;
}

  /** This ctor used only by test code.
   * 
   * @param dir The Directory to merge the other segments into
   * @param name The name of the new segment
   */
- (id) initWithDirectory: (id <LCDirectory>) dir name: (NSString *) name
{
  self = [self init];
  ASSIGN(directory, dir);
  ASSIGN(segment, name);
  return self;
  }

- (id) initWithIndexWriter: (LCIndexWriter *) writer name: (NSString *) name
{
  self = [self initWithDirectory: [writer directory] name: name];
  termIndexInterval = [writer termIndexInterval];
  return self;
  }

  /**
   * Add an IndexReader to the collection of readers that are to be merged
   * @param reader
   */
- (void) addIndexReader: (LCIndexReader *) reader
{
  [readers addObject: reader];
  }

  /**
   * 
   * @param i The index of the reader to return
   * @return The ith reader to be merged
   */
- (LCIndexReader *) segmentReader: (int) i
{
    return (LCIndexReader *) [readers objectAtIndex: i];
  }

  /**
   * Merges the readers specified by the {@link #add} method into the directory passed to the constructor
   * @return The number of documents that were merged
   * @throws IOException
   */
- (int) merge
{
  int value;
    
  value = [self mergeFields];
  [self mergeTerms];
  [self mergeNorms];

  if ([fieldInfos hasVectors])
  {
    [self mergeVectors];
    }

    return value;
  }
  
  /**
   * close all IndexReaders that have been added.
   * Should not be called before merge().
   * @throws IOException
   */
- (void) closeReaders
{
  int i;
    for (i = 0; i < [readers count]; i++) {  // close readers
      LCIndexReader *reader = (LCIndexReader *) [readers objectAtIndex: i];
      [reader close];
    }
  }

- (NSArray *) createCompoundFile: (NSString *) fileName
{
  LCCompoundFileWriter *cfsWriter = [[LCCompoundFileWriter alloc] initWithDirectory: directory name: fileName];

  NSMutableArray *files = [[NSMutableArray alloc] init];
    
    // Basic files
    NSString *file;
    int i;
    for (i = 0; i < [COMPOUND_EXTENSIONS count]; i++) {
      file = [segment stringByAppendingPathExtension: [COMPOUND_EXTENSIONS objectAtIndex: i]];
      [files addObject: file];
    }

    // Field norm files
    for (i = 0; i < [fieldInfos size]; i++) {
      LCFieldInfo *fi = [fieldInfos fieldInfoWithNumber: i];
      if ([fi isIndexed]) {
	file = [segment stringByAppendingPathExtension: [NSString stringWithFormat: @"f%d", i]];
	[files addObject: file];
      }
    }

    // Vector files
    if ([fieldInfos hasVectors]) {
      for (i = 0; i < [VECTOR_EXTENSIONS count]; i++) {
      file = [segment stringByAppendingPathExtension: [VECTOR_EXTENSIONS objectAtIndex: i]];
      [files addObject: file];
      }
    }

    // Now merge all added files
    NSEnumerator *e = [files objectEnumerator];
    while ((file = [e nextObject])) {
      [cfsWriter addFile: file];
    }
    
    // Perform the merge
    [cfsWriter close];
   
    return files;
  }

  /**
   * 
   * @return The number of documents in all of the readers
   * @throws IOException
   */
- (int) mergeFields
{
  fieldInfos = [[LCFieldInfos alloc] init];	  // merge field names
  int docCount = 0;
  int i;
  for (i = 0; i < [readers count]; i++) {
    LCIndexReader *reader = (LCIndexReader *) [readers objectAtIndex: i];
      [fieldInfos addIndexedCollection: [reader fieldNames: LCFieldOption_TERMVECTOR_WITH_POSITION_OFFSET]
	      storeTermVector: YES
	      storePositionWithTermVector: YES 
	      storeOffsetWithTermVector: YES];
      [fieldInfos addIndexedCollection: [reader fieldNames: LCFieldOption_TERMVECTOR_WITH_POSITION]
	      storeTermVector: YES
	      storePositionWithTermVector: YES 
	      storeOffsetWithTermVector: NO];
      [fieldInfos addIndexedCollection: [reader fieldNames: LCFieldOption_TERMVECTOR_WITH_OFFSET]
	      storeTermVector: YES
	      storePositionWithTermVector: NO 
	      storeOffsetWithTermVector: YES];
      [fieldInfos addIndexedCollection: [reader fieldNames: LCFieldOption_TERMVECTOR]
	      storeTermVector: YES
	      storePositionWithTermVector: NO 
	      storeOffsetWithTermVector: NO];
      [fieldInfos addIndexedCollection: [reader fieldNames: LCFieldOption_INDEXED]
	      storeTermVector: NO 
	      storePositionWithTermVector: NO 
	      storeOffsetWithTermVector: NO];
      [fieldInfos addCollection: [reader fieldNames: LCFieldOption_UNINDEXED]
	      isIndexed: NO];
    }
    NSString *file = [segment stringByAppendingPathExtension: @"fnm"];
    [fieldInfos write: directory name: file];

    LCFieldsWriter *fieldsWriter = // merge field values
      [[LCFieldsWriter alloc] initWithDirectory: directory
                              segment: segment
			      fieldInfos: fieldInfos];

    for (i = 0; i < [readers count]; i++) {
      LCIndexReader *reader = (LCIndexReader *) [readers objectAtIndex: i];
      int maxDoc = [reader maxDoc];
      int j;
      for (j = 0; j < maxDoc; j++)
          if (![reader isDeleted: j]) {               // skip deleted docs
            [fieldsWriter addDocument: [reader document: j]];
            docCount++;
          }
      }
      [fieldsWriter close];
    return docCount;
  }

  /**
   * Merge the TermVectors from each of the segments into the new one.
   * @throws IOException
   */
- (void) mergeVectors
{
  LCTermVectorsWriter *termVectorsWriter = 
    [[LCTermVectorsWriter alloc] initWithDirectory: directory segment: segment fieldInfos: fieldInfos];

  int r;
  for (r = 0; r < [readers count]; r++) {
    LCIndexReader *reader = (LCIndexReader *) [readers objectAtIndex: r];
    int maxDoc = [reader maxDoc];
    int docNum;
    for (docNum = 0; docNum < maxDoc; docNum++) {
      // skip deleted docs
      if ([reader isDeleted: docNum]) 
        continue;
      [termVectorsWriter addAllDocVectors: [reader termFreqVectors: docNum]];
    }
  }
  [termVectorsWriter close];
}

- (void) mergeTerms;
{
  NSString *file = [segment stringByAppendingPathExtension: @"frq"];
  freqOutput = [directory createOutput: file];
  file = [segment stringByAppendingPathExtension: @"prx"];
  proxOutput = [directory createOutput: file];
  termInfosWriter = [[LCTermInfosWriter alloc] initWithDirectory: directory
	  segment: segment
	  fieldInfos: fieldInfos
	  interval: termIndexInterval];
  skipInterval = [termInfosWriter skipInterval];
  queue = [[LCSegmentMergeQueue alloc] initWithSize: [readers count]];

  [self mergeTermInfos];
   
  if (freqOutput != nil) [freqOutput close];
  if (proxOutput != nil) [proxOutput close];
  if (termInfosWriter != nil) [termInfosWriter close];
  if (queue != nil) [queue close];
}

- (void) mergeTermInfos
{
  int base = 0;
  int i;
  for (i = 0; i < [readers count]; i++) {
      LCIndexReader *reader = (LCIndexReader *) [readers objectAtIndex: i];
      LCTermEnum *termEnum = [reader terms];
      LCSegmentMergeInfo *smi = [[LCSegmentMergeInfo alloc] initWithBase: base
		      termEnum: termEnum reader: reader];
      base += [reader numDocs];
      if ([smi next])
      {
        [queue put: smi];				  // initialize queue
      }
      else
        [smi close];
    }

    NSMutableArray *match = [[NSMutableArray alloc] init];

    while ([queue size] > 0) {
      int matchSize = 0;			  // pop matching terms
      if (matchSize < [match count])
              [match replaceObjectAtIndex: matchSize withObject: [queue pop]];
      else
              [match addObject: [queue pop]];

      matchSize++;
      LCTerm *term = [[match objectAtIndex: 0] term];
      LCSegmentMergeInfo *top = (LCSegmentMergeInfo *) [queue top];

      while (top != nil && [term compare: [top term]] == NSOrderedSame) {
        if (matchSize < [match count])
          [match replaceObjectAtIndex: matchSize withObject: [queue pop]];
        else
	      [match addObject: [queue pop]];
	    matchSize++;
        top = (LCSegmentMergeInfo *) [queue top];
      }

      [self mergeTermInfo: match size: matchSize]; // add new TermInfo

      while (matchSize > 0) {
        LCSegmentMergeInfo *smi = [match objectAtIndex: --matchSize];
        if ([smi next])
          [queue put: smi];			  // restore queue
        else
          [smi close];				  // done with a segment
      }
    }
  }

  /** Merge one term found in one or more segments. The array <code>smis</code>
   *  contains segments that are positioned at the same term. <code>N</code>
   *  is the number of cells in the array actually occupied.
   *
   * @param smis array of segments
   * @param n number of cells in the array actually occupied
   */
- (void) mergeTermInfo: (NSArray *) smis size: (int) n
{
  long freqPointer = [freqOutput filePointer];
  long proxPointer = [proxOutput filePointer];

//  NSLog(@"appendPosting %@, size %d", smis, n);
  int df = [self appendPosting: smis size: n];		  // append posting data

  long skipPointer = [self writeSkip];

  if (df > 0) {
      //NSLog(@"Add term %@", [[smis objectAtIndex: 0] term]);
      // add an entry to the dictionary with pointers to prox and freq files
      [termInfo setDocFreq: df];
      [termInfo setFreqPointer: freqPointer];
      [termInfo setProxPointer: proxPointer];
      [termInfo setSkipOffset: (long)(skipPointer - freqPointer)];
      [termInfosWriter addTerm: [[smis objectAtIndex: 0] term]
	      termInfo: termInfo];
    }
  }

  /** Process postings from multiple segments all positioned on the
   *  same term. Writes out merged entries into freqOutput and
   *  the proxOutput streams.
   *
   * @param smis array of segments
   * @param n number of cells in the array actually occupied
   * @return number of documents across all segments where this term was found
   */
- (int) appendPosting: (NSArray *) smis size: (int) n
{
    int lastDoc = 0;
    int df = 0;					  // number of docs w/ term
    [self resetSkip];
    int i;
    for (i = 0; i < n; i++) {
      LCSegmentMergeInfo *smi = [smis objectAtIndex: i];
      id <LCTermPositions> postings = [smi postings];
      int base = [smi base];
      NSArray *docMap = [smi docMap];
      [postings seekTermEnum: [smi termEnum]];
      while ([postings next]) {
        int doc = [postings doc];
        if (docMap != nil)
          doc = [[docMap objectAtIndex: doc] intValue]; // map around deletions
        doc += base;                              // convert to merged space

        if (doc < lastDoc)
	{
          NSLog(@"docs out of order");
	}

        df++;

        if ((df % skipInterval) == 0) {
          [self bufferSkip: lastDoc];
        }

        int docCode = (doc - lastDoc) << 1;	  // use low bit to flag freq=1
        lastDoc = doc;

        int freq = [postings freq];
        if (freq == 1) {
          [freqOutput writeVInt: (docCode | 1)];  // write doc & freq=1
        } else {
          [freqOutput writeVInt: docCode];	  // write doc
          [freqOutput writeVInt: freq];		  // write frequency in doc
        }

        int lastPosition = 0;			  // write position deltas
	int j;
        for (j = 0; j < freq; j++) {
          int position = [postings nextPosition];
          [proxOutput writeVInt: position - lastPosition];
          lastPosition = position;
        }
      }
    }
    return df;
  }

- (void) resetSkip
{
    [skipBuffer reset];
    lastSkipDoc = 0;
    lastSkipFreqPointer = [freqOutput filePointer];
    lastSkipProxPointer = [proxOutput filePointer];
  }

- (void) bufferSkip: (int) doc
{
    long freqPointer = [freqOutput filePointer];
    long proxPointer = [proxOutput filePointer];

    [skipBuffer writeVInt: (doc - lastSkipDoc)];
    [skipBuffer writeVInt: ((int) (freqPointer - lastSkipFreqPointer))];
    [skipBuffer writeVInt: ((int) (proxPointer - lastSkipProxPointer))];

    lastSkipDoc = doc;
    lastSkipFreqPointer = freqPointer;
    lastSkipProxPointer = proxPointer;
  }

- (long) writeSkip
{
    long skipPointer = [freqOutput filePointer];
    [skipBuffer writeTo: freqOutput];
    return skipPointer;
  }

- (void) mergeNorms
{
	int i;
    for (i = 0; i < [fieldInfos size]; i++) {
      LCFieldInfo *fi = [fieldInfos fieldInfoWithNumber: i];
      if ([fi isIndexed]) {
	NSString *file = [segment stringByAppendingPathExtension: [NSString stringWithFormat: @"f%d", i]];
        LCIndexOutput *output = [directory createOutput: file];
	int j;
          for (j = 0; j < [readers count]; j++) {
            LCIndexReader *reader = (LCIndexReader *) [readers objectAtIndex: j];
            int maxDoc = [reader maxDoc];
	    NSMutableData *input = [[NSMutableData alloc] init];
	    [reader setNorms: [fi name] bytes: input offset: 0];
	    int k;
	    char *bytes = (char *)[input bytes];
            for (k = 0; k < maxDoc; k++) {
              if (![reader isDeleted: k]) {
                [output writeByte: bytes[k]];
              }
            }
          }
          [output close];
      }
    }
  }

@end
