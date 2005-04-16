#include "TestDocHelper.h"
#include "Document/LCDocument.h"
#include "Document/LCField.h"
#include "Store/LCRAMDirectory.h"
#include "Index/LCSegmentReader.h"
#include "Index/LCSegmentInfo.h"
#include "Index/LCSegmentTermDocs.h"
#include "Index/LCTerm.h"
#include "Index/LCIndexWriter.h"
#include "Index/LCIndexReader.h"
#include "Index/LCTermDocs.h"
#include "Analysis/LCWhitespaceAnalyzer.h"
#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include "Store/LCDirectory.h"
#include "GNUstep/GNUstep.h"

@interface TestSegmentTermDocs: NSObject <UKTest>
{
  LCDocument *testDoc;
  id <LCDirectory> dir;
}
@end

@implementation TestSegmentTermDocs

- (id) init
{
  self = [super init];
  testDoc = [[LCDocument alloc] init];
  dir = [[LCRAMDirectory alloc] init];
  [TestDocHelper setupDoc: testDoc];
  [TestDocHelper writeDirectory: dir doc: testDoc];
  return self;
}

- (void) testTermDocs
{
  UKNotNil(dir);

  //After adding the document, we should be able to read it back in
  LCSegmentInfo *si = [[LCSegmentInfo alloc] initWithName: @"test" numberOfDocuments: 1 directory: dir];
  LCSegmentReader *reader = [LCSegmentReader segmentReaderWithInfo: si];
  UKNotNil(reader);
  LCSegmentTermDocs *segTermDocs = [[LCSegmentTermDocs alloc] initWithSegmentReader: reader];
  UKNotNil(segTermDocs);
  LCTerm *t = [[LCTerm alloc] initWithField: [TestDocHelper TEXT_FIELD_2_KEY]
	                       text: @"field"];
  [segTermDocs seekTerm: t];
  if ([segTermDocs next] == YES)
      {
        long docId = [segTermDocs doc];
	UKIntsEqual(docId, 0);
        long freq = [segTermDocs freq];
	UKIntsEqual(freq, 3);
      }
  [reader close];
}  
  
- (void) testBadSeek
{
  LCSegmentInfo *si = [[LCSegmentInfo alloc] initWithName: @"test" numberOfDocuments: 3 directory: dir];
  LCSegmentReader *reader = [LCSegmentReader segmentReaderWithInfo: si];
  UKNotNil(reader);
  LCSegmentTermDocs *segTermDocs = [[LCSegmentTermDocs alloc] initWithSegmentReader: reader];
  UKNotNil(segTermDocs);
  LCTerm *t = [[LCTerm alloc] initWithField: @"testField2" text: @"bad"];
  UKFalse([segTermDocs next]);
  [reader close];

  si = [[LCSegmentInfo alloc] initWithName: @"test" numberOfDocuments: 3 directory: dir];
  reader = [LCSegmentReader segmentReaderWithInfo: si];
  UKNotNil(reader);
  segTermDocs = [[LCSegmentTermDocs alloc] initWithSegmentReader: reader];
  UKNotNil(segTermDocs);
  t = [[LCTerm alloc] initWithField: @"junk" text: @"bad"];
  UKFalse([segTermDocs next]);
  [reader close];
}

- (void) addDoc: (LCIndexWriter *) writer value: (NSString *) value
{
  LCDocument *doc = [[LCDocument alloc] init];
  LCField *field = [[LCField alloc] initWithName: @"content"
	           string: value
		   store: LCStore_NO
		   index: LCIndex_Tokenized];
  [doc addField: field];
  RELEASE(field);
  [writer addDocument: doc];
  RELEASE(doc);
}

