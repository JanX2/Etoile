#import <EtoileFoundation/Macros.h>
#import "ETObjectStore.h"

@implementation ETSerialObjectBuffer

- (id) init 
{
	SUPERINIT;
	buffer = [[NSMutableData alloc] initWithCapacity: 1024];
	return self;
}

- (void) dealloc
{
	[buffer release];
	[branch release];
	[super dealloc];
}

- (void) startVersion: (unsigned int)aVersion inBranch: (NSString *)aBranch
{
	version = aVersion;
	[aBranch retain];
	[branch release];
	branch = aBranch;
}

- (NSData *) dataForVersion: (unsigned int)aVersion inBranch: (NSString *)aBranch
{
	if (aVersion == version && [branch isEqualToString: aBranch])
	{
		return buffer;
	}
	return nil;
}

- (void) writeBytes: (unsigned char *)bytes count: (unsigned int)count
{
	[buffer appendBytes: bytes length: count];
}

- (void) replaceRange: (NSRange)aRange withBytes: (unsigned char *)bytes
{
	[buffer replaceBytesInRange: aRange withBytes: bytes length: aRange.length];
}

- (BOOL) isValidBranch: (NSString *)aBranch
{
	return [aBranch isEqualToString: branch];
}

- (NSData *) buffer
{
	return buffer;
}

- (unsigned int) version
{
	return version;
}

- (NSString *) branch
{
	return branch;
}

- (unsigned int) size
{
	return [buffer length];
}

// Methods that don't apply to buffers
- (void) commit {}
- (void) createBranch: (NSString *)newBranch from: (NSString *)oldBranch {}
- (NSString *) parentOfBranch: (NSString *)aBranch { return nil; }

@end
