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
    sharedInstance = [[OgreFindPanel alloc] initWithContentRect: NSMakeRect(400, 400, 450, 150) 
                     styleMask: NSTitledWindowMask|NSClosableWindowMask
		     backing: NSBackingStoreBuffered
		     defer: NO];
  }
  return sharedInstance;
}

- (void) switchButtonAction: (id) sender
{
  if (sender == regexButton) {
    if ([regexButton state] == NSOnState) {
      [findPanelController setSyntax: OgreRubySyntax];
    } else {
      [findPanelController setSyntax: OgreSimpleMatchingSyntax];
    }
  } else { // case sensitive button
    if ([caseSensitiveButton state] == NSOnState) {
      [findPanelController setOptions: OgreNoneOption];
    } else {
      [findPanelController setOptions: OgreIgnoreCaseOption];
    }
  }
}

- (id) initWithContentRect: (NSRect) frame
		 styleMask: (unsigned int) mask
		   backing: (NSBackingStoreType) type
		     defer: (BOOL) defer
{
	NSRect rect;
	self = [super initWithContentRect: frame 
                                styleMask: mask 
                                  backing: type 
                                    defer: defer];
	
	rect = NSMakeRect(10, frame.size.height-10-25, 80, 25);
	findTextLabel = [[NSTextField alloc] initWithFrame: rect];
	[findTextLabel setStringValue: _(@"Find")];
	[findTextLabel setBezeled: NO];
	[findTextLabel setBordered: NO];
	[findTextLabel setDrawsBackground: NO];
        [findTextLabel setSelectable: NO];
	[[self contentView] addSubview: findTextLabel];
	
	rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, frame.size.width - NSMaxX(rect) - 10, rect.size.height);
	findTextField = [[NSTextField alloc] initWithFrame: rect];
	[[self contentView] addSubview: findTextField];

	rect = NSMakeRect(10, rect.origin.y-10-25, 80, 25);
	replaceTextLabel = [[NSTextField alloc] initWithFrame: rect];
	[replaceTextLabel setStringValue: _(@"Replace")];
	[replaceTextLabel setBezeled: NO];
	[replaceTextLabel setBordered: NO];
        [replaceTextLabel setSelectable: NO];
	[replaceTextLabel setDrawsBackground: NO];
	[[self contentView] addSubview: replaceTextLabel];
	
	rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, frame.size.width - NSMaxX(rect) - 10, rect.size.height);
	replaceTextField = [[NSTextField alloc] initWithFrame: rect];
	[[self contentView] addSubview: replaceTextField];

	rect = NSMakeRect(10, rect.origin.y-10-25, 160, 25);
	caseSensitiveButton = [[NSButton alloc] initWithFrame: rect];
	[caseSensitiveButton setButtonType: NSSwitchButton];
	[caseSensitiveButton setTitle: _(@"Case Sensitive")];
	[caseSensitiveButton setTarget: self];
	[caseSensitiveButton setAction: @selector(switchButtonAction:)];
	[[self contentView] addSubview: caseSensitiveButton];

	rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, 160, 25);
	regexButton = [[NSButton alloc] initWithFrame: rect];
	[regexButton setButtonType: NSSwitchButton];
	[regexButton setTitle: _(@"Regular Expression")];
	[regexButton setTarget: self];
	[regexButton setAction: @selector(switchButtonAction:)];
	[[self contentView] addSubview: regexButton];

	rect = NSMakeRect(frame.size.width-10-120, 5, 120, 25);
	findNextButton = [[NSButton alloc] initWithFrame: rect];
        [findNextButton setButtonType: NSMomentaryLightButton];
        [findNextButton setBezelStyle: NSRoundedBezelStyle];
	[findNextButton setTitle: _(@"Find Next")];
	[findNextButton setAction: @selector(findNext:)];
        [findNextButton sizeToFit];
        rect.size = [findNextButton bounds].size;
        rect.origin.x = frame.size.width-10-rect.size.width;
        [findNextButton setFrame: rect];
	[[self contentView] addSubview: findNextButton];
	
	rect = NSMakeRect(NSMinX(rect)-5-rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
	findPreviousButton = [[NSButton alloc] initWithFrame: rect];
        [findPreviousButton setButtonType: NSMomentaryLightButton];
        [findPreviousButton setBezelStyle: NSRoundedBezelStyle];
	[findPreviousButton setTitle: _(@"Find Previous")];
	[findPreviousButton setAction: @selector(findPrevious:)];
        [findPreviousButton sizeToFit];
        rect.size = [findPreviousButton bounds].size;
        rect.origin.x = NSMinX([findNextButton frame])-5-rect.size.width;
        [findPreviousButton setFrame: rect];
	[[self contentView] addSubview: findPreviousButton];

	rect = NSMakeRect(NSMinX(rect)-5-rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
	replaceButton = [[NSButton alloc] initWithFrame: rect];
        [replaceButton setButtonType: NSMomentaryLightButton];
        [replaceButton setBezelStyle: NSRoundedBezelStyle];
	[replaceButton setTitle: _(@"Replace")];
	[replaceButton setAction: @selector(replace:)];
        [replaceButton sizeToFit];
        rect.size = [replaceButton bounds].size;
        rect.origin.x = NSMinX([findPreviousButton frame])-5-rect.size.width;
        [replaceButton setFrame: rect];
	[[self contentView] addSubview: replaceButton];
	
	return self;
}

- (NSTextField *) findTextField
{
	return findTextField;
}

- (NSTextField *) replaceTextField
{
	return replaceTextField;
}

- (void) setFindPanelController: (OgreFindPanelController *) controller
{
	ASSIGN(findPanelController, controller);
	/* Assign target */
	[findNextButton setTarget: controller];
	[findPreviousButton setTarget: controller];
	[replaceButton setTarget: controller];
	[self switchButtonAction: regexButton];
	[self switchButtonAction: caseSensitiveButton];
}

- (OgreFindPanelController *) findPanelController
{
	return findPanelController;
}

@end
