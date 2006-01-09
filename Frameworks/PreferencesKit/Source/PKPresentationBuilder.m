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

#ifdef HAVE_UKTEST
#include <UnitKit/UnitKit.h>
#endif

#include "CocoaCompatibility.h"
#include "PrefsModule.h"
#include "PKPreferencesController.h"
#include "PKPrefPanesRegistry.h"
#include "PKPreferencePane.h"
#include "PKPresentationBuilder.h"

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
    if ([presentationMode isEqual: (NSString *)PKToolbarPresentationMode])
    {
        return [[[PKToolbarPresentation alloc] init] autorelease];
    }
    else if ([presentationMode isEqual: (NSString *)PKTablePresentationMode])
    {
        return [[[PKTableViewPresentation alloc] init] autorelease];
    }
    else if ([presentationMode isEqual: (NSString *)PKMatrixPresentationMode])
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
    
    [self resizePreferencesViewForView: [[pc selectedPreferencePane] mainView]];
}

/** <override-subclass />
    Uses this method to remove preferences window related UI elements, previously 
    set up in <ref>-loadUI</ref>. Usually called when presentation mode is going
    to change. */
- (void) unloadUI
{
#ifdef GNUSTEP
    [self subclassResponsability: _cmd];
#endif
}

/** <override-subclass />
    <p>Computes and assigns the correct size to <strong>preferences
    view</strong> where <var>view</var> parameter is going to displayed.</p>
    <p>Overrides this abstract method to resize preferences view container to
    match size of the preference pane view which is shown or should be.<p> */
- (void) resizePreferencesViewForView: (NSView *)view
{
    /* Presentation switches might modify pane view default position, so we reset
       it. */
    [view setFrameOrigin: NSZeroPoint];
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
#ifdef GNUSTEP
    [self subclassResponsability: _cmd];
#endif
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

/** <override-subclass> */
- (NSString *) presentationMode
{
    return (NSString *)PKNoPresentationMode;
}

@end
