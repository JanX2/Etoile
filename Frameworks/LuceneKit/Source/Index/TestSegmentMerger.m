#include "TestSegmentMerger.h"
#include "TestDocHelper.h"
#include "Index/LCSegmentReader.h"
#include "Index/LCSegmentInfo.h"
#include "Index/LCSegmentMerger.h"
#include "Index/LCTerm.h"
#include "Index/LCTermPositionVector.h"
#include "Document/LCDocument.h"
#include "Store/LCRAMdirectory.h"

@implementation TestSegmentMerger

- (id) init
{
  self = [super init];
  //The variables for the new merged segment
  mergedDir = [[LCRAMDirectory alloc] init];
  mergedSegment = @"test";
  //First segment to be merged
  merge1Dir = [[LCRAMDirectory alloc] init];
  doc1 = [[LCDocument alloc] init];
  merge1Segment = @"test-1";
  reader1 = nil;
  //Second Segment to be merged
  merge2Dir = [[LCRAMDirectory alloc] init];
  doc2 = [[LCDocument alloc] init];
  merge2Segment = @"test-2";
  reader2 = nil;

  [TestDocHelper setupDoc: doc1];
  [TestDocHelper writeDirectory: merge1Dir segment: merge1Segment doc: doc1];
  [TestDocHelper setupDoc: doc2];
  [TestDocHelper writeDirectory: merge2Dir segment: merge2Segment doc: doc2];
  LCSegmentInfo *si = [[LCSegmentInfo alloc] initWithName: merge1Segment
	   numberOfDocuments: 1
	   directory: merge1Dir];
  reader1 = [LCSegmentReader segmentReaderWithInfo: si];
  si = [[LCSegmentInfo alloc] initWithName: merge2Segment
	   numberOfDocuments: 1
	   directory: merge2Dir];
  reader2 = [LCSegmentReader segmentReaderWithInfo: si];

  return self;
}
  
- (void) test
{
  UKNotNil(mergedDir);
  UKNotNil(merge1Dir);
  UKNotNil(merge2Dir);
  UKNotNil(reader1);
  UKNotNil(reader2);
}
  
- (void) testMerge
{
  //NSLog(@"----------------TestMerge------------------");
  LCSegmentMerger *merger = [[LCSegmentMerger alloc] initWithDirectory: mergedDir name: mergedSegment];
  [merger addIndexReader: reader1];
  [merger addIndexReader: reader2];
  int docsMerged = [merger merge];
  [merger closeReaders];
  UKIntsEqual(docsMerged, 2);      
  //Should be able to open a new SegmentReader against the new directory
  LCSegmentInfo *si = [[LCSegmentInfo alloc] initWithName: mergedSegment numberOfDocuments: docsMerged directory: mergedDir];
  LCSegmentReader *mergedReader = [LCSegmentReader segmentReaderWithInfo: si];
  UKNotNil(mergedReader);
  UKIntsEqual([mergedReader numDocs], 2);
  LCDocument *newDoc1 = [mergedReader document: 0];
  UKNotNil(newDoc1);
  //There are 2 unstored fields on the document
  UKIntsEqual([TestDocHelper numFields: newDoc1], [TestDocHelper numFields: doc1]-2);
  LCDocument *newDoc2 = [mergedReader document: 1];
  UKNotNil(newDoc2);
  UKIntsEqual([TestDocHelper numFields: newDoc2], [TestDocHelper numFields: doc2]-2);
  
  LCTerm *t = [[LCTerm alloc] initWithField: [TestDocHelper TEXT_FIELD_2_KEY] text: @"field"];
  id <LCTermDocs> termDocs = [mergedReader termDocsWithTerm: t];
  UKNotNil(termDocs);
  UKTrue([termDocs next]);

  NSArray *stored = [mergedReader fieldNames: LCFieldOption_INDEXED_WITH_TERMVECTOR];
  UKNotNil(stored);
  //NSLog(@"stored size:; %d", [stored count]);
  UKIntsEqual([stored count], 2);
  
  id <LCTermFreqVector> vector = [mergedReader termFreqVector: 0 field: [TestDocHelper TEXT_FIELD_2_KEY]];
  UKNotNil(vector);
  NSArray *terms = [vector terms];
  UKNotNil(terms);
  UKIntsEqual([terms count], 3);
  NSArray *freqs = [vector termFrequencies];
  UKNotNil(freqs);
  UKTrue([vector conformsToProtocol: @protocol(LCTermPositionVector)]);

  int i;
  for (i = 0; i < [terms count]; i++)
  {
    NSString *term = [terms objectAtIndex: i];
    int freq = [[freqs objectAtIndex: i] intValue];
    UKTrue([[TestDocHelper FIELD_2_TEXT] rangeOfString: term].location != NSNotFound);
    UKIntsEqual([[[TestDocHelper FIELD_2_FREQS] objectAtIndex: i] intValue], freq);
  }

  //NSLog(@"---------------------end TestMerge-------------------");
}

@end
