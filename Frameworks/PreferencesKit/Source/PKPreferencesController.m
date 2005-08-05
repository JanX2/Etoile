/*
	PKPreferencesController.m

	Abstract Preferences window controller class

	Copyright (C) 2004 Quentin Mathe
                       Uli Kusterer

	Author:  Quentin Mathe <qmathe@club-internet.fr>
             Uli Kusterer
    Date:  February 2005

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <AppKit/AppKit.h>

#ifdef HAVE_UKTEST
#import <UnitKit/UnitKit.h>
#endif

#import "PrefsModule.h"
#import "PKPrefPanesRegistry.h"
#import "PKPreferencePane.h"
#import "PKPreferencesController.h"


#ifndef GNUSTEP

// FIXME: Move such GNUstep imported extensions in a Cocoa compatibility file.
// In GNUstep, this method is located in AppKit within GSToolbar.

@implementation NSArray (ObjectsWithValueForKey)

- (NSArray *) objectsWithValue: (id)value forKey: (NSString *)key 
{
    NSMutableArray *result = [NSMutableArray array];
    NSArray *values = [self valueForKey: key];
    int i, n = 0;
    
    if (values == nil)
        return nil;
    
    n = [values count];
    
    for (i = 0; i < n; i++)
    {
        if ([[values objectAtIndex: i] isEqual: value])
        {
            [result addObject: [self objectAtIndex: i]];
        }
    }
    
    if ([result count] == 0)
        return nil;
    
    return result;
}
@end

#endif 
/* NOT GNUSTEP */

// FIXME: Hack to avoid compiler varning with next method -objectWithValue:forKey:
@interface NSArray (ObjectsWithValueForKey)
- (id) objectsWithValue: (id)value forKey: (NSString *)key;
@end

// FIXME: Move -objectWithValue:forKey: method in a more appropriate place.

@implementation NSArray (ObjectWithValueForKey)

- (id) objectWithValue: (id)value forKey: (NSString *)key
{
    return [[self objectsWithValue: value forKey: key] objectAtIndex: 0];
}

@end

@interface PKPreferencesController (Private)
- (void) initExtra;
- (void) windowWillClose: (NSNotification *)aNotification;
- (NSView *) mainViewWaitSign;
@end

@implementation PKPreferencesController

static PKPreferencesController	*sharedInstance = nil;
static BOOL 		inited = NO;

+ (PKPreferencesController *) sharedPreferencesController
{
	return (sharedInstance ? sharedInstance : [[self alloc] init]);
}

- (id) init
{
	if (sharedInstance != nil) 
    {
		[self dealloc];
	} 
    else 
    {
		self = [super init];
        
        [self initExtra];
        
        inited = NO;
	}
    
	return sharedInstance = self;	
}

- (void) initExtra
{
    /* Walk PrefPanes folder and list them: */
    [[PKPrefPanesRegistry sharedRegistry] loadAllPlugins];
}

/* Initialize stuff that can't be set in the nib/gorm file. */
- (void) awakeFromNib
{
    NSArray *prefPanes; 
	NSString *path;
    
    sharedInstance = self;
    
    // NOTE: [self initExtra]; is not needed here because -init is called when nib is loaded (checked on Cocoa)
    
    prefPanes = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins];
    
    if (prefPanes != nil)
    {
        path = [[prefPanes objectAtIndex: 0] objectForKey: @"path"];
	
        /* Load a first pane. */
        [self updateUIForPreferencePane: 
            [[PKPrefPanesRegistry sharedRegistry] preferencePaneAtPath: path]];
    }
    else
    {
        NSLog(@"No PreferencePane loaded are available.");
    }
    
	/* Let the system keep track of where it belongs */
    if ([owner isKindOfClass: [NSWindow class]])
    {
        [owner setFrameAutosaveName: @"PreferencesMainWindow"];
        [owner setFrameUsingName: @"PreferencesMainWindow"];
    }
	
	[self initUI];
}

/*
 * Preferences window UI stuff
 */

- (void) initUI
{
    
}

/*
 * Abstract methods
 */

- (NSView *) preferencesListView
{
    return nil;
}

- (void) resizePreferencesViewForView: (NSView *)view
{

}

/*
 * Preference pane related methods
 */

