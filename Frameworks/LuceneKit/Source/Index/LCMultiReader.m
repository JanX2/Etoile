#include "LuceneKit/Index/LCMultiReader.h"
#include "LuceneKit/Index/LCSegmentMergeQueue.h"
#include "LuceneKit/Index/LCSegmentMergeInfo.h"
#include "LuceneKit/Index/LCTerm.h"
#include "LuceneKit/Index/LCTermEnum.h"
#include "GNUstep.h"

/** An IndexReader which reads multiple indexes, appending their content.
 *
 * @version $Id$
 */
@implementation LCMultiReader

- (id) init
{
  self = [super init];
  normsCache = [[NSMutableDictionary alloc] init];
  maxDoc = 0;
  numDocs = -1;
  hasDeletions = NO;
  return self;
}

 /**
  * <p>Construct a MultiReader aggregating the named set of (sub)readers.
  * Directory locking for delete, undeleteAll, and setNorm operations is
  * left to the subreaders. </p>
  * <p>Note that all subreaders are closed if this Multireader is closed.</p>
  * @param subReaders set of (sub)readers
  * @throws IOException
  */
- (id) initWithReaders: (NSArray *) r
                starts: (NSArray *) s
{
  self = [self init];
  [super initWithDirectory: ([subReaders count] == 0) ? nil : [[subReaders objectAtIndex: 0] directory]];
  [self initialize: subReaders];
  return self;
}

  /** Construct reading the named set of readers. */
- (id) initWithDirectory: (id <LCDirectory>) dir
       segmentInfos: (LCSegmentInfos *) sis
              close: (BOOL) close
	             readers: (NSArray *) sr
{
  self = [self init];
  [super initWithDirectory: dir
	  segmentInfos: sis
	  closeDirectory: close];
  [self initialize: sr];
  return self;
}

- (void) initialize: (NSArray *) sr
{
  ASSIGN(subReaders, sr);
  starts = [[NSMutableArray alloc] init]; // build starts array
  int i;
  for (i = 0; i < [subReaders count]; i++) {
    [starts addObject: [NSNumber numberWithInt: maxDoc]];
    maxDoc += [[subReaders objectAtIndex: i] maxDoc];      // compute maxDocs

    if ([[subReaders objectAtIndex: i] hasDeletions])
        hasDeletions = YES;
  }
  [starts addObject: [NSNumber numberWithInt: maxDoc]];
}


  /** Return an array of term frequency vectors for the specified document.
   *  The array contains a vector for each vectorized field in the document.
   *  Each vector vector contains term numbers and frequencies for all terms
   *  in a given vectorized field.
   *  If no such fields existed, the method returns null.
   */
- (NSArray *) termFreqVectors: (int) n
{
  int i = [self readerIndex: n];        // find segment num
  return [[subReaders objectAtIndex: i] termFreqVectors: (n - [[starts objectAtIndex: i] intValue])]; // dispatch to segment
  }

- (id <LCTermFreqVector>) termFreqVector: (int) n field: (NSString *) field
{
  int i = [self readerIndex: n];       // find segment num
  return [[subReaders objectAtIndex: i] termFreqVector: (n - [[starts objectAtIndex: i] intValue])
	  field: field];
  }

- (int) numberDocs
{
    if (numDocs == -1) {        // check cache
      int n = 0;                // cache miss--recompute
      int i;
      for (i = 0; i < [subReaders count]; i++)
        n += [[subReaders objectAtIndex: i] numDocs];      // sum from readers
      numDocs = n;
    }
    return numDocs;
  }

- (int) maxDoc
{
    return maxDoc;
  }

- (LCDocument *) document: (int) n
{
  int i = [self readerIndex: n];        // find segment num
  return [[subReaders objectAtIndex: i] document: (n - [[starts objectAtIndex: i] intValue])]; // dispatch to segment
}

- (BOOL) isDeleted: (int) n
{
  int i = [self readerIndex: n];        // find segment num
  return [[subReaders objectAtIndex: i] isDeleted: (n - [[starts objectAtIndex: i] intValue])]; // dispatch to segment
  }

- (BOOL) hasDeletions
{
  return hasDeletions; 
}

- (void) doDelete: (int) n
{
    numDocs = -1;                             // invalidate cache
    int i = [self readerIndex: n];        // find segment num
    [[subReaders objectAtIndex: i] delete: (n - [[starts objectAtIndex: i] intValue])]; // dispatch to segment
    hasDeletions = YES;
}

- (void) doUndeleteAll
{
  int i;
  for (i = 0; i < [subReaders count]; i++)
      [[subReaders objectAtIndex: i] undeleteAll];
    hasDeletions = NO;
  }

