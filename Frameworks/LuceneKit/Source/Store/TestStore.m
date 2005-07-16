#include <LuceneKit/Store/LCFSDirectory.h>
#include <LuceneKit/Store/LCIndexInput.h>
#include <LuceneKit/Store/LCIndexOutput.h>
#include <LuceneKit/Store/LCRAMDirectory.h>
#include <LuceneKit/Store/LCRAMFile.h>
#include <UnitKit/UnitKit.h>

@interface TestStore: NSObject <UKTest>
@end

@implementation TestStore

- (void) count: (int) count ram: (BOOL) ram
{
	srandom((int)[[NSDate date] timeIntervalSince1970]);
	int i, j;
	NSString *p, *fs = @"RAM";
    
	id <LCDirectory> store;
	if (ram)
		store = [[LCRAMDirectory alloc] init];
	else
    {
		p = [NSString stringWithFormat: @"LuceneKit_Test_%d_Can_Be_Deleted", (int)random()];
		p = [NSTemporaryDirectory() stringByAppendingPathComponent: p];
		store = [LCFSDirectory getDirectory: [p stringByStandardizingPath]
									 create: YES];
		fs = @"Disk";
		//store = FSDirectory.getDirectory("test.store", true);
    }
	
	srandom(1251971);
	int length, LENGTH_MASK = 0xFFF;
	NSString *name;
	char b;
	NSDate *date = [NSDate date];;
	for (i = 0; i < count; i++) {
		name = [NSString stringWithFormat: @"%d.dat", i];
		length = random() & LENGTH_MASK;
		b = (char)(random() & 0x7F);
		
		LCIndexOutput *file = [store createOutput: name];
		
		for (j = 0; j < length; j++)
			[file writeByte: b];
		
		[file close];
	}
	[store close];
	NSLog(@"Write %d files in %@: %f seconds", count, fs, [[NSDate date] timeIntervalSinceDate: date]);
	
	srandom(1251971);
	date = [NSDate date];
	if (!ram)
    {
		//store = FSDirectory.getDirectory("test.store", true);
		store = [LCFSDirectory getDirectory: [p stringByStandardizingPath]
									 create: NO];
    }
	for (i = 0; i < count; i++)
	{
		name = [NSString stringWithFormat: @"%d.dat", i];
		length = random() & LENGTH_MASK;
		b = (char)(random() & 0x7F);
		
		LCIndexInput *ii = [store openInput: name];
		UKIntsEqual(length, [ii length]);
		for (j = 0; j < length; j++)
			UKIntsEqual(b, (int)[ii readByte]);
		[ii close];
    }
	NSLog(@"Read %d files in %@: %f seconds", count, fs, [[NSDate date] timeIntervalSinceDate: date]);
	
	UKIntsEqual(count, [[store fileList] count]);
	
	date = [NSDate date];
	for (i = 0; i < count; i++) {
		name = [NSString stringWithFormat: @"%d.dat", i];
		[store deleteFile: name];
	}
	NSLog(@"Delete %d files in %@: %f seconds", count, fs, [[NSDate date] timeIntervalSinceDate: date]);
	
	UKIntsEqual(0, [[store fileList] count]);
	[store close];
	
	if (!ram)
		[[NSFileManager defaultManager] removeFileAtPath: p handler: nil];
}

- (void) testRAM
{
	// [self count: 10 ram: YES];
}

- (void) testFS
{
	// [self count: 10 ram: NO];
}

- (void) doTestClone: (BOOL) ram
{
	srandom((int)[[NSDate date] timeIntervalSince1970]);
	int j;
	NSString *p, *fs = @"RAM";
    
	id <LCDirectory> store;
	if (ram)
		store = [[LCRAMDirectory alloc] init];
	else
    {
		p = [NSString stringWithFormat: @"LuceneKit_Test_%d_Can_Be_Deleted", (int)random()];
		p = [NSTemporaryDirectory() stringByAppendingPathComponent: p];
		store = [LCFSDirectory getDirectory: [p stringByStandardizingPath]
									 create: YES];
		fs = @"Disk";
		//store = FSDirectory.getDirectory("test.store", true);
    }
	
	NSString *name = @"1.dat";
	LCIndexOutput *file = [store createOutput: name];
	for (j = 0; j < 10; j++)
		[file writeByte: (j+'0')];
	for (j = 0; j < 26; j++)
		[file writeByte: (j+'A')];
	
	[file close];
	
	LCIndexInput *input = [store openInput: name];
	UKIntsEqual('0', [input readByte]);
	[input seekToFileOffset: 10];
	UKIntsEqual('A', [input readByte]);
	LCIndexInput *clone = [input copy];
	UKIntsEqual([input readByte], [clone readByte]);
	UKIntsEqual('C', [clone readByte]);
	[clone seekToFileOffset: 0];
	UKIntsEqual('0', [clone readByte]);
	UKIntsEqual('C', [input readByte]);
	UKIntsEqual(1, [clone offsetInFile]);
	UKIntsEqual(13, [input offsetInFile]);
	[input close];
	if (!ram)
		[[NSFileManager defaultManager] removeFileAtPath: p handler: nil];
}

- (void) testRAMClone
{
	[self doTestClone: YES];
}

- (void) testFSClone
{
	[self doTestClone: NO];
}

@end