/* Main bottleneck for switching panes: */
- (BOOL) updateUIForPreferencePane: (PKPreferencePane *)requestedPane
{
    NSView *mainViewContainer = [self preferencesView];
    
    if (currentPane != nil)	/* Have a previous pane that needs unloading? */
	{
		/* Make sure last text field gets an "end editing" message: */
		if ([currentPane autoSaveTextFields])
			[[mainViewContainer window] selectNextKeyView: self];
		
		if(requestedPane) /* User passed in a new pane to select? */
		{
			switch ([currentPane shouldUnselect])	/* Ask old one to unselect. */
			{
				case NSUnselectCancel:
					nextPane = nil;
					return NO;
					break;
                    
				case NSUnselectLater:
					nextPane = requestedPane;	/* Remember next pane for later. */
					return NO;
                    break;
                    
				case NSUnselectNow:
					nextPane = nil;
					break;
			}
		}
		else /* Nil in currentPane. Called in response to replyToUnselect: to signal 'ok': */
		{
			requestedPane = nextPane;	/* Continue where we left off. */
			nextPane = nil;
		}
		
		/* Unload the old pane: */
		[currentPane willUnselect];
		[[currentPane mainView] removeFromSuperview];
		[currentPane didUnselect];
		currentPane = nil;
	}
	
	/* Display "please wait" message in middle of content area: */
    if (mainViewWaitSign != nil)
    {
        NSRect box = [mainViewWaitSign frame];
        NSRect wBox = [mainViewContainer frame];
        box.origin.x = truncf(abs(wBox.size.width -box.size.width) /2);
        box.origin.y = truncf(abs(wBox.size.height -box.size.height) /2);
        [mainViewWaitSign setFrameOrigin: box.origin];
        [mainViewContainer addSubview: mainViewWaitSign];
        [mainViewContainer setNeedsDisplay: YES];
        [mainViewContainer display];
    }
	
	/* Get main view for next pane: */
	[requestedPane setOwner: self];
	NSView *theView = [requestedPane mainView];
	[requestedPane willSelect];
	
	/* Resize window so content area is large enough for prefs: */
	[self resizePreferencesViewForView: theView];
	
	/* Remove "wait" sign, show new pane: */
    if (mainViewWaitSign != nil)
        [mainViewWaitSign removeFromSuperview];
	[mainViewContainer addSubview: theView];
	
	/* Finish up by setting up key views and remembering new current pane: */
	currentPane = requestedPane;
	[[mainViewContainer window] makeFirstResponder: [requestedPane initialKeyView]];
	[requestedPane didSelect];
	
	/* Message window title:
	[[mainViewContainer window] setTitle: [dict objectForKey: @"name"]]; */
	
	return YES;
    
    /* Previous code:
    NSView *mainView = [self prefsMainView];
	NSView *moduleView = [aPrefsModule view];
	NSRect mavFrame = [mainView frame];
	NSRect movFrame = [moduleView frame];
	NSRect cvFrame = [[window contentView] frame];
	NSRect cvWithoutToolbarFrame = [[window contentViewWithoutToolbar] frame];
	NSRect wFrame = [window frame];
	float height;
	
	if (!aPrefsModule || ![modules objectForKey: [aPrefsModule buttonCaption]]
		|| !moduleView)
		return NO;
	
	[[mainView subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	height = cvFrame.size.height - cvWithoutToolbarFrame.size.height +
	movFrame.size.height;
	
	[window setFrame: NSMakeRect(wFrame.origin.x, wFrame.origin.y + (wFrame.size.height - height),
		wFrame.size.width, height) display: YES animate: YES];	
	[moduleView setFrame: NSMakeRect(mavFrame.origin.x + (cvFrame.size.width - movFrame.size.width) / 2,
		movFrame.origin.y, movFrame.size.width, movFrame.size.height)];
		
	[mainView addSubview: moduleView];
	[mainView setNeedsDisplay: YES];
	
	[window setTitle: [aPrefsModule buttonCaption]];
	
	return YES;
     */
}

/*
 * Runtime stuff (ripped from Preferences.app by Jeff Teunissen)
 */

- (BOOL) respondsToSelector: (SEL) aSelector
{
	if (aSelector == nil)
		return NO;

	if ([super respondsToSelector: aSelector])
		return YES;

	if (currentPane)
		return [currentPane respondsToSelector: aSelector];

	return NO;
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)aSelector
{
	NSMethodSignature * sign = [super methodSignatureForSelector: aSelector];

	if (sign == nil && currentPane) {
		sign = [(NSObject *)currentPane methodSignatureForSelector: aSelector];
	}

	return sign;
}

- (void) forwardInvocation: (NSInvocation *)invocation
{
	[invocation invokeWithTarget: currentPane];
}

/*
 * Accessors
 */

- (NSView *) preferencesView
{
	return preferencesView;
}

- (id) owner;
{
    return owner;
}

- (PKPreferencePane *) selectedPreferencePane
{
    return currentPane;
}

- (NSView *) mainViewWaitSign
{
    if (mainViewWaitSign == nil)
    {
        return [self preferencesView];
    }
    else
    {
        return mainViewWaitSign;
    }
}

/*
 * Notification methods
 */

- (void) windowWillClose: (NSNotification *) aNotification
{
    [currentPane willUnselect];
    [currentPane didUnselect];
}

/*
 * Action methods
 */

- (IBAction) switchView: (id)sender
{
    // NOTE: Subclass responsability
}

@end