- (int) readerIndex: (int) n  // find reader for doc n:
{
    int lo = 0;                                      // search starts array
    int hi = [subReaders count] - 1;                  // for first element less

    while (hi >= lo) {
      int mid = (lo + hi) >> 1;
      int midValue = [[starts objectAtIndex: mid] intValue];
      if (n < midValue)
        hi = mid - 1;
      else if (n > midValue)
        lo = mid + 1;
      else {                                      // found a match
        while (mid+1 < [subReaders count] && [[starts objectAtIndex: (mid+1)] intValue] == midValue) {
          mid++;                                  // scan to last match
        }
        return mid;
      }
    }
    return hi;
  }

- (NSData *) norms: (NSString *) field
{
  NSMutableData *bytes = [normsCache objectForKey: field];
  if (bytes != nil)
      return bytes;          // cache hit

  bytes = [[NSMutableData alloc] init];
  int i;
  for (i = 0; i < [subReaders count]; i++)
    [[subReaders objectAtIndex: i] setNorms: field bytes: bytes offset: [[starts objectAtIndex: i] intValue]];
  [normsCache setObject: bytes forKey: field]; // update cache
  return AUTORELEASE(bytes);
}

- (void) setNorms: (NSString *) field 
            bytes: (NSMutableData *) result offset: (int) offset
{
  NSData *bytes = [normsCache objectForKey: field];
  if (bytes != nil)                            // cache hit
  {
    NSRange r = NSMakeRange(offset, [self maxDoc]);
    [result replaceBytesInRange: r withBytes: [bytes bytes]];
  }

  int i;
  for (i = 0; i < [subReaders count]; i++)      // read from segments
    [[subReaders objectAtIndex: i] setNorms: field bytes: result offset: offset + [[starts objectAtIndex: i] intValue]];
}

- (void) doSetNorm: (int) n field: (NSString *) field charValue: (char) value
{
  [normsCache removeObjectForKey: field]; // clear cache
  int i = [self readerIndex: n]; // find segment num
  [[subReaders objectAtIndex: i] setNorm: (n-[[starts objectAtIndex: i] intValue]) field: field charValue: value]; // dispatch
  }

- (LCTermEnum *) terms
{
  return AUTORELEASE([[LCMultiTermEnum alloc] initWithReaders: subReaders
		                              starts: starts
					      term: nil]);
}

- (LCTermEnum *) termsWithTerm: (LCTerm *) term
{
  return AUTORELEASE([[LCMultiTermEnum alloc] initWithReaders: subReaders
		                              starts: starts
					      term: term]);
}

- (long) docFreq: (LCTerm *) t
{
  int total = 0;          // sum freqs in segments
  int i;
  for (i = 0; i < [subReaders count]; i++)
    total += [[subReaders objectAtIndex: i] docFreq: t];
  return total;
}

- (id <LCTermDocs>) termDocs
{
  return AUTORELEASE([[LCMultiTermDocs alloc] initWithReaders: subReaders
		  starts: starts]);
}

- (id <LCTermPositions>) termPositions
{
  return AUTORELEASE([[LCMultiTermPositions alloc] initWithReaders: subReaders
		  starts: starts]);
}

- (void) doCommit
{
  int i;
  for (i = 0; i < [subReaders count]; i++)
    [[subReaders objectAtIndex: i] commit];
}

- (void) doClose
{
  int i;
  for (i = 0; i < [subReaders count]; i++)
    [[subReaders objectAtIndex: i] close];
}

  /**
   * @see IndexReader#getFieldNames(IndexReader.FieldOption)
   */
- (NSArray *) fieldNames: (LCFieldOption) fieldOption
{
    // maintain a unique set of field names
    NSMutableSet *fieldSet = [[NSMutableSet alloc] init];
    int i;
    for (i = 0; i < [subReaders count]; i++) {
      LCIndexReader *reader = [subReaders objectAtIndex: i];
      [fieldSet addObjectsFromArray: [reader fieldNames: fieldOption]];
    }
    return [fieldSet allObjects];
}

@end

@implementation LCMultiTermEnum

