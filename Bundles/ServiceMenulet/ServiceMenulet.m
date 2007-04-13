#import "ServiceMenulet.h"
#import <GNUstepGUI/GSServicesManager.h>

static NSString *AZPerformServiceNotification = @"AZPerformServiceNotification";
static NSString *AZServiceItem = @"AZServiceItem";

@interface GSServicesManager (ServiceMenulet)
- (void) doService: (NSMenuItem*) item;
@end

@interface ServiceButton: NSButton
@end

@implementation GSServicesManager (ServiceMenulet)
- (BOOL) validateMenuItem: (id <NSMenuItem>) item
{
    // FIXME: we should ask application about this, but it can be difficult.
    /* We always return YES so that users can use any service */
    return YES;
}

- (void) doService: (NSMenuItem*)item
{
    /* service_title can be used in NSPerformService straight */
    NSString *service_title = [self item2title: item];
    if (service_title)
    {
	/* We post a notification to any application which
	   want to run a services for us */
	[[[NSWorkspace sharedWorkspace] notificationCenter] 
		postNotificationName: AZPerformServiceNotification
		object: self
		userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			service_title, AZServiceItem, nil]];
    }
}

@end

@implementation ServiceButton
- (void) mouseDown: (NSEvent *) event
{
    GSServicesManager *manager = [GSServicesManager manager];
    [NSMenu popUpContextMenu: [manager servicesMenu]
                   withEvent: event 
		     forView:self];
//    [super mouseDown: event];
}
@end

@implementation ServiceMenulet

- (void) dealloc
{
  DESTROY(view);
  [super dealloc];
}

- (id) init
{
  NSRect rect = NSZeroRect;

  self = [super init];

  /* We have to register in order to have service menu.
     Should we register every possible type ? */
  NSArray *sends = [NSArray arrayWithObjects:NSStringPboardType, nil];
  NSArray *returns = [NSArray arrayWithObjects:NSStringPboardType, nil];
  [NSApp registerServicesMenuSendTypes: sends returnTypes: returns];

  rect.size.height = 22;
  rect.size.width = 50;
  view = [[ServiceButton alloc] initWithFrame: rect];
  [view setBordered: NO];
  [view setTitle: @"Services"];
  NSMenu *menu = [[NSMenu alloc] initWithTitle: @"Services"];
  [NSApp setServicesMenu: menu];
#if 0
  GSServicesManager *manager = [GSServicesManager manager];
  NSLog(@"%@", [manager servicesMenu]);
  [view setMenu: [manager servicesMenu]];
  [view setMenu: menu];
#endif
  DESTROY(menu);

  return self;
}

- (NSView *) menuletView
{
  return (NSView *)view;
}

@end
