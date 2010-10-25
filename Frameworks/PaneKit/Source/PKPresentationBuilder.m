/** <title>PKPresentationBuilder</title>

	PKPresentationBuilder.m

	<abstract>Abstract Presentation class that returns concrete presentation 
    objects (used by PKPreferencesController as layout delegates).</abstract>

	Copyright (C) 2005 Quentin Mathe
                       Uli Kusterer

	Author:  Quentin Mathe <qmathe@club-internet.fr>
             Uli Kusterer
    Date:  November 2005

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

#import <PaneKit/CocoaCompatibility.h>
#import <PaneKit/PKPanesController.h>
#import <PaneKit/PKPaneRegistry.h>
#import <PaneKit/PKPane.h>
#import <PaneKit/PKPresentationBuilder.h>
#import "GNUstep.h"

NSString *PKNoPresentationMode = @"PKNoPresentationMode";
NSString *PKOtherPresentationMode = @"PKOtherPresentationMode";

static NSMutableDictionary *injectedObjects = nil;

/** PKPresentationBuilder Description */
@implementation PKPresentationBuilder

+ (void) load
{
  injectedObjects = [[NSMutableDictionary alloc] initWithCapacity: 10];
}

/** <p>Dependency injection relying on +load method being sent to superclass    
    before subclasses. It means we can be sure [PKPresentationBuilder] is 
    already loaded by runtime, when each subclass receives this message.</p> */
+ (BOOL) inject: (id)obj forKey: (id)key
{
  [injectedObjects setObject: obj forKey: key];
  return YES;
}

/** <p>Factory method that returns the right presentation instance when 
    possible.</p>
    <p>It returns nil when no presentation subclass registered against 
    <var>presentationMode</var> could be found.</p> */
+ (id) builderForPresentationMode: (const NSString *)presentationMode
{
  id presentationUnit = [injectedObjects objectForKey: presentationMode];
    
  // NOTE: [myClass class] == myClass (and [myObject class] == myClass)
  if ([presentationUnit isEqual: [presentationUnit class]]) {
    presentationUnit = AUTORELEASE([[presentationUnit alloc] init]);
  }
      
  return presentationUnit;
}

- (id) init
{
  self = [super init];
 
  return self;
}

- (void) dealloc
{
  DESTROY(controller);
  DESTROY(allLoadedPlugins);
  [super dealloc];
}

/*
 * Preferences UI stuff (mostly abstract methods)
 */

- (void) setPanesController: (PKPanesController *) c
{
  /* Cache these two objects for subclass */
  ASSIGN(controller, c);
  ASSIGN(allLoadedPlugins, [[controller registry] loadedPlugins]);
}

/** <override-subclass />
    <p>Uses this method to do preferences window related UI set up you may
    have to do and usually done in -awakeFromNib.</p> */
- (void) loadUI
{
  [self layoutPreferencesViewWithPaneView: [[controller selectedPane] mainView]];
  [self didSelectPaneWithIdentifier: [controller selectedPaneIdentifier]];
}

/** <override-subclass />
    <p>Uses this method to remove preferences window related UI elements, 
    previously set up in -loadUI. Usually called when presentation mode is going
    to change.</p> */
- (void) unloadUI
{
//  [self subclassResponsibility: _cmd];
}

- (void) willSelectPaneWithIdentifier: (NSString *) identifier;
{
//  [self subclassResponsibility: _cmd];
}

- (void) didSelectPaneWithIdentifier: (NSString *)identifier
{
//  [self subclassResponsibility: _cmd];
}


/** <override-subclass />
    <p>Computes and assigns the right size to <em>preferences view</em> 
    (where <var>paneView</var> parameter is going to displayed), then the right 
    frame to both <em>presentation view</em> and <var>paneView</var>.
    Finally adds <var>paneView</var> as a subview of <em>preferences 
    view</em> (if it isn't already done).</p>
    <p>By default, this method just takes care to add the <var>paneView</var>
    to <em>preferences view</em>.</p>
    <p><strong>Overrides this abstract method to layout subviews of the preferences 
    view container (in a way specific to your presentation)</strong>, it must take in 
    account the size of <em>preference pane</em> view which is shown or
    is going to be. If <var>paneView</var> can be directly added to 
    <em>preferences view</em>, just call this method with 
    <code>super</code>. That might not always be true, to take an example, 
    consider your presentation view is a <em>tab view</em>, it means 
    <var>paneView</var> has to be added this time to tab view itself and not 
    preferences view, otherwise it would be overlapped by the former.</p> */
- (void) layoutPreferencesViewWithPaneView: (NSView *)paneView
{
  NSView *prefsView = [controller view];
    
  /* We give up here when no paneView is provided and let our subclasses 
     finishing their custom layout. */
  if (paneView == nil)
      return;
    
  if ([[paneView superview] isEqual: prefsView] == NO)
    [prefsView addSubview: paneView];
    
  /* Presentation switches might modify pane view default position, so we reset
     it. */
  [paneView setFrameOrigin: NSZeroPoint];
}

/*
 * Action methods
 */

/** <override-subclass />
    <p>Switches the current preference pane viewed to another one provided by
    <var>sender</var>.</p>
    <p><strong>Overrides this abstract method in your subclass in order to 
    implement this behavior by calling 
    [PKPreferencesController -selectPaneWithIdentifier:]; you have to 
    be able to retrieve the preference pane through your custom
    <var>sender</var>.</strong></p> */
- (void) switchPaneView: (id)sender
{
//  [self subclassResponsibility: _cmd];
}

/*
 * Accessors
 */

/** <override-subclass />
    <p>Returns the <em>presentation mode</em> which is used to identify
    the presentation.</p>
    <p>By default, this methods returns <code>PKNoPresentationMode</code>.</p>
    <p><strong>Overrides this abstract method to return the specific 
    <em>presentation identifier</em> related to your subclass.</strong></p> */
- (NSString *) presentationMode
{
  return (NSString *)PKNoPresentationMode;
}

@end
