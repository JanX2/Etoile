/*
	PKPreferencePane.h
 
	Preference pane class (was GSPreferencePane)
 
	Copyright (C) 2004 Uli Kusterer
 
	Author:  Uli Kusterer
             Quentin Mathe
	Date:  August 2004
 
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

#import "PKPreferencePane.h"
#import <AppKit/AppKit.h>

NSString *NSPreferencePaneDoUnselectNotification = @"NSPreferencePaneDoUnselect";
NSString *NSPreferencePaneCancelUnselectNotification = @"NSPreferencePaneCancelUnselect";


@implementation PKPreferencePane

-(id)	initWithBundle: (NSBundle*) bundle
{
	self = [super init];
	
	_bundle = [bundle retain];
	
	return self;
}

-(void)	dealloc
{
	[_bundle release];
	[_topLevelObjects makeObjectsPerformSelector: @selector(release)];
	[_topLevelObjects release];
	
	[super dealloc];
}

/** Returns the bundle instance which the <strong>preference pane</strong> 
    stored. */
-(NSBundle*) bundle
{
	return _bundle;
}

/** <p>Loads preference pane's view by loading the nib file which contains it.
    </p>
    <p>Related nib file is known by <ref>mainNibName</ref>.</p> */
-(NSView*) loadMainView
{
	_topLevelObjects = [[NSMutableArray alloc] init];
	NSDictionary*	ent = [NSDictionary dictionaryWithObjectsAndKeys:
							self, @"NSOwner",
							_topLevelObjects, @"NSTopLevelObjects",
							nil];

	if( ![_bundle loadNibFile: [self mainNibName] externalNameTable: ent withZone: [self zone]] )
		return nil;
	
	[self assignMainView];
	[self mainViewDidLoad];
	
	return _mainView;
}

/** <p>Assigns the main view loaded with <ref>-loadMainView:</ref>.</p>
    <p>By default this method, retrieves the main view by calling 
    <ref>-contentView</ref> on window referenced in the nib file by 
    <code>_window</code> outlet.</p>
    <p>Overrides this method if your preference pane
    view is located in different place within the nib file. Takes note that when 
    assignement is done, <code>_window</code> is released and sets to 
    <code>nil</code>. Finally this method returns <ref>-mainView</ref> if no 
    errors occured, otherwise <code>nil</code>.</p> */
-(NSView *)	assignMainView
{
	[self setMainView: [_window contentView]];
	[_window release];
	_window = nil;
	
	return [self mainView];
}

/** <p>Returns the nib name adverstised as <em>main</em> in enclosing bundle's 
    property list.</p>
    <p>Related nib file is known by <ref>mainNibName</ref>.</p> */
-(NSString*)	mainNibName
{
	return [[_bundle infoDictionary] objectForKey: @"NSMainNibFile"];
}

/** <override-subclass> */
-(void)	willSelect		{}

/** <override-subclass> */
-(void)	didSelect		{}

/** <override-subclass> */
-(void)	willUnselect	{}

/** <override-subclass> */
-(void)	didUnselect		{}

/** <override-subclass>
    <p>Notifies the preference pane that everything is set up and ready to be 
    displayed, similarly to <ref>-windowDidLoad</ref> when the main nib file
    has been awaken. It is called by <ref>-loadMainView</ref> when the main
    view is correctly set. By default this method does nothing.</p>
    <p>Override this method to have extra preference pane view set up according to 
    its stored settings.</p> */
-(void)	mainViewDidLoad	{}

/** <override-subclass>
    Returns a value to state if the preference pane accepts to be deselected
    right now. Various values may be returned, look at 
    <ref>NSPreferencePaneUnselectReply</ref> constants.</p>
    <p>Overrides this method when you want to delay or cancel a deselect request,
    but take note that you will have to call <ref>-replyToShouldUnselect</ref> 
    later (when deselection is processed) if you return 
    <code>NSUnselectLater</code>.</p> */
-(NSPreferencePaneUnselectReply) shouldUnselect
{
	return NSUnselectNow;
}

/** <override-never>
    <p>Asks the preference pane to know if it accepts to be deselected.</p>
    Take care to invoke this method yourself when you have overriden 
    <ref>shouldUnselect:</ref> to return <code>NSUnselectLater</code> (it
    implies you know when the preference should be unselected).<p> */
-(void)	replyToShouldUnselect: (BOOL)shouldUnselect
{
	if( shouldUnselect )
		[_owner updateUIForPreferencePane: nil];
}

/** <p>Sets the preference pane view which is presented to the user.</p>
    <p>Take note, you should avoid to call this method in your code unless you
    have already overriden <ref>-loadMainView</ref> and 
    <ref>-assignMainView</ref>.</p>*/
-(void) setMainView: (NSView*)view
{
	[_mainView autorelease];
	_mainView = [view retain];
}

/** Returns the preference pane view which is presented to the user. */
-(NSView*) mainView
{
	return _mainView;
}

/** Returns the view which initially owns the focus in the responder chain when
    the preference pane view is loaded. */
-(NSView*) initialKeyView
{
	return _initialKeyView;
}

/** Sets the view which initially owns the focus in the responder chain when the
    preference pane view is loaded. */
-(void) setInitialKeyView: (NSView*)view
{
	[_initialKeyView autorelease];
	_initialKeyView = [view retain];
}

/** Returns the view which starts the responder chain bound to the preference 
    pane view. */
-(NSView*) firstKeyView
{
	return _firstKeyView;
}

/** Sets the view which starts the responder chain bound to the preference pane 
    view. */
-(void) setFirstKeyView: (NSView*)view
{
	[_firstKeyView autorelease];
	_firstKeyView = [view retain];
}

/** Returns the view which ends the responder chain bound to the preference pane
    view. */
-(NSView*) lastKeyView
{
	return _lastKeyView;
}

/** Sets the view which ends the responder chain bound to the preference pane
    view. */
-(void) setLastKeyView: (NSView*)view
{
	[_lastKeyView autorelease];
	_lastKeyView = [view retain];
}

/** <override-subclass>
    <p>Returns <code>YES</code> when text fields are asked to resign their 
    responder status when <ref>-shouldUnselect<ref> is going to be called, 
    otherwise returns <code>NO</code> if the preference pane must itself request
    each text field resigning its responder status (to have their content
    saved).</p> 
    <p>By default this method returns <code>YES</code>, but it is possible
    to override it to alter the returned value.</p> */
-(BOOL) autoSaveTextFields
{
	return YES;
}

/** Returns <code>YES</code> when the receiver is the currently selected
    preference pane, otherwise returns <code>NO</code>. */
-(BOOL) isSelected
{
	return( [_owner selectedPreferencePane] == self );
}

/** Not implemented. */
-(void) updateHelpMenuWithArray:(NSArray *)inArrayOfMenuItems
{
	NSLog(@"PKPreferencePane: updateHelpMenuWithArray: not yet implemented.");
}

/* Private */
-(void)	setOwner: (id <PKPreferencePaneOwner>)owner
{
	_owner = owner;
}

@end
