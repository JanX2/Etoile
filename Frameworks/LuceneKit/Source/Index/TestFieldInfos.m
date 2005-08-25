#include <LuceneKit/Index/LCFieldInfos.h>
#include <LuceneKit/GNUstep/GNUstep.h>
#include <UnitKit/UnitKit.h>
#include "TestDocHelper.h"
#include <LuceneKit/Store/LCRAMDirectory.h>

@interface TestFieldInfos: NSObject <UKTest>
@end

@implementation TestFieldInfos;
- (void) testFieldInfos
{
	LCDocument *testDoc = [[LCDocument alloc] init];
	[TestDocHelper setupDoc: testDoc];
	
	//Positive test of FieldInfos
	UKNotNil(testDoc);
	LCFieldInfos *fieldInfos = [[LCFieldInfos alloc] init];
	[fieldInfos addDocument: testDoc];
	
	//Since the complement is stored as well in the fields map
	UKIntsEqual(6, [fieldInfos size]); //this is 6 b/c we are using the no-arg constructor
	LCRAMDirectory *dir = [[LCRAMDirectory alloc] init];
	NSString *name = @"testFile";
	LCIndexOutput *output = [dir createOutput: name];
	UKNotNil(output);
	//Use a RAMOutputStream
	
	[fieldInfos write: output];
	UKTrue([output length] > 0);
	[output close];
	LCFieldInfos *readIn = [[LCFieldInfos alloc] initWithDirectory: dir name: name];
	UKIntsEqual([fieldInfos size], [readIn size]);
	LCFieldInfo *info = [readIn fieldInfo: @"textField1"];
	UKNotNil(info);
	UKFalse([info isTermVectorStored]);
	
	info = [readIn fieldInfo: @"textField2"];
	UKNotNil(info);
	UKTrue([info isTermVectorStored]);
	
	[dir close];
}

@end

