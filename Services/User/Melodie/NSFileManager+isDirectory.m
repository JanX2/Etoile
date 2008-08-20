#import <Foundation/NSFileManager.h>

@implementation NSFileManager (isDirectory)
- (BOOL) directoryExistsAtPath:(NSString*)aPath
{
	BOOL isDir = NO;
	[self fileExistsAtPath:aPath isDirectory:&isDir];
	return isDir;
}
@end
