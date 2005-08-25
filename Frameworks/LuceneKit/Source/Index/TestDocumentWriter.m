#include <LuceneKit/Index/LCDocumentWriter.h>
#include <LuceneKit/GNUstep/GNUstep.h>
#include <UnitKit/UnitKit.h>
#include <LuceneKit/Store/LCRAMDirectory.h>
#include <LuceneKit/Analysis/LCWhitespaceAnalyzer.h>
#include <LuceneKit/Index/LCSegmentReader.h>
#include <LuceneKit/Index/LCSegmentInfo.h>
#include "TestDocHelper.h"

@interface TestDocumentWriter: NSObject <UKTest>
@end

@implementation TestDocumentWriter
- (void) testDocumentWriter
{
	LCRAMDirectory *dir = [[LCRAMDirectory alloc] init];
	LCDocument *testDoc = [[LCDocument alloc] init];
	[TestDocHelper setupDoc: testDoc];
	UKNotNil(dir);
	LCAnalyzer *analyzer = [[LCWhitespaceAnalyzer alloc] init];
	LCSimilarity *similarity= [LCSimilarity defaultSimilarity];
	LCDocumentWriter *writer = [[LCDocumentWriter alloc] initWithDirectory: dir
																  analyzer: analyzer similarity: similarity maxFieldLength: 50];
	UKNotNil(writer);
	[writer addDocument: @"test" document: testDoc];
	
#if 0
	//After adding the document, we should be able to read it back in
	LCSegmentReader *reader = [LCSegmentReader segmentReaderWithInfo: [[LCSegmentInfo alloc] initWithName: @"test" numberOfDocuments: 1 directory: dir]];
	UKNotNil(reader);
	LCDocument *doc = [reader document: 0];
	UKNotNil(doc);
	
	//System.out.println("Document: " + doc);
	NSArray *fields = [doc fields: @"textField2"];
	UKNotNil(fields);
	UKIntsEqual(1, [fields count]);
	UKStringsEqual([TestDocHelper FIELD_2_TEXT], [[fields objectAtIndex: 0] string]);
	UKTrue([[fields objectAtIndex: 0] isTermVectorStored]);
	
	fields = [doc fields: @"textField1"];
	UKNotNil(fields);
	UKIntsEqual(1, [fields count]);
	UKStringsEqual([TestDocHelper FIELD_1_TEXT], [[fields objectAtIndex: 0] string]);
	UKFalse([[fields objectAtIndex: 0] isTermVectorStored]);
	
	fields = [doc fields: @"keyField"];
	UKNotNil(fields);
	UKIntsEqual(1, [fields count]);
	UKStringsEqual([TestDocHelper KEYWORD_TEXT], [[fields objectAtIndex: 0] string]);
#endif
}
@end