- (void) testSkipTo
{
  id <LCDirectory> d = [[LCRAMDirectory alloc] init];
  LCIndexWriter *writer = [[LCIndexWriter alloc] initWithDirectory: d
	  analyzer: [[LCWhitespaceAnalyzer alloc] init]
	  create: YES];
      
  LCTerm *ta = [[LCTerm alloc] initWithField: @"content" text: @"aaa"];
  int i;
  for(i = 0; i < 10; i++)
    [self addDoc: writer value: @"aaa aaa aaa aaa"];
        
  LCTerm *tb = [[LCTerm alloc] initWithField: @"content" text: @"bbb"];
  for(i = 0; i < 16; i++)
    [self addDoc: writer value: @"bbb bbb bbb bbb"];
        
  LCTerm *tc = [[LCTerm alloc] initWithField: @"content" text: @"ccc"];
  for(i = 0; i < 50; i++)
    [self addDoc: writer value: @"ccc ccc ccc ccc"];
        
      // assure that we deal with a single segment  
  [writer optimize];
  [writer close];
      
  //NSLog(@"===== TestSkipTo ======");
  LCIndexReader *reader = [LCIndexReader openDirectory: d];
  id <LCTermDocs> tdocs = [reader termDocs];
      
  // without optimization (assumption skipInterval == 16)
      
  // with next
  [tdocs seekTerm: ta];
  UKTrue([tdocs next]);
  UKIntsEqual(0, [tdocs doc]);
  UKIntsEqual(4, [tdocs freq]);
  UKTrue([tdocs next]);
  UKIntsEqual(1, [tdocs doc]);
  UKIntsEqual(4, [tdocs freq]);
  UKTrue([tdocs skipTo: 0]);
  UKIntsEqual(2, [tdocs doc]);
  UKTrue([tdocs skipTo: 4]);
  UKIntsEqual(4, [tdocs doc]);
  UKTrue([tdocs skipTo: 9]);
  UKIntsEqual(9, [tdocs doc]);
  UKFalse([tdocs skipTo: 10]);
      
  // without next
  [tdocs seekTerm: ta];
  UKTrue([tdocs skipTo: 0]);
  UKIntsEqual(0, [tdocs doc]);
  UKTrue([tdocs skipTo: 4]);
  UKIntsEqual(4, [tdocs doc]);
  UKTrue([tdocs skipTo: 9]);
  UKIntsEqual(9, [tdocs doc]);
  UKFalse([tdocs skipTo: 10]);
      
      // exactly skipInterval documents and therefore with optimization
      
      // with next
  [tdocs seekTerm: tb];
  UKTrue([tdocs next]);
  UKIntsEqual(10, [tdocs doc]);
  UKIntsEqual(4, [tdocs freq]);
  UKTrue([tdocs next]);
  UKIntsEqual(11, [tdocs doc]);
  UKIntsEqual(4, [tdocs freq]);
  UKTrue([tdocs skipTo: 5]);
  UKIntsEqual(12, [tdocs doc]);
  UKTrue([tdocs skipTo: 15]);
  UKIntsEqual(15, [tdocs doc]);
  UKTrue([tdocs skipTo: 24]);
  UKIntsEqual(24, [tdocs doc]);
  UKTrue([tdocs skipTo: 25]);
  UKIntsEqual(25, [tdocs doc]);
  UKFalse([tdocs skipTo: 26]);
      
  // without next
  [tdocs seekTerm: tb];
  UKTrue([tdocs skipTo: 5]);
  UKIntsEqual(10, [tdocs doc]);
  UKTrue([tdocs skipTo: 15]);
  UKIntsEqual(15, [tdocs doc]);
  UKTrue([tdocs skipTo: 24]);
  UKIntsEqual(24, [tdocs doc]);
  UKTrue([tdocs skipTo: 25]);
  UKIntsEqual(25, [tdocs doc]);
  UKFalse([tdocs skipTo: 26]);
      
      // much more than skipInterval documents and therefore with optimization
      
      // with next
  [tdocs seekTerm: tc];
  UKTrue([tdocs next]);
  UKIntsEqual(26, [tdocs doc]);
  UKIntsEqual(4, [tdocs freq]);
  UKTrue([tdocs next]);
  UKIntsEqual(27, [tdocs doc]);
  UKIntsEqual(4, [tdocs freq]);
  UKTrue([tdocs skipTo: 5]);
  UKIntsEqual(28, [tdocs doc]);
  UKTrue([tdocs skipTo: 40]);
  UKIntsEqual(40, [tdocs doc]);
  UKTrue([tdocs skipTo: 57]);
  UKIntsEqual(57, [tdocs doc]);
  UKTrue([tdocs skipTo: 74]);
  UKIntsEqual(74, [tdocs doc]);
  UKTrue([tdocs skipTo: 75]);
  UKIntsEqual(75, [tdocs doc]);
  UKFalse([tdocs skipTo: 76]);
      
      //without next
  [tdocs seekTerm: tc];
  UKTrue([tdocs skipTo: 5]);
  UKIntsEqual(26, [tdocs doc]);
  UKTrue([tdocs skipTo: 40]);
  UKIntsEqual(40, [tdocs doc]);
  UKTrue([tdocs skipTo: 57]);
  UKIntsEqual(57, [tdocs doc]);
  UKTrue([tdocs skipTo: 74]);
  UKIntsEqual(74, [tdocs doc]);
  UKTrue([tdocs skipTo: 75]);
  UKIntsEqual(75, [tdocs doc]);
  UKFalse([tdocs skipTo: 76]);
      
  [tdocs close];
  [reader close];
  [dir close];
//  NSLog(@"===== TestSkipTo ====== done");
  }
@end
