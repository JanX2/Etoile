#include "LCDocumentWriter.h"
#include "GNUstep.h"
#include <UnitKit/UnitKit.h>
#include "LCRAMDirectory.h"
#include "LCWhitespaceAnalyzer.h"
#include "LCSegmentReader.h"
#include "LCSegmentInfo.h"
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
	NSString *segName = @"test";
	[writer addDocument: segName document: testDoc];
	
	//After adding the document, we should be able to read it back in
	LCSegmentReader *reader = [LCSegmentReader segmentReaderWithInfo: [[LCSegmentInfo alloc] initWithName: segName numberOfDocuments: 1 directory: dir]];
	UKNotNil(reader);
	LCDocument *doc = [reader document: 0];
	UKNotNil(doc);
	
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

	fields = [doc fields: [TestDocHelper NO_NORMS_KEY]];
	UKNotNil(fields);
	UKIntsEqual(1, [fields count]);
	UKStringsEqual([TestDocHelper NO_NORMS_TEXT], [[fields objectAtIndex: 0] string]);

	fields = [doc fields: [TestDocHelper TEXT_FIELD_3_KEY]];
	UKNotNil(fields);
	UKIntsEqual(1, [fields count]);
	UKStringsEqual([TestDocHelper FIELD_3_TEXT], [[fields objectAtIndex: 0] string]);

	// test that the norm file is not present if omitNorms is true
	int i;
	for(i = 0; i < [[reader fieldInfos] size]; i++) {
		LCFieldInfo *fi = [[reader fieldInfos] fieldInfoWithNumber: i];
		if ([fi isIndexed]) {
			NSString *filename = [NSString stringWithFormat: @"%@.f%d", segName, i];
			BOOL fileExist = [dir fileExists: filename];
			UKTrue([fi omitNorms] == !fileExist);
		}
	}
			

}
@end

