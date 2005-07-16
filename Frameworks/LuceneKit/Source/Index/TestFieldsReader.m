#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include <LuceneKit/Store/LCRAMDirectory.h>
#include <LuceneKit/Document/LCDocument.h>
#include <LuceneKit/Document/LCField.h>
#include "TestDocHelper.h"
#include <LuceneKit/Index/LCFieldInfos.h>
#include <LuceneKit/Index/LCFieldsReader.h>
#include <LuceneKit/Index/LCDocumentWriter.h>
#include <LuceneKit/Analysis/LCWhitespaceAnalyzer.h>
#include <LuceneKit/Search/LCSimilarity.h>

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
	UKNotNil([doc field: @"textField1"]);
	LCField *field = [doc field: @"textField2"];
	UKNotNil(field);
	UKTrue([field isTermVectorStored]);
	[reader close];
}

@end
