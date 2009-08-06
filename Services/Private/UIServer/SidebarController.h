#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>
#import <AppKit/AppKit.h>

@interface SidebarController : NSObject
{
	ETLayoutItemGroup *_sidebarGroup;
}

- (ETLayoutItemGroup *)sidebarGroup;
@end
