#include "TestFilterIndexReader.h"
#include "Index/LCFilterIndexReader.h"
#include "Index/LCTerm.h"

/** Filter that only permits terms containing 'e'.*/
@interface TestTermEnum: LCFilterTermEnum
@end

@implementation TestTermEnum

/** Scan for terms containing the letter 'e'.*/
- (BOOL) next
{
  while ([input next])
  {
    if ([[[input term] text] rangeOfString: @"e"].location != NSNotFound)
      return YES;
  }
  return NO;
}

@end

/** Filter that only returns odd numbered documents. */
@interface TestTermPositions: LCFilterTermPositions
@end

@implementation TestTermPositions
- (BOOL) next
{
  while ([input next])
  {
    if (([input doc] % 2) == 1)
	    return YES;
  }
  return NO;
}
@end

@interface TestReader: LCFilterIndexReader
@end

@implementation TestReader
/** Filter terms with TestTermEnum. */
- (LCTermEnum *) terms
{
  return [[TestTermEnum alloc] initWithTermEnum: [input terms]];
}

/** Filter positions with TestTermPositions. */
- (id <LCTermPositions>) termPositions
{
  return [[TestTermPositions alloc] initWithTermPositions: [input termPositions]];
}
@end

#include "Store/LCRAMDirectory.h"
#include "Index/LCIndexWriter.h"
#include "Analysis/LCWhitespaceAnalyzer.h"
#include "Document/LCDocument.h"
#include "Document/LCField.h"

@implementation TestFilterIndexReader 

  /**
   * Tests the IndexReader.getFieldNames implementation
   * @throws Exception on error
   */
- (void) testFilterIndexReader
{
  LCRAMDirectory *directory = [[LCRAMDirectory alloc] init];
  LCIndexWriter *writer = [[LCIndexWriter alloc] initWithDirectory: directory
	  analyzer: [[LCWhitespaceAnalyzer alloc] init]
	  create: YES];
  LCDocument *d1 = [[LCDocument alloc] init];
  LCField *field = [[LCField alloc] initWithName: @"default"
	  string: @"one two"
	  store: LCStore_YES
	  index: LCIndex_Tokenized];
  [d1 addField: field];
  [writer addDocument: d1];

  LCDocument *d2 = [[LCDocument alloc] init];
  field = [[LCField alloc] initWithName: @"default"
	  string: @"one three"
	  store: LCStore_YES
	  index: LCIndex_Tokenized];
  [d2 addField: field];
  [writer addDocument: d2];

  LCDocument *d3 = [[LCDocument alloc] init];
  field = [[LCField alloc] initWithName: @"default"
	  string: @"one four"
	  store: LCStore_YES
	  index: LCIndex_Tokenized];
  [d3 addField: field];
  [writer addDocument: d3];
  [writer close];

  LCIndexReader *r = [LCIndexReader openDirectory: directory];
  LCIndexReader *reader = [[TestReader alloc] initWithIndexReader: r];

  LCTermEnum *terms = [reader terms];
  while ([terms next]) {
    UKTrue([[[terms term] text] rangeOfString: @"e"].location != NSNotFound);
  }
  [terms close];
    
  LCTerm *term = [[LCTerm alloc] initWithField: @"default" text: @"one"];
  id <LCTermPositions> positions = [reader termPositionsWithTerm: term];
#if 1
  [positions next];
  UKTrue(([positions doc] % 2) == 1);
  [positions next];
  [positions next];
#else // FIXME: Cannot run this with "ukrun -q"
  while ([positions next] == YES) 
    UKIntsEqual(([positions doc] % 2), 1);
#endif

  [reader close];
}

@end
