/*
 * Initial version
 * by Yen-Ju Chen <yjchenx @ gmail com>
 * 
 * GUI cleanup, replaceAndFind button, searchAll button, key view loop, focusing behaviour
 * by Guenther Noack <guenther@unix-ag.uni-kl.de>
 * 
 * BSD License ( or OgreKit License)
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
    sharedInstance = [[OgreFindPanel alloc] initWithContentRect: NSMakeRect(400, 400, 380, 150) 
                     styleMask: NSTitledWindowMask|NSClosableWindowMask
		     backing: NSBackingStoreBuffered
		     defer: NO];
  }
  return sharedInstance;
}

- (void) switchButtonAction: (id) sender
{
  if (sender == regexButton) 
  {
    if ([regexButton state] == NSOnState) 
    {
      [findPanelController setSyntax: OgreRubySyntax];
    } 
    else 
    {
      [findPanelController setSyntax: OgreSimpleMatchingSyntax];
    }
  } 
  else if (sender == caseSensitiveButton) 
  {
    if ([caseSensitiveButton state] == NSOnState) 
    {
      [findPanelController setOptions: OgreNoneOption];
    } 
    else 
    {
      [findPanelController setOptions: OgreIgnoreCaseOption];
    }
  }
  else if (sender == inSelectionButton) 
  {
    if ([inSelectionButton state] == NSOnState) 
    {
      [findPanelController setInSelection: YES];
    } 
    else 
    {
      [findPanelController setInSelection: NO];
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
      
      if (self == nil) {
        return self;
      }
      
      [self setTitle: _(@"Find Panel")];
      
	rect = NSMakeRect(5, frame.size.height-5-25, 90, 22);
	findTextLabel = [[NSTextField alloc] initWithFrame: rect];
	[findTextLabel setStringValue: _(@"Find:")];
	[findTextLabel setBezeled: NO];
	[findTextLabel setBordered: NO];
	[findTextLabel setAlignment: NSRightTextAlignment];
	[findTextLabel setDrawsBackground: NO];
        [findTextLabel setSelectable: NO];
	[[self contentView] addSubview: findTextLabel];
	
	rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, frame.size.width - NSMaxX(rect) - 10, rect.size.height);
	findTextField = [[NSTextField alloc] initWithFrame: rect];
	[findTextField setAction: @selector(findNext:)];
	[[self contentView] addSubview: findTextField];

	rect = NSMakeRect(5, rect.origin.y-5-22, 90, 22);
	replaceTextLabel = [[NSTextField alloc] initWithFrame: rect];
	[replaceTextLabel setStringValue: _(@"Replace with:")];
	[replaceTextLabel setBezeled: NO];
	[replaceTextLabel setBordered: NO];
	[replaceTextLabel setAlignment: NSRightTextAlignment];
        [replaceTextLabel setSelectable: NO];
	[replaceTextLabel setDrawsBackground: NO];
	[[self contentView] addSubview: replaceTextLabel];
	
	rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, frame.size.width - NSMaxX(rect) - 10, rect.size.height);
	replaceTextField = [[NSTextField alloc] initWithFrame: rect];
	[[self contentView] addSubview: replaceTextField];

	rect = NSMakeRect(10, rect.origin.y-5-22, 140, 22);
	caseSensitiveButton = [[NSButton alloc] initWithFrame: rect];
	[caseSensitiveButton setButtonType: NSSwitchButton];
	[caseSensitiveButton setTitle: _(@"Case Sensitive")];
	[caseSensitiveButton setTarget: self];
	[caseSensitiveButton setAction: @selector(switchButtonAction:)];
        [caseSensitiveButton sizeToFit];
        rect.size = [caseSensitiveButton bounds].size;
        rect.origin.x = 5 + 90 + 5;
        [caseSensitiveButton setFrame: rect];
	[[self contentView] addSubview: caseSensitiveButton];

	rect = NSMakeRect(NSMaxX(rect)+10, rect.origin.y, 140, rect.size.height);
	regexButton = [[NSButton alloc] initWithFrame: rect];
	[regexButton setButtonType: NSSwitchButton];
	[regexButton setTitle: _(@"Regular Expression")];
	[regexButton setTarget: self];
	[regexButton setAction: @selector(switchButtonAction:)];
	[[self contentView] addSubview: regexButton];

	rect = NSMakeRect(10, rect.origin.y-5-22, 140, 22);
	inSelectionButton = [[NSButton alloc] initWithFrame: rect];
	[inSelectionButton setButtonType: NSSwitchButton];
	[inSelectionButton setTitle: _(@"Only in selected text")];
	[inSelectionButton setTarget: self];
	[inSelectionButton setAction: @selector(switchButtonAction:)];
        [inSelectionButton sizeToFit];
        rect.size = [inSelectionButton bounds].size;
        rect.origin.x = 5 + 90 + 5;
        [inSelectionButton setFrame: rect];
	[[self contentView] addSubview: inSelectionButton];

	rect = NSMakeRect(frame.size.width-5-120, 5, 120, 25);
	findNextButton = [[NSButton alloc] initWithFrame: rect];
        [findNextButton setButtonType: NSMomentaryLightButton];
//        [findNextButton setBezelStyle: NSRoundedBezelStyle];
	[findNextButton setTitle: _(@"Next")];
	[findNextButton setAction: @selector(findNext:)];
        [findNextButton sizeToFit];
        rect.size = [findNextButton bounds].size;
        rect.origin.x = frame.size.width-10-rect.size.width;
        [findNextButton setFrame: rect];
	[[self contentView] addSubview: findNextButton];
	
	rect = NSMakeRect(NSMinX(rect)-5-rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
	findPreviousButton = [[NSButton alloc] initWithFrame: rect];
        [findPreviousButton setButtonType: NSMomentaryLightButton];
//        [findPreviousButton setBezelStyle: NSRoundedBezelStyle];
	[findPreviousButton setTitle: _(@"Previous")];
	[findPreviousButton setAction: @selector(findPrevious:)];
        [findPreviousButton sizeToFit];
        rect.size = [findPreviousButton bounds].size;
        rect.origin.x = NSMinX([findNextButton frame])-5-rect.size.width;
        [findPreviousButton setFrame: rect];
	[[self contentView] addSubview: findPreviousButton];

	rect = NSMakeRect(NSMinX(rect)-5-rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
	replaceAndFindButton = [[NSButton alloc] initWithFrame: rect];
        [replaceAndFindButton setButtonType: NSMomentaryLightButton];
//        [replaceAndFindButton setBezelStyle: NSRoundedBezelStyle];
	[replaceAndFindButton setTitle: _(@"Replace & Find")];
	[replaceAndFindButton setAction: @selector(replaceAndFind:)];
        [replaceAndFindButton sizeToFit];
        rect.size = [replaceAndFindButton bounds].size;
        rect.origin.x = NSMinX([findPreviousButton frame])-5-rect.size.width;
        [replaceAndFindButton setFrame: rect];
	[[self contentView] addSubview: replaceAndFindButton];
	
	rect = NSMakeRect(NSMinX(rect)-5-rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
	replaceButton = [[NSButton alloc] initWithFrame: rect];
        [replaceButton setButtonType: NSMomentaryLightButton];
//        [replaceButton setBezelStyle: NSRoundedBezelStyle];
	[replaceButton setTitle: _(@"Replace")];
	[replaceButton setAction: @selector(replace:)];
        [replaceButton sizeToFit];
        rect.size = [replaceButton bounds].size;
        rect.origin.x = NSMinX([replaceAndFindButton frame])-5-rect.size.width;
        [replaceButton setFrame: rect];
	[[self contentView] addSubview: replaceButton];
	
	rect = NSMakeRect(NSMinX(rect)-5-rect.size.width, rect.origin.y, rect.size.width, rect.size.height);
	replaceAllButton = [[NSButton alloc] initWithFrame: rect];
        [replaceAllButton setButtonType: NSMomentaryLightButton];
//        [replaceAllButton setBezelStyle: NSRoundedBezelStyle];
	[replaceAllButton setTitle: _(@"Replace All")];
	[replaceAllButton setAction: @selector(replaceAll:)];
        [replaceAllButton sizeToFit];
        rect.size = [replaceAllButton bounds].size;
        rect.origin.x = NSMinX([replaceButton frame])-5-rect.size.width;
        [replaceAllButton setFrame: rect];
	[[self contentView] addSubview: replaceAllButton];
	
	// Set up key view loop
	[findTextField setNextKeyView: replaceTextField];
	[replaceTextField setNextKeyView: caseSensitiveButton];
	[caseSensitiveButton setNextKeyView: regexButton];
	[regexButton setNextKeyView: inSelectionButton];
	[inSelectionButton setNextKeyView: replaceAllButton];
	[replaceAllButton setNextKeyView: replaceButton];
	[replaceButton setNextKeyView: replaceAndFindButton];
	[replaceAndFindButton setNextKeyView: findPreviousButton];
	[findPreviousButton setNextKeyView: findNextButton];
	[findNextButton setNextKeyView: findTextField];
	
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
	[findTextField setTarget: controller];
	[findNextButton setTarget: controller];
	[findPreviousButton setTarget: controller];
	[replaceAndFindButton setTarget: controller];
	[replaceButton setTarget: controller];
	[replaceAllButton setTarget: controller];
	[self switchButtonAction: regexButton];
	[self switchButtonAction: caseSensitiveButton];
	[self switchButtonAction: inSelectionButton];
}

- (OgreFindPanelController *) findPanelController
{
	return findPanelController;
}

@end
