#include <LuceneKit/Store/LCFSIndexInput.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@implementation LCFSIndexInput

- (id) copyWithZone: (NSZone *) zone;
{
	LCFSIndexInput *clone = [[LCFSIndexInput allocWithZone: zone] initWithFile: path];
	[clone seek: [self filePointer]];
	return clone;
}

- (id) initWithFile: (NSString *) absolutePath
{
	self = [self init];
	ASSIGN(path, absolutePath);
	ASSIGN(handle, [NSFileHandle fileHandleForReadingAtPath: absolutePath]);
	NSFileManager *manager = [NSFileManager defaultManager];
	NSDictionary *d = [manager fileAttributesAtPath: absolutePath
									   traverseLink: YES];
	length = [[d objectForKey: NSFileSize] longValue];
	return self;
}

- (char) readByte
{
	char b;
	NSData *d = [handle readDataOfLength: 1];
	[d getBytes: &b length: 1];
	return b;
}

- (void) readBytes: (NSMutableData *) b 
			offset: (int) offset length: (int) len
{
	NSData *d = [handle readDataOfLength: len];
	unsigned l = [d length];
	NSRange r = NSMakeRange(offset, l);
	char *buf = malloc(sizeof(char)*l);
	[d getBytes: buf length: l];
	[b replaceBytesInRange: r withBytes: buf];
	free(buf);
	buf = NULL;
}

- (unsigned long long) filePointer
{
	return [handle offsetInFile];
}

- (void) seek: (unsigned long long) pos
{
	if (pos < [self length])
		[handle seekToFileOffset: pos];
	else
		[handle seekToEndOfFile];
}

/** IndexInput methods */
- (void) close
{
	[handle closeFile];
}

- (unsigned long long) length
{
	return length;
}

- (void) dealloc
{
	[self close];
	DESTROY(handle);
	DESTROY(path);
	[super dealloc];
}

@end
