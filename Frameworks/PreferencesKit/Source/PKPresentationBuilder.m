/*
	PKPresentationBuilder.m

	Abstract Preferences window controller class

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

#import "CocoaCompatibility.h"
#import "PrefsModule.h"
#import "PKPreferencesController.h"
#import "PKPrefPanesRegistry.h"
#import "PKPreferencePane.h"
#import "PKPresentationBuilder.h"

// HACK: Temporary solution to instantiate concrete presentation classes.
@class PKToolbarPresentation;
@class PKTableViewPresentation;
@class PKMatrixViewPresentation;

const NSString *PKNoPresentationMode = @"PKNoPresentationMode";
const NSString *PKToolbarPresentationMode = @"PKToolbarPresentationMode";
const NSString *PKTablePresentationMode = @"PKTablePresentationMode";
const NSString *PKMatrixPresentationMode = @"PKMatrixPresentationMode";
const NSString *PKOtherPresentationMode = @"PKOtherPresentationMode";


@implementation PKPresentationBuilder

+ (id) builderForPresentationMode: (NSString *)presentationMode
{
    if ([presentationMode isEqual: PKToolbarPresentationMode])
    {
        return [[[PKToolbarPresentation alloc] init] autorelease];
    }
    else if ([presentationMode isEqual: PKTablePresentationMode])
    {
        return [[[PKTableViewPresentation alloc] init] autorelease];
    }
    else if ([presentationMode isEqual: PKMatrixPresentationMode])
    {
        return [[[PKMatrixViewPresentation alloc] init] autorelease];
    }
    
    return nil;
}

/*
 * Preferences UI stuff (mostly abstract methods)
 */

/** <override-subclass />
    Uses this method to do preferences window related UI set up you may
    have to do and usually done in <ref>-awakeFromNib</ref>. */
- (void) loadUI
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    
    [self layoutPreferencesViewWithPaneView: [[pc selectedPreferencePane] mainView]];
    [self didSelectPreferencePaneWithIdentifier: [pc selectedPreferencePaneIdentifier]];
}

/** <override-subclass />
    Uses this method to remove preferences window related UI elements, previously 
    set up in <ref>-loadUI</ref>. Usually called when presentation mode is going
    to change. */
- (void) unloadUI
{
    [self subclassResponsability: _cmd];
}

/** <override-subclass />
    <p>Computes and assigns the right size to <strong>preferences view</strong> 
    (where <var>paneView</var> parameter is going to displayed), then the right 
    frame to both <strong>presentation view</strong> and <var>paneView</var>.
    Finally adds <var>paneView</paneView> as a subview of <strong>preferences 
    view</strong> (if it isn't already done).</p>
    <p>By default, this method just takes care to add the <var>paneVie</var>
    to <strong>preferences view</strong>.</p>
    <p>Overrides this abstract method to layout subviews of the preferences 
    view container (in a way specific to your presentation), it must take in 
    account the size of <strong>preference pane</strong> view which is shown or
    is going to be. If <var>paneView</var> can be directly added to 
    <strong>preferences view</strong>, just call this method with 
    <code>super</code>. That might not always be true, to take an example, 
    consider your presentation view is a <strong>tab view<strong>, it means 
    <var>paneView<var> has to be added this time to tab view itself and not 
    preferences view, otherwise it would be overlapped by the former.<p> */
- (void) layoutPreferencesViewWithPaneView: (NSView *)paneView
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    NSView *prefsView = [pc preferencesView];
    
    if ([[paneView superview] isEqual: prefsView] == NO)
        [prefsView addSubview: paneView];
    
    /* Presentation switches might modify pane view default position, so we reset
       it. */
    [paneView setFrameOrigin: NSZeroPoint];
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
    [self subclassResponsability: _cmd];
}

/*
 * Accessors
 */

/** <override-subclass />
<p>Returns the <strong>presentation view</strong> where every preference 
panes should be listed.</p>
<p>Overrides this abstract method to return your custom <strong>presentation 
view</strong> like toolbar, table view, popup menu, tab view etc.</p> */
- (NSView *) presentationView
{
    return nil;
}

/** <override-subclass>
    <p>Returns the <strong>presentation mode</strong> which is used to identify
    the presentation.</p>
    <p>By default, this methods returns <code>PKNoPresentationMode</code>.</p>
    <p>Overrides this abstract method to return the specific <strong>presentation 
    identifier</strong> related to your subclass.</p> */
- (NSString *) presentationMode
{
    return (NSString *)PKNoPresentationMode;
}

@end