- (id) initWithReaders: (NSArray *) readers
                 starts: (NSArray *) starts
                  term: (LCTerm *) t
{
  self = [super init];
  queue = [[LCSegmentMergeQueue alloc] initWithSize: [readers count]];
  int i;
  for (i = 0; i < [readers count]; i++) {
    LCIndexReader *reader = [readers objectAtIndex: i];
    LCTermEnum *termEnum;

    if (t != nil) {
        termEnum = [reader termsWithTerm: t];
      } else
        termEnum = [reader terms];

    LCSegmentMergeInfo *smi = [[LCSegmentMergeInfo alloc] initWithBase: [[starts objectAtIndex: i] intValue] termEnum: termEnum reader: reader];
      if ((t == nil ? [smi next] : ([termEnum term] != nil)))
        [queue put: smi];          // initialize queue
      else
        [smi close];
    }

    if (t != nil && [queue size] > 0) {
      [self next];
    }
  }

- (BOOL) next
{
  LCSegmentMergeInfo *top = (LCSegmentMergeInfo *)[queue top];
  if (top == nil) {
      term = nil;
      return NO;
    }

  term = [top term];
  docFreq = 0;

  while (top != nil && [term compare: [top term]] == NSOrderedSame) {
    [queue pop];
    docFreq += [[top termEnum] docFreq];    // increment freq
      if ([top next])
        [queue put: top];          // restore queue
      else
        [top close];          // done with a segment
      top = (LCSegmentMergeInfo *)[queue top];
    }
    return YES;
  }

- (LCTerm *) term
{
    return term;
  }

- (long) docFreq
{
    return docFreq;
  }

- (void) close
{
    [queue close];
}

@end

@implementation LCMultiTermDocs

- (id) init
{
  self = [super init];
  base = 0;
  pointer = 0;
  return self;
}

- (id) initWithReaders: (NSArray *) r 
                starts: (NSArray *) s
{
  self = [self init];
  ASSIGN(readers, r);
  ASSIGN(starts, s);
  readerTermDocs = [[NSMutableArray alloc] init];
  return self;
}

- (int) doc
{
    return base + [current doc];
}

- (int) freq
{
    return [current freq];
  }

- (void) seekTerm: (LCTerm *) t
{
  ASSIGN(term, t);
  base = 0;
  pointer = 0;
  current = nil;
}

- (void) seekTermEnum: (LCTermEnum *) termEnum
{
    [self seekTerm: [termEnum term]];
}

- (BOOL) next
{
    if (current != nil && [current next]) {
      return YES;
    } else if (pointer < [readers count]) {
      base = [[starts objectAtIndex: pointer] intValue];
      current = [self termDocs: pointer++];
      return [self next];
    } else
      return NO;
  }

  /** Optimized implementation. */
- (int) readDocs: (NSMutableArray *) docs frequency: (NSMutableArray *) freqs
{
    while (YES) {
      while (current == nil) {
        if (pointer < [readers count]) {      // try next segment
          base = [[starts objectAtIndex: pointer] intValue];
          current = [self termDocs: pointer++];
        } else {
          return 0;
        }
      }
      int end = [current readDocs: docs frequency: freqs];
      if (end == 0) {          // none left in segment
        current = nil;
      } else {            // got some
        int b = base;        // adjust doc numbers
	int i;
        for (i = 0; i < end; i++)
	{
	  int tmp = [[docs objectAtIndex: i] intValue] + b;;
	  [docs replaceObjectAtIndex: i withObject: [NSNumber numberWithInt: tmp]];
	}
      }
        return end;
    }
  }

  /** As yet unoptimized implementation. */
- (BOOL) skipTo: (int) target
{
    do {
      if (![self next])
        return NO;
    } while (target > [self doc]);
      return YES;
  }

- (id <LCTermDocs>) termDocs: (int) i
{
    if (term == nil) return nil;
    id <LCTermDocs> result = [readerTermDocs objectAtIndex: i];
    if (result == nil)
    {
      result = [self termDocsWithReader: [readers objectAtIndex: i]];
      [readerTermDocs addObject: result];
    }
    [result seekTerm: term];
    return result;
  }

- (id <LCTermDocs>) termDocsWithReader: (LCIndexReader *) reader
{
    return [reader termDocs];
  }

- (void) close
{
  int i;
    for (i = 0; i < [readerTermDocs count]; i++) {
      if ([readerTermDocs objectAtIndex: i] != nil)
        [[readerTermDocs objectAtIndex: i] close];
    }
}

@end

@implementation LCMultiTermPositions

- (id) initWithReaders: (NSArray *) r
                starts: (NSArray *) s
{
  self = [super initWithReaders: r starts: s];
  return self;
  }

- (id <LCTermDocs>) termDocsWithReader: (LCIndexReader *) reader
{
    return (id <LCTermDocs>)[reader termPositions];
  }

- (int) nextPosition
{
    return [(id <LCTermPositions>)current nextPosition];
  }

@end
