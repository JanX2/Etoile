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
#import "CocoaCompatibility.h"
#import "PKPrefPanesRegistry.h"
#import "PKPreferencePane.h"
#import "PKPresentationBuilder.h"
#import "PKPreferencesController.h"

#ifdef GNUSTEP  // build failed on mac
const NSString *PKNoPresentationMode;
const NSString *PKToolbarPresentationMode;
const NSString *PKTablePresentationMode;
const NSString *PKOtherPresentationMode;
#endif


@interface PKPreferencesController (Private)
- (void) windowWillClose: (NSNotification *)aNotification;
- (NSView *) mainViewWaitSign;
@end

@implementation PKPreferencesController

static PKPreferencesController	*sharedInstance = nil;
static BOOL inited = NO;


+ (PKPreferencesController *) sharedPreferencesController
{
	return (sharedInstance ? sharedInstance : [[self alloc] init]);
}

- (id) init
{
    return [self initWithPresentationMode: (NSString *)PKToolbarPresentationMode];
}

- (id) initWithPresentationMode: (NSString *)presentationMode
{
	if (sharedInstance != nil) 
    {
		[self dealloc];
	} 
    else 
    {
        self = [super init];
        
        /* Walk PrefPanes folder and list them. */
        [[PKPrefPanesRegistry sharedRegistry] loadAllPlugins];
        
        /* Request a builder which matches presentationMode to presentation backend. */
        presentation = [PKPresentationBuilder builderForPresentationMode: presentationMode];
        [presentation retain];
        
        inited = NO;
	}
    
	return sharedInstance = self;	
}

/* Initialize stuff that can't be set in the nib/gorm file. */
- (void) awakeFromNib
{
    NSArray *prefPanes;
    
    sharedInstance = self;
        
    // NOTE: [[PKPrefPanesRegistry sharedRegistry] loadAllPlugins]; is not 
    // needed here because -init is called when nib is loaded (checked on Cocoa)
    // Idem for presentationControllerAssociation set up
    
    if ([owner isKindOfClass: [NSWindow class]])
    {
        /* Let the system keep track of where it belongs */
        [owner setFrameAutosaveName: @"PreferencesMainWindow"];
        [owner setFrameUsingName: @"PreferencesMainWindow"];
    }

    /* In subclasses, we set up our list view where preference panes will be
       listed. */
    [presentation loadUI];

    prefPanes = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins];
    
    if (prefPanes != nil)
    {
        NSString *identifier = 
            [[prefPanes objectAtIndex: 0] objectForKey: @"identifier"];
	
        /* Load a first pane. */
        [self selectPreferencePaneWithIdentifier: identifier];
    }
    else
    {
        NSLog(@"No PreferencePane loaded are available.");
    }
}

/*
 * Preference pane related methods
 */

/** Sets or resets up completely the currently selected <strong>preference 
pane</strong> UI.
<p>By being the main bottleneck for switching preference panes, this method
must be called each time a new preference pane is selected like with
<ref>-selectedPreferencePaneWithIdentifier:</ref> method.</p> */
- (BOOL) updateUIForPreferencePane: (PKPreferencePane *)requestedPane
{
    NSView *prefsView = [self preferencesView];
    
    if (currentPane != nil)	/* Have a previous pane that needs unloading? */
	{
		/* Make sure last text field gets an "end editing" message: */
		if ([currentPane autoSaveTextFields])
			[[prefsView window] selectNextKeyView: self];
		
		if(requestedPane) /* User passed in a new pane to select? */
		{
			switch ([currentPane shouldUnselect])	/* Ask old one to unselect.
                */
			{
				case NSUnselectCancel:
					nextPane = nil;
					return NO;
					break;
                    
				case NSUnselectLater:
					nextPane = requestedPane;	/* Remember next pane for later.
                    */
					return NO;
                    break;
                    
				case NSUnselectNow:
					nextPane = nil;
					break;
			}
		}
		else /* Nil in currentPane. Called in response to replyToUnselect: to
            signal 'ok': */
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
        NSRect wBox = [prefsView frame];
        box.origin.x = truncf(abs(wBox.size.width -box.size.width) /2);
        box.origin.y = truncf(abs(wBox.size.height -box.size.height) /2);
        [mainViewWaitSign setFrameOrigin: box.origin];
        [prefsView addSubview: mainViewWaitSign];
        [prefsView setNeedsDisplay: YES];
        [prefsView display];
    }
	
	/* Get main view for next pane: */
	[requestedPane setOwner: self];
	NSView *paneView = [requestedPane mainView];
    // NOTE: By security, we check both frame origin and
    // autoresizing.
    [paneView setFrameOrigin: NSMakePoint(0, 0)];
    [paneView setAutoresizingMask: NSViewNotSizable];
	[requestedPane willSelect];
	
	/* Resize window so content area is large enough for prefs: */
	[presentation resizePreferencesViewForView: paneView];
	
	/* Remove "wait" sign, show new pane: */
    if (mainViewWaitSign != nil)
        [mainViewWaitSign removeFromSuperview];
	[prefsView addSubview: paneView];
	
	/* Finish up by setting up key views and remembering new current pane: */
	currentPane = requestedPane;
    // FIXME: The hack below will have to be decently reimplemented in order we
    // we can support not resigning first responder for other presentation
    // views when a new pane gets selected.
    if ([[self presentationMode] isEqual: PKTablePresentationMode] == NO)
        [[prefsView window] makeFirstResponder: [requestedPane initialKeyView]];
	[requestedPane didSelect];
	
	/* Message window title:
        [[prefsView window] setTitle: [dict objectForKey: @"name"]]; */
	
	return YES;
}

