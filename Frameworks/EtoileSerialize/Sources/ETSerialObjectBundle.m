#include <unistd.h>
#import <EtoileFoundation/Macros.h>
#import "ETObjectStore.h"

static NSFileManager * filemanager;

@implementation ETSerialObjectBundle

+ (void) initialize
{
	filemanager = [NSFileManager defaultManager];
}

- (id) initWithPath: (NSString *)aPath
{
	SUPERINIT;
	[self setPath: aPath];
	return self;
}

- (id) init
{
	return [self initWithPath: nil];
}

- (void) dealloc
{
	[branch release];
	[bundlePath release];
	[self commit];
	[super dealloc];
}

- (void) setPath: (NSString *)aPath
{
	ASSIGN(bundlePath, aPath);
}

- (BOOL) isValidBranch: (NSString *)aBranch
{
	NSString *filename = [bundlePath stringByAppendingPathComponent: aBranch];
	return [filemanager fileExistsAtPath: filename];
}

- (void) startVersion: (unsigned int)aVersion inBranch: (NSString *)aBranch
{
	NSString *filename = [bundlePath stringByAppendingPathComponent: aBranch];

	// Create a directory for the branch, if there isn't one already
	if (![filemanager fileExistsAtPath: filename])
	{
		[filemanager createDirectoryAtPath: filename attributes: nil];
	}
	filename = [filename stringByAppendingPathComponent:
		[NSString stringWithFormat:@"%d.save", aVersion]];
	file = fopen([filename UTF8String], "w");

	version = aVersion;
	ASSIGN(branch, aBranch);
}

- (NSString*) parentOfBranch: (NSString *)aBranch
{
	// FIXME: This should use a dynamic buffer and catch ENAMETOOLONG.
	char buffer[1024];
	int len = (int)readlink([[bundlePath stringByAppendingPathComponent: aBranch] UTF8String], buffer, 1023);
	buffer[len] = '\0';
	return [NSString stringWithUTF8String: buffer];
}

- (NSData *) dataForVersion: (unsigned int)aVersion inBranch: (NSString *)aBranch
{
	NSString *filename = [bundlePath stringByAppendingPathComponent:aBranch];
	filename = [filename stringByAppendingPathComponent:
		[NSString stringWithFormat:@"%d.save", aVersion]];

	if (![filemanager fileExistsAtPath: filename])
	{
		return nil;
	}
	return [NSData dataWithContentsOfMappedFile: filename];
}

- (void) writeBytes: (unsigned char *)bytes count: (unsigned int)count
{
	fwrite(bytes, count, 1, file);
}

- (void) replaceRange: (NSRange)aRange withBytes: (unsigned char *)bytes
{
	fseek(file, aRange.location, SEEK_SET);
	fwrite(bytes, aRange.length, 1, file);
}

- (void) commit
{
	if (file != 0)
	{
		fclose(file);
	}
	file = 0;
}

- (void) createBranch: (NSString *)newBranch from: (NSString *)oldBranch
{
	NSString *newPath = [bundlePath stringByAppendingPathComponent: newBranch];
	// Create a directory for the branch, if there isn't one already
	if (![filemanager fileExistsAtPath: newPath])
	{
		[filemanager createDirectoryAtPath: newPath attributes: nil];
	}
	NSString *oldPath = [bundlePath stringByAppendingPathComponent: oldBranch];
	NSString *link = [bundlePath stringByAppendingPathComponent: @"previous"];

	if (symlink([link UTF8String], [oldPath UTF8String]) == -1)
	{
		[NSException raise: @"ETFileSystemException"
		            format: @"Failed to create symbolic link at path %@ with error code %i", link, errno];
	}
}

- (unsigned int) size
{
	if(file != 0)
	{
		return ftell(file);
	}
	else
	{
		return 0;
	}
}

- (NSUInteger) version
{
	return version;
}

- (NSString *) branch
{
	return branch;
}

@end
