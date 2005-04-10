#include "TestMultiReader.h"
#include "TestDocHelper.h"
#include "Document/LCDocument.h"
#include "Store/LCRAMDirectory.h"
#include "Index/LCSegmentInfos.h"
#include "Index/LCSegmentInfo.h"
#include "Index/LCSegmentReader.h"
#include "Index/LCMultiReader.h"
#include "Index/LCTermFreqVector.h"

@implementation TestMultiReader

- (id) init
{
  self = [super init];
  dir = [[LCRAMDirectory alloc] init];
  doc1 = [[LCDocument alloc] init];;
  doc2 = [[LCDocument alloc] init];;
  readers = [[NSMutableArray alloc] init];
  sis = [[LCSegmentInfos alloc] init];

  [TestDocHelper setupDoc: doc1];
  [TestDocHelper setupDoc: doc2];
  [TestDocHelper writeDirectory: dir segment: @"seg-1" doc: doc1];
  [TestDocHelper writeDirectory: dir segment: @"seg-2" doc: doc2];
    
  [sis writeToDirectory: dir];
  LCSegmentInfo *si = [[LCSegmentInfo alloc] initWithName: @"seg-1"
	   numberOfDocuments: 1 directory: dir];
  reader1 = [LCSegmentReader segmentReaderWithInfo: si];
  si = [[LCSegmentInfo alloc] initWithName: @"seg-2"
	   numberOfDocuments: 1 directory: dir];
  reader2 = [LCSegmentReader segmentReaderWithInfo: si];
  [readers addObject: reader1];
  [readers addObject: reader2];
  return self;
}

- (void) test
{
  UKNotNil(dir);
  UKNotNil(reader1);
  UKNotNil(reader2);
  UKNotNil(sis);
}    

- (void) testDocument
{
  [sis readFromDirectory: dir];
  LCMultiReader *reader = [[LCMultiReader alloc] initWithDirectory: dir
	  segmentInfos: sis
	  close: NO
	  readers: readers];
  UKNotNil(reader);
  LCDocument *newDoc1 = [reader document: 0];
  UKNotNil(newDoc1);
  UKIntsEqual([TestDocHelper numFields: newDoc1], [TestDocHelper numFields: doc1]-2);
  LCDocument *newDoc2 = [reader document: 1];
  UKNotNil(newDoc2);
  UKIntsEqual([TestDocHelper numFields: newDoc2], [TestDocHelper numFields: doc2]-2);
  id <LCTermFreqVector> vector = [reader termFreqVector: 0 field: [TestDocHelper TEXT_FIELD_2_KEY]];
  UKNotNil(vector);
}
  
- (void) testTermVectors 
{
  LCMultiReader *reader = [[LCMultiReader alloc] initWithDirectory: dir
	  segmentInfos: sis
	  close: NO
	  readers: readers];
  UKNotNil(reader);
}

@end