/** <p>Switches to <strong>preference pane</strong> with the given identifier.
    </p> 
    <p>This method needs to be call in <ref>-switchPreferencePaneView:</ref>.</p> */
- (void) selectPreferencePaneWithIdentifier: (NSString *)identifier
{
    /* If the preference pane is already selected, we don't take in account the
    request, especially because it we reloads another instance of the pane 
    view on top of the current one. */
    if ([[self selectedPreferencePaneIdentifier] isEqualToString: identifier])
        return;

    PKPreferencePane *pane = [[PKPrefPanesRegistry sharedRegistry] 
        preferencePaneWithIdentifier: identifier];
    
    if ([presentation respondsToSelector: @selector(willSelectPreferencePaneWithIdentifier:)])
        [presentation willSelectPreferencePaneWithIdentifier: identifier];
    
    [self updateUIForPreferencePane: pane];
    
    if ([presentation respondsToSelector: @selector(didSelectPreferencePaneWithIdentifier:)])
        [presentation didSelectPreferencePaneWithIdentifier: identifier];
}

/*
 * Runtime stuff (ripped from Preferences.app by Jeff Teunissen)
 */

- (BOOL) respondsToSelector: (SEL) aSelector
{
	if (aSelector == NULL)
		return NO;

	if ([super respondsToSelector: aSelector])
		return YES;
    
    if (presentation != nil)
        return [presentation respondsToSelector: aSelector];

	if (currentPane != nil)
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
    /* First we try to forward messages to our builder. */
    if ([presentation respondsToSelector: [invocation selector]])
        [invocation invokeWithTarget: presentation];
    
    if ([currentPane respondsToSelector: [invocation selector]])
        [invocation invokeWithTarget: currentPane];
}

/*
 * Accessors
 */

/** Returns the view which encloses both preference pane loaded view and 
    presentation view where where every preferences panes are usually listed, it
    is often a window content view.<br /> 
    To take an example, for [ PKToolbarPreferencesController ], the view which 
    contains both toolbar view and preference pane dedicated view is returned. */
- (NSView *) preferencesView
{
	if (preferencesView == nil && [owner isKindOfClass: [NSWindow class]])
    {
        // FIXME: Hack statement because on GNUstep the view bound to
        // -contentView includes the toolbar view unlike Cocoa (when a
        // toolbar is visible), by the way we have to rely on a special method
        // until GNUstep implementation matches Cocoa better.
        
        #ifndef GNUSTEP
        return [(NSWindow *)owner contentView];
        
        #else
        return [(NSWindow *)owner contentViewWithoutToolbar];
        
        #endif
    }

    return preferencesView;
}

/** Returns the owner object for the current <ref>-preferencesView</ref>, it
    is usually the parent window in order to allow automatic resizing and window 
    title update when selected preference pane changes.<br /> 
    However it is possible to specify an ancestor view when you need to layout 
    <strong>preferences view</strong> with other views in the content view, but 
    this possibility involves to manage resizing yourself by overriding 
    <ref>-resizesPreferencesViewForView:</ref> method. */
- (id) owner;
{
    return owner;
}

/** Returns identifier of the currently selected <strong>preference pane</strong>. */
- (NSString *) selectedPreferencePaneIdentifier
{
    NSArray *plugins = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins]; 
    NSDictionary *plugin = [plugins objectWithValue: currentPane forKey: @"instance"];
    
    return [plugin objectForKey: @"identifier"];
}

/** Returns the currently selected <strong>preference pane</strong>. */
- (PKPreferencePane *) selectedPreferencePane
{
    return currentPane;
}

/** <p>Returns the <strong>wait view</strong> displayed between each preference 
    pane switch until UI is fully set up. By default, it displays a circular 
    progress indicator.</p>
    <p>Overrides this method if you want to provide to customize such wait view.
    </p> */
- (NSView *) mainViewWaitSign
{
    if (mainViewWaitSign == nil)
    {
        // FIXME: We should probably return [self waitView];
        return nil;
    }
    else
    {
        return mainViewWaitSign;
    }
}

/** <override-subclass> */
- (NSString *) presentationMode
{
    return [presentation presentationMode];
}

/** <override-subclass> */
- (void) setPresentationMode: (NSString *)presentationMode
{
    if ([presentationMode isEqual: [presentation presentationMode]])
        return;
    
    id presentationToCheck = [PKPresentationBuilder builderForPresentationMode: presentationMode];
    
    if (presentationToCheck == nil)
    {
        // FIXME: We may throw an exception here.
    }
    else
    {
        [presentation unloadUI];
    
        [presentation release];
        presentation = [presentationToCheck retain];
    
        [presentation loadUI];
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

/** <override-subclass>
    <p>Switches the current preference pane viewed to another one provided by
    <var>sender</var>.</p>
    <p>Overrides this abstract method in your subclass in order to implement this
    behavior by calling <ref>-selectPreferencePaneWithIdentifier:</ref>;
    you have to be able to retrieve the preference pane through your custom
    <var>sender</var>.</p> */
- (IBAction) switchPreferencePaneView: (id)sender
{
    // NOTE: It could be better to have a method like 
    // -preferencePaneIdentifierForSender: on presentation builder side than
    // propagating the action method.
    [presentation switchPreferencePaneView: sender];
}

@end
