#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>
#import <AppKit/AppKit.h>

#import "ETOverlayShelf.h"
#import "SidebarController.h"

@interface UIServer : NSObject
{
	ETLayoutItemGroup *_rootGroup;
	NSConnection *_connection;

	ETOverlayShelf *_shelf;
	NSConnection *_shelfConnection;
	SidebarController *_sidebar;
}
+ (id) server;

- (id) init;
- (id) rootGroup;

@end
