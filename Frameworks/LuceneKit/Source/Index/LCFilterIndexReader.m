#include "Index/LCFilterIndexReader.h"
#include "Document/LCDocument.h"
#include "Document/LCField.h"
#include "GNUstep/GNUstep.h"

@implementation LCFilterTermDocs

  /** Base class for filtering {@link TermDocs} implementations. */
- (id) initWithTermDocs: (id <LCTermDocs>) docs
{
  self = [super init];
  ASSIGN(input, docs);
  return self;
}

- (void) dealloc
{
  RELEASE(input);
  [super dealloc];
}

- (void) seekTerm: (LCTerm *) term
{
  [input seekTerm: term];
}

- (void) seekTermEnum: (LCTermEnum *) termEnum
{
  [input seekTermEnum: termEnum];
}

- (long) doc
{
  return [input doc];
}

- (long) freq
{
  return [input freq];
}

- (BOOL) next
{
  return [input next];
}

- (int) readDocs: (NSMutableArray *) docs frequency: (NSMutableArray *) freqs
{
  return [input readDocs: docs frequency: freqs];
}

- (BOOL) skipTo: (int) i
{
  return [input skipTo: i];
}

- (void) close
{
  [input close];
}

@end

  /** Base class for filtering {@link TermPositions} implementations. */
@implementation LCFilterTermPositions

- (id) initWithTermPositions: (id <LCTermPositions>) po
{
  return [super initWithTermDocs: po];
}

- (int) nextPosition
{
  return [(id <LCTermPositions>)input nextPosition];
}

- (NSComparisonResult) compare: (LCFilterTermPositions *) other
{
  if ([self doc] < [other doc])
    return NSOrderedAscending;
  else if ([self doc] == [other doc])
    return NSOrderedSame;
  else
    return NSOrderedDescending;
}

@end

@implementation LCFilterTermEnum

  /** Base class for filtering {@link TermEnum} implementations. */
- (id) initWithTermEnum: (LCTermEnum *) termEnum
{
  self = [super init];
  ASSIGN(input, termEnum);
  return self;
}

- (BOOL) next
{
  return [input next];
}

- (LCTerm *) term
{
  return [input term];
}

- (long) docFreq
{
  return [input docFreq];
}

- (void) close
{
  [input close];
}

@end

@implementation LCFilterIndexReader

  /**
   * <p>Construct a FilterIndexReader based on the specified base reader.
   * Directory locking for delete, undeleteAll, and setNorm operations is
   * left to the base reader.</p>
   * <p>Note that base reader is closed if this FilterIndexReader is closed.</p>
   * @param in specified base reader.
   */
- (id) initWithIndexReader: (LCIndexReader *) reader
{
  self = [super initWithDirectory: [reader directory]];
  ASSIGN(input, reader);
  return self;
}

- (NSArray *) termFreqVectors: (int) docNumber
{
  return [input termFreqVectors: docNumber];
}

- (id <LCTermFreqVector>) termFreqVector: (int) docNumber field: (NSString *) field
{
  return [input termFreqVector: docNumber field: field];
}

- (int) numDocs
{
  return [input numDocs];
}

- (int) maxDoc
{
  return [input maxDoc];
}

- (LCDocument *) document: (int) n
{
  return [input document: n];
}

- (BOOL) isDeleted: (int) n
{
  return [input isDeleted: n];
}

- (BOOL) hasDeletions
{
  return [input hasDeletions];
}

- (void) doUndeleteAll
{
  [input undeleteAll];
}

- (NSData *) norms: (NSString *) f
{
  return [input norms: f];
}

- (void) setNorms: (NSString *) f bytes: (NSMutableData *) bytes
         offset: (int) offset
{
  [input setNorms: f bytes: bytes offset: offset];

}

- (void) doSetNorm: (int) d field: (NSString *) f
             charValue: (char) b
{
  [input setNorm: d field: f charValue: b];
}

- (LCTermEnum *) terms
{
  return [input terms];
}

- (LCTermEnum *) termsWithTerm: (LCTerm *) t
{
  return [input termsWithTerm: t];
}

- (long) docFreq: (LCTerm *) t
{
  return [input docFreq: t];
}

- (id <LCTermDocs>) termDocs
{
  return [input termDocs];
}

- (id <LCTermPositions>) termPositions
{
  return [input termPositions];
}

- (void) doDelete: (int) n
{
  [input delete: n];
}

- (void) doCommit
{
  [input commit];
}

- (void) doClose
{
  [input close];
}

- (NSArray *) fieldNames: (LCFieldOption) option
{
  return [input fieldNames: option];
}

@end
