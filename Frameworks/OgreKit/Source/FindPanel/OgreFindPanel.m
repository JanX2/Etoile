/* Yen-Ju Chen <yjchenx @ gmail com> 
 * BSD Licence ( or OgreKit License)
 */

#import <OgreKit/OgreFindPanel.h>
#import <OgreKit/OgreFindPanelController.h>
#import "GNUstep.h"

static OgreFindPanel *sharedInstance;
/* Standard find panel */ 
@implementation OgreFindPanel

+ (OgreFindPanel *) sharedFindPanel
{
	if (sharedInstance == nil) {
		sharedInstance = [[OgreFindPanel alloc] initWithContentRect: NSMakeRect(400, 400, 300, 200) 
														   styleMask: NSTitledWindowMask|NSClosableWindowMask
															 backing: NSBackingStoreRetained 
															   defer: NO];
	}
	return sharedInstance;
}

- (id) initWithContentRect: (NSRect) frame
				 styleMask: (unsigned int) mask
				   backing: (NSBackingStoreType) type
					 defer: (BOOL) defer
{
	NSRect rect;
	self = [super initWithContentRect: frame styleMask: mask backing: type defer: defer];
	
	rect = NSMakeRect(10, frame.size.height-10-25, 80, 25);
	findTextLabel = [[NSTextField alloc] initWithFrame: rect];
	[findTextLabel setStringValue: _(@"Find")];
	[findTextLabel setBezeled: NO];
	[findTextLabel setBordered: NO];
	[findTextLabel setDrawsBackground: NO];
	[[self contentView] addSubview: findTextLabel];
	
	rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, frame.size.width - NSMaxX(rect) - 10, rect.size.height);
	findTextField = [[NSTextField alloc] initWithFrame: rect];
	[[self contentView] addSubview: findTextField];
	
	rect = NSMakeRect(frame.size.width-80, 5, 70, 25);
	findNextButton = [[NSButton alloc] initWithFrame: rect];
	[findNextButton setTitle: _(@"Next")];
	[findNextButton setAction: @selector(findNext:)];
	[[self contentView] addSubview: findNextButton];
	
	rect = NSMakeRect(NSMinX(rect)-5-rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
	findPreviousButton = [[NSButton alloc] initWithFrame: rect];
	[findPreviousButton setTitle: _(@"Previous")];
	[findPreviousButton setAction: @selector(findPrevious:)];
	[[self contentView] addSubview: findPreviousButton];
	
	return self;
}

- (NSTextField *) findTextField
{
	return findTextField;
}

- (void) setFindPanelController: (OgreFindPanelController *) controller
{
	ASSIGN(findPanelController, controller);
	/* Assign target */
	[findNextButton setTarget: controller];
	[findPreviousButton setTarget: controller];
}

- (OgreFindPanelController *) findPanelController
{
	return findPanelController;
}


@end
