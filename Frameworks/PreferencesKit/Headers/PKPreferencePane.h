//
//  GSPreferencePane.h
//  GSSystemPreferences
//
//  Created by Uli Kusterer on 22.10.04.
//  Copyright 2004 M. Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@class GSSysPrefsAppDelegate;


// Possible return values for shouldUnselect:
typedef enum NSPreferencePaneUnselectReply
{
    NSUnselectCancel = 0,
    NSUnselectNow = 1,
    NSUnselectLater = 2
} NSPreferencePaneUnselectReply;

// Notifications: (NYI)
extern NSString *NSPreferencePaneDoUnselectNotification;
extern NSString *NSPreferencePaneCancelUnselectNotification;


// Help Menu support (NYI)
#define	kNSPrefPaneHelpMenuInfoPListKey			@"NSPrefPaneHelpAnchors"
#define	kNSPrefPaneHelpMenuTitleKey				@"title"		
#define	kNSPrefPaneHelpMenuAnchorKey			@"anchor"				


// Implementation of PrefPane superclass. Use NSPreferencePane instead, which is a subclass of this.
@interface GSPreferencePane : NSObject
{
	@private
		IBOutlet NSWindow*		_window;			// Window from which to tear out the main view.
	
		IBOutlet NSView*		_initialKeyView;	// Subview of main content view to be initially selected.
		IBOutlet NSView*		_firstKeyView;		// Subview of main content view to start keyboard loop at.
		IBOutlet NSView*		_lastKeyView;		// Subview of main content view to end keyboard loop at.
	
		NSView*					_mainView;			// Main view containing the prefs GUI.
		NSBundle*				_bundle;			// Bundle containing your subclass.
	
		NSMutableArray*			_topLevelObjects;	// In place of Apple's _reserved1.
		GSSysPrefsAppDelegate*	_owner;				// In place of Apple's _reserved2.

		id						_reserved3;
}

-(id)			initWithBundle: (NSBundle*)bundle;

-(NSBundle*)	bundle;

// Load the main view from wherever we want to get it and return it:
//	This should also set up mainView, initialKeyView, firstKeyView and
//	lastKeyView.
-(NSView*) loadMainView;

// Main view was loaded, we're ready to go:
-(void) mainViewDidLoad;

// Name of the NIB file to load for main view and rest of GUI:
-(NSString*) mainNibName;

// Take the content view of _window and make it our main view:
-(void) assignMainView;

// This pane is gonna be/has finished being shown in the window:
-(void) willSelect;
-(void) didSelect;

// Return whether it's okay to unselect this pane now:
//	You can return NSUnselectLater and then later call
//	replyToShouldUnselect: to e.g. ask the user to save changes.
-(NSPreferencePaneUnselectReply) shouldUnselect;

// If shouldUnselect returned NSUnselectLater, call this when "later" has arrived.
-(void)		replyToShouldUnselect: (BOOL)shouldUnselect;

// This pane is gonna be/has finished being removed from the window:
-(void)		willUnselect;
-(void)		didUnselect;

// Accessors for _mainView:
-(void)		setMainView: (NSView*)view;
-(NSView*)	mainView;

// Accessors for view to have keyboard focus when the pane comes up:
-(NSView*)	initialKeyView;
-(void)		setInitialKeyView: (NSView*)view;

// Keyboard tabbing chain:
-(NSView*)	firstKeyView;
-(void)		setFirstKeyView: (NSView*)view;

-(NSView*)	lastKeyView;
-(void)		setLastKeyView: (NSView*)view;

// Should the current text field be asked to give up focus before un-selecting this pane?
-(BOOL)		autoSaveTextFields;

// Is this pane the one currently showing in the window?
-(BOOL)		isSelected;

// Help menu support (NYI):
-(void)		updateHelpMenuWithArray: (NSArray*)inArrayOfMenuItems;


// Private: (GNUstep-specific and subject to change)
-(void)		setOwner: (GSSysPrefsAppDelegate*)owner;

@end



// The class name you should actually use:
@interface NSPreferencePane : GSPreferencePane {}

@end

