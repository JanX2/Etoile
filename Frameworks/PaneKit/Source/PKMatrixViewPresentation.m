/*
	PKMatrixViewPresentation.m
 
	Preferences controller subclass with preference panes listed in a matrix
 
	Copyright (C) 2005 Yen-Ju Chen, Quentin Mathe 
 
	Author:  Yen-Ju Chen
             Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2005
 
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
#import <PaneKit/PKPanesController.h>
#import <PaneKit/PKMatrixViewPresentation.h>
#import "PKMatrixView.h"
#import "GNUstep.h"

const NSString *PKMatrixPresentationMode = @"PKMatrixPresentationMode";


@implementation PKMatrixViewPresentation

/* Dependency injection relying on -load method being sent to superclass before
   subclasses. It means we can be sure PKPresentationBuilder is already loaded
   by runtime, when each subclass receives this message. */
+ (void) load
{
  [PKPresentationBuilder inject: self forKey: PKMatrixPresentationMode];
}

/*
 * Overriden methods
 */

- (void) buttonAction: (id) sender
{
  [self switchPaneView: self];
}

- (void) loadUI
{
  NSView *mainViewContainer = [controller view];

  int count = [allLoadedPlugins count];
  NSRect rect = [mainViewContainer bounds];  
    
  matrixView = [[PKMatrixView alloc] initWithFrame: rect 
                                   numberOfButtons: count];
  [matrixView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [matrixView setAutoresizesSubviews: YES];
#ifndef GNUSTEP // Doesn't work on GNUstep.
  [matrixView setTarget: self];
  [matrixView setAction: @selector(buttonAction:)];
#endif
    
  [mainViewContainer addSubview: matrixView];
  [mainViewContainer setAutoresizesSubviews: YES];

  ASSIGN(identifiers, [allLoadedPlugins valueForKey: @"identifier"]);
    
  NSEnumerator *e = [identifiers objectEnumerator];
  id identifier;
  int tag = 0;
    
  while ((identifier = [e nextObject]))
  {
    NSDictionary *plugin = [allLoadedPlugins objectWithValue: identifier 
                                             forKey: @"identifier"];
    NSButtonCell *button = [[NSButtonCell alloc] init];
        
    [button setTitle: [plugin objectForKey: @"name"]];
        
    NSImage *image = [plugin objectForKey: @"image"];
    if ((image) && [image isKindOfClass: [NSImage class]]) {
      [image setSize: NSMakeSize(48, 48)];
      [button setImage: image];
    }

    [button setImagePosition: NSImageAbove];
    [button setBordered: NO];
    [button setTag: tag++];
    [button setTarget: self];
    [button setAction: @selector(buttonAction:)];
        
    [matrixView addButtonCell: button];
    DESTROY(button);
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

// FIXME: Actual code in this method have to be improved to work when
// preferencesView is not equal to contentView and we should move some portions
// common with other presentation classes in PKPresentationBuilder superclass.
- (void) layoutPreferencesViewWithPaneView: (NSView *)paneView
{
  if (paneView == nil) 
    return;
   
  NSView *prefsView = [controller view];
   
  NSSize size = [matrixView frameSizeForContentSize: [paneView frame].size];
  NSRect rect = NSMakeRect(0, 0, size.width, size.height);
    
  NSRect windowFrame = [[matrixView window] frame];
  int oldHeight = windowFrame.size.height;
    
  // FIXME: Implement -frameRectForContentRect: in GNUstep 
  windowFrame.size = [NSWindow frameRectForContentRect: rect 
      styleMask: [[matrixView window] styleMask]].size;
    
#if 1 // Not sure we want to do that 
    // NOTE: We have to check carefully the view is not undersized to avoid
    // limiting switch possibilities in listed panes.
    if (windowFrame.size.height < 100)
        windowFrame.size.height = 100;
    if (windowFrame.size.width < 100)
        windowFrame.size.width = 100;
#endif
   
  /* We take in account the fact the origin is located at bottom left corner. */
  int delta = oldHeight - windowFrame.size.height;
  windowFrame.origin.y += delta;
    
  #ifndef GNUSTEP
    [[matrixView window] setFrame: windowFrame display: YES animate: YES];
  #else 
    [[matrixView window] setFrame: windowFrame display: YES animate: NO];
  #endif

  [matrixView setFrame: rect];
  [paneView setFrameOrigin: NSZeroPoint];
  if ([[paneView superview] isEqual: [matrixView contentView]] == NO)
    [[matrixView contentView] addSubview: paneView];
}

- (void) switchPaneView: (id) sender
{
  int tag = [[matrixView selectedButtonCell] tag];
    
  [controller selectPaneWithIdentifier: [identifiers objectAtIndex: tag]];
}

@end
