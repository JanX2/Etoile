// Modified by Yen-Ju Chen
/*
	PKTableViewPresentation.m
 
	Preferences controller subclass with preference panes listed in a table bview
 
	Copyright (C) 2005 Quentin Mathe    
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2005
 
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
#import "CocoaCompatibility.h"
#import "PKPreferencesController.h"
#import "PKPrefPanesRegistry.h"
#import "PKMatrixViewPresentation.h"
#import "PKMatrixView.h"
#include "GNUstep.h"

extern const NSString *PKMatrixPresentationMode;


@implementation PKMatrixViewPresentation

/*
 * Overriden methods
 */

- (void) buttonAction: (id) sender
{
	[self switchPreferencePaneView: self];
}

- (void) loadUI
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    NSView *mainViewContainer = [pc preferencesView];
    NSArray *plugins = [[PKPrefPanesRegistry sharedRegistry] loadedPlugins];

    int count = [plugins count];
    NSRect rect = [mainViewContainer bounds];  
    
    matrixView = [[PKMatrixView alloc] initWithFrame: rect numberOfButtons: count];
    [matrixView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
    [matrixView setAutoresizesSubviews: YES];
    [matrixView setTarget: self];
    [matrixView setAction: @selector(buttonAction:)];
    [mainViewContainer addSubview: matrixView];
    [mainViewContainer setAutoresizesSubviews: YES];

    ASSIGN(identifiers, [plugins valueForKey: @"identifier"]);
    NSEnumerator *e = [identifiers objectEnumerator];
    id identifier;
    int tag = 0;
    while ((identifier = [e nextObject]))
    {
      NSDictionary *plugin = [plugins objectWithValue: identifier forKey: @"identifier"];
      NSButtonCell *button = [[NSButtonCell alloc] init];
      [button setTitle: [plugin objectForKey: @"name"]];
      NSImage *image = [plugin objectForKey: @"image"];
      [image setSize: NSMakeSize(48, 48)];
      [button setImage: image];
      [button setImagePosition: NSImageAbove];
      [button setBordered: NO];
      [button setTag: tag++];
      [button setTarget: self];
      [button setAction: @selector(buttonAction:)];
      [matrixView addButtonCell: button];
      [button release];
    }
    
    [super loadUI];
}

- (void) unloadUI
{
    [matrixView removeFromSuperview];
}

- (NSString *) presentationMode
{
    return (NSString *)PKMatrixPresentationMode;
}

- (NSView *) presentationView
{
    return [matrixView contentView];
}

// FIXME: Actual code in this method have to be improved to work when
// preferencesView is not equal to contentView and we should move some portions
// common with other presentation classes in PKPresentationBuilder superclass.
- (void) layoutPreferencesViewWithPaneView: (NSView *)paneView
{
    if (paneView == nil) return;
    
    [super layoutPreferencesViewWithPaneView: paneView];
    
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    NSSize size = [matrixView frameSizeForContentSize: [paneView frame].size];
    NSRect rect = NSMakeRect(0, 0, size.width, size.height);
    [matrixView setFrame: rect];

    NSRect windowFrame = [[matrixView window] frame];
    int oldHeight = windowFrame.size.height;
    
    // FIXME: Implement -frameRectForContentRect: in GNUstep 
    windowFrame.size = [NSWindow frameRectForContentRect: [matrixView frame]
        styleMask: [[matrixView window] styleMask]].size;
    
#if 0 // Not sure we want to do that 
    // NOTE: We have to check carefully the view is not undersized to avoid
    // limiting switch possibilities in listed panes.
    if (windowFrame.size.height < 150)
        windowFrame.size.height = 150;
    if (windowFrame.size.width < 400)
        windowFrame.size.width = 400;
#endif
    
    /* We take in account the fact the origin is located at bottom left corner. */
    int delta = oldHeight - windowFrame.size.height;
    windowFrame.origin.y += delta;
    
    [[matrixView window] setFrame: windowFrame display: YES];
}

- (IBAction) switchPreferencePaneView: (id)sender
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    int tag = [[matrixView selectedButtonCell] tag];
    [pc selectPreferencePaneWithIdentifier: [identifiers objectAtIndex: tag]];
}

@end
