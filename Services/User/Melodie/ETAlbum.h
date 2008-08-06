#import <AppKit/AppKit.h>
#import <CoreObject/CoreObject.h>
#import "ETMusicFile.h"

@interface ETAlbum : COGroup
{
	NSImage *cover;
}
- (BOOL) isOrdered;
- (NSString *) name;
- (NSString *) displayName;
- (NSImage *) icon;

@end
