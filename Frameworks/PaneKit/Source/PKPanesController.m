/** <title>PKPanesController</title>

	PKPanesController.m

	<abstract>Pane window controller class</abstract>

	Copyright (C) 2006 Yen-Ju Chen 
	Copyright (C) 2004 Quentin Mathe
                           Uli Kusterer

	Author:  Yen-Ju Chen <yjchenx gmail>
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

#import <PaneKit/CocoaCompatibility.h>
#import <PaneKit/PKPaneRegistry.h>
#import <PaneKit/PKPane.h>
#import <PaneKit/PKPresentationBuilder.h>
#import <PaneKit/PKPanesController.h>
#import "GNUstep.h"

@interface PKPanesController (Private)
- (void) windowWillClose: (NSNotification *) not;
- (NSView *) mainViewWaitSign;
@end

/** <p>PKPanesController Description</p> */
@implementation PKPanesController

- (id) init
{
  /* This is usually called by Nib file.
   * In that case, we assume the owner and registry is
   * connected in Nib. */

  self = [super init];

  return self;
}

/* This is usually called programmingly.
   So we call awakeFromNib explicitly */
- (id) initWithRegistry: (PKPaneRegistry *) r
       presentationMode: (const NSString *) mode
       owner: (id) o
{
  self = [super init];

  ASSIGN(registry, r);
  ASSIGN(owner, o);
  /* Request a builder which matches presentationMode to 
   * presentation backend. */
  ASSIGN(presentation, [PKPresentationBuilder builderForPresentationMode: mode]);

  [self awakeFromNib];

  return self;
}

/* Initialize stuff that can't be set in the nib/gorm file. */
- (void) awakeFromNib
{
  if (owner == nil) {
    /* Create an empty window as owner */
    owner = [[NSPanel alloc] initWithContentRect: NSMakeRect(400, 400, 300, 150)
                           styleMask: NSTitledWindowMask|NSClosableWindowMask
                             backing: NSBackingStoreBuffered 
                               defer: YES];
    [owner setReleasedWhenClosed: NO];
    
  }

  if (presentation == nil) {
    /* Use toolbar as default */ 
    ASSIGN(presentation, [PKPresentationBuilder builderForPresentationMode: (NSString *)PKToolbarPresentationMode]);
  }
  [presentation setPanesController: self];
    
  /* In subclasses, we set up our list view where preference panes will be
     listed. */
  [presentation loadUI];

  NSArray *prefPanes = [registry loadedPlugins];
    
  if (prefPanes != nil)
  {
    NSString *identifier = 
        [[prefPanes objectAtIndex: 0] objectForKey: @"identifier"];
	
    /* Load a first pane. */
    [self selectPaneWithIdentifier: identifier];
  }
  else
  {
    NSLog(@"No Pane loaded are available.");
  }
}

/*
 * Preference pane related methods
 */

/** <p>Sets or resets up completely the currently selected <em>preference 
   pane</em> UI.</p>
   <p><strong>By being the main bottleneck for switching preference panes, this 
   method must be called each time a new preference pane is selected like with
   -selectPaneWithIdentifier: method.</strong></p> */
