#import "ETObjectStore.h"

@implementation ETSerialObjectBuffer
- (id) init 
{
	if(nil == (self = [super init]))
	{
		return nil;
	}
	buffer = [[NSMutableData alloc] initWithCapacity:1024];
	return self;
}

- (void) startVersion:(unsigned)aVersion inBranch:(NSString*)aBranch
{
	version = aVersion;
	[aBranch retain];
	[branch release];
	branch = aBranch;
}

- (NSData*) dataForVersion:(unsigned)aVersion inBranch:(NSString*)aBranch
{
	if (aVersion == version && [branch isEqualToString:aBranch])
	{
		return buffer;
	}
	return nil;
}

- (void) writeBytes:(unsigned char*)bytes count:(unsigned)count
{
	[buffer appendBytes:bytes length:count];
}

- (void) replaceRange:(NSRange)aRange withBytes:(unsigned char*)bytes
{
	[buffer replaceBytesInRange:aRange withBytes:bytes length:aRange.length];
}
- (BOOL) isValidBranch:(NSString*)aBranch
{
	return [aBranch isEqualToString:branch];
}

- (NSData*) buffer
{
	return buffer;
}

- (unsigned) version
{
	return version;
}

- (NSString*) branch
{
	return branch;
}

- (unsigned) size
{
	return [buffer length];
}

- (void) dealloc
{
	[buffer release];
	[branch release];
	[super dealloc];
}
// Methods that don't apply to buffers
- (void) finalize {}
- (void) createBranch:(NSString*)newBranch from:(NSString*)oldBranch {}
- (NSString*) parentOfBranch:(NSString*)aBranch { return nil; }
@end
