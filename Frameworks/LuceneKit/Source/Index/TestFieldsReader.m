#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include "Store/LCRAMDirectory.h"
#include "Document/LCDocument.h"
#include "Document/LCField.h"
#include "TestDocHelper.h"
#include "Index/LCFieldInfos.h"
#include "Index/LCFieldsReader.h"
#include "Index/LCDocumentWriter.h"
#include "Analysis/LCWhitespaceAnalyzer.h"
#include "Search/LCSimilarity.h"

@interface TestFieldsReader: NSObject <UKTest> 
{
	LCRAMDirectory *dir;
	LCDocument *testDoc;
	LCFieldInfos *fieldInfos;
}

@end

@implementation TestFieldsReader

- (id) init
{
	self = [super init];
	dir = [[LCRAMDirectory alloc] init];
	testDoc = [[LCDocument alloc] init];
	fieldInfos = [[LCFieldInfos alloc] init];;
	[TestDocHelper setupDoc: testDoc];
	[fieldInfos addDocument: testDoc];
	LCDocumentWriter *writer = [[LCDocumentWriter alloc] initWithDirectory: dir
																  analyzer: [[LCWhitespaceAnalyzer alloc] init]
																similarity: [LCSimilarity defaultSimilarity]
															maxFieldLength: 50];
	UKNotNil(writer);
	[writer addDocument: @"test" document: testDoc];
	return self;
}

- (void) testFieldsReader
{
	UKNotNil(dir);
	UKNotNil(fieldInfos);
	LCFieldsReader *reader = [[LCFieldsReader alloc] initWithDirectory: dir segment: @"test" fieldInfos: fieldInfos];
	UKNotNil(reader);
	UKIntsEqual([reader size], 1);
	LCDocument *doc = [reader document: 0];
	UKNotNil(doc);
	UKNotNil([doc fieldWithName: @"textField1"]);
	LCField *field = [doc fieldWithName: @"textField2"];
	UKNotNil(field);
	UKTrue([field isTermVectorStored]);
	[reader close];
}

@end