- (BOOL) updateUIForPane: (PKPane *) pane
{
  NSView *prefsView = [self view];
  PKPane *nextPane = nil;
  PKPane *requestedPane = nil;
  ASSIGN(requestedPane, pane);
  if (currentPane == pane) {
    return YES;
  }
    
  if (currentPane != nil)  /* Have a previous pane that needs unloading? */
  {
    /* Make sure last text field gets an "end editing" message: */
    if ([currentPane autoSaveTextFields])
      [[prefsView window] selectNextKeyView: self];
		
    if(requestedPane) /* User passed in a new pane to select? */
    {
      switch ([currentPane shouldUnselect]) /* Ask old one to unselect. */
      {
        case NSUnselectCancel:
          DESTROY(nextPane);
          return NO;
        case NSUnselectLater:
          ASSIGN(nextPane, requestedPane); /* Remember next pane for later. */
          return NO;
        case NSUnselectNow:
          DESTROY(nextPane);
          break;
      }
    }
    else 
    {
      NSLog(@"Weird, no current pane andn no requested pane");
      return NO;
    }
		
    /* Unload the old pane: */
    [currentPane willUnselect];
    [[currentPane mainView] removeFromSuperview];
    [currentPane didUnselect];
    DESTROY(currentPane);
  }
	
  /* Display "please wait" message in middle of content area: */
  if (mainViewWaitSign != nil)
  {
    NSRect box = [mainViewWaitSign frame];
    NSRect wBox = [prefsView frame];
    box.origin.x = (int)(abs(wBox.size.width -box.size.width) /2);
    box.origin.y = (int)(abs(wBox.size.height -box.size.height) /2);
    [mainViewWaitSign setFrameOrigin: box.origin];
    [prefsView addSubview: mainViewWaitSign];
    [prefsView setNeedsDisplay: YES];
    [prefsView display];
  }
	
  /* Get main view for next pane: */
  [requestedPane setOwner: self];
  NSView *paneView = [requestedPane mainView];
  // NOTE: By security, we check both frame origin and autoresizing.
  [paneView setFrameOrigin: NSMakePoint(0, 0)];
  [paneView setAutoresizingMask: NSViewNotSizable];
  [requestedPane willSelect];
    
  /* Remove "wait" sign: */
  if (mainViewWaitSign != nil)
    [mainViewWaitSign removeFromSuperview];
	
  /* Resize window so content area is large enough for prefs and show new pane: */
  [presentation layoutPreferencesViewWithPaneView: paneView];
	
  /* Finish up by setting up key views and remembering new current pane: */
  ASSIGN(currentPane, requestedPane);
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

/** <p>Switches to <em>preference pane</em> with the given 
    identifier.</p> 
    <p><strong>This method needs to be called in 
    -switchPaneView:.</strong></p> */
- (void) selectPaneWithIdentifier: (NSString *)identifier
{
  /* If the preference pane is already selected, we don't take in account the
     request, especially because it we reloads another instance of the pane 
     view on top of the current one. */
  if ([[self selectedPaneIdentifier] isEqualToString: identifier])
    return;

  PKPane *pane = [registry paneWithIdentifier: identifier];
    
  if ([presentation respondsToSelector: @selector(willSelectPaneWithIdentifier:)])
    [presentation willSelectPaneWithIdentifier: identifier];
    
  [self updateUIForPane: pane];
    
  if ([presentation respondsToSelector: @selector(didSelectPaneWithIdentifier:)])
    [presentation didSelectPaneWithIdentifier: identifier];
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

/** <p>Returns the view which encloses both preference pane loaded view and 
    presentation view where where every preferences panes are usually listed, it
    is often a window content view.</p> 
    <p>To take an example, for <code>PKToolbarPresentationMode</code>, the view 
    which contains both toolbar view and preference pane dedicated view is 
    returned.</p> */
- (NSView *) view 
{
  if (view == nil && [owner isKindOfClass: [NSWindow class]])
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
  return view;
}

/** <p>Returns the owner object for the current -view, it
    is usually the parent window in order to allow automatic 
    resizing and window title update when selected preference pane 
    changes.</p> 
    <p>However it is possible to specify an ancestor view when you 
    need to layout <em>preferences view</em> with other views in the 
    content view, but 
    this possibility involves to manage resizing yourself by overriding 
    -[PKPresentationBuilder layoutPreferencesViewWithPaneView:] method.</p> */
- (id) owner
{
  if (owner == nil) {
    /* owner cannot be nil. 
     * It must be initialized programmingly.
     * Call -awakeFromNib to initialize everything.
     */
    [self awakeFromNib];
  }
  return owner;
}

- (PKPaneRegistry *) registry
{
  return registry;
}

/** Returns identifier of the currently selected <em>preference pane</em>. */
- (NSString *) selectedPaneIdentifier
{
  NSArray *plugins = [registry loadedPlugins]; 
  NSDictionary *plugin = [plugins objectWithValue: currentPane forKey: @"instance"];
    
  return [plugin objectForKey: @"identifier"];
}

/** Returns the currently selected <em>preference pane</em>. */
- (PKPane *) selectedPane
{
  return currentPane;
}

/** <p>Returns the <em>wait view</em> displayed between each preference 
    pane switch until UI is fully set up. By default, it displays a circular 
    progress indicator.</p>
    <p><em>Overrides this method if you want to provide to customize such wait view.
    </em></p> */
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

/** <p>Returns the <em>presentation mode</em> which is used to identify
    the current presentation style.</p> */
- (const NSString *) presentationMode
{
  return [presentation presentationMode];
}

/** <p>Sets the <em>presentation</em> style used to display the 
    preferences pane list and identified by <var>presentationMode</var>.</p> */
- (void) setPresentationMode: (const NSString *) presentationMode
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
    ASSIGN(presentation, presentationToCheck);
    [presentation setPanesController: self];
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

/** <p>Switches the current preference pane viewed to another one provided by
    <var>sender</var>.</p> */
- (IBAction) switchPaneView: (id)sender
{
  // NOTE: It could be better to have a method like 
  // -preferencePaneIdentifierForSender: on presentation builder side than
  // propagating the action method.
  [presentation switchPaneView: sender];
}

@end
