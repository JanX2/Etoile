/*
	PKPlainPresentation.m

	Preferences controller subclass with single preference pane

	Copyright (C) 2006 Yen-Ju Chen

	Author:  Yen-JU Chen <yjchenx gmail>
	Date:  November 2006

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
#import "PKPlainPresentation.h"
#import "GNUstep.h"

const NSString *PKPlainPresentationMode = @"PKPlainPresentationMode";

@implementation PKPlainPresentation

/* Dependency injection relying on -load method being sent to superclass before
   subclasses. It means we can be sure PKPresentationBuilder is already loaded
   by runtime, when each subclass receives this message. */
+ (void) load
{
  [super inject: self forKey: PKPlainPresentationMode];
}

/*
 * Overriden methods
 */

- (void) loadUI
{
  [super loadUI];
}

- (void) unloadUI
{
}

- (NSString *) presentationMode
{
    return (NSString *)PKPlainPresentationMode;
}

- (void) layoutPreferencesViewWithPaneView: (NSView *)paneView
{
  if (paneView == nil)
      return;

  NSView *mainView = [preferencesController preferencesView];
  NSRect paneViewFrame = [paneView frame];
  NSRect windowFrame = [[mainView window] frame];
    
  if ([[paneView superview] isEqual: mainView] == NO)
    [mainView addSubview: paneView];
   
  /* Presentation switches might modify pane view default position, so we reset
     it. */
  [paneView setFrameOrigin: NSZeroPoint];

  NSRect oldFrame = [[mainView window] frame];
//  windowFrame.size = [[mainView window] frameRectForContentRect: paneViewFrame].size;
  // FIXME: Implement -frameRectForContentRect: in GNUstep
  windowFrame.size = [NSWindow frameRectForContentRect: paneViewFrame
      styleMask: [[mainView window] styleMask]].size;

    
  // NOTE: We have to check carefully the view is not undersized to avoid
  // limiting switch possibilities in listed panes.
  if (windowFrame.size.height < 150)
    windowFrame.size.height = 150;
  if (windowFrame.size.width < 400)
    windowFrame.size.width = 400;
  
  /* We take in account the fact the origin is located at bottom left corner. */
  windowFrame.origin.y -= (windowFrame.size.height-oldFrame.size.height);
   
#ifdef GNUSTEP    
  [[mainView window] setFrame: windowFrame display: YES animate: NO];
#else
  [[mainView window] setFrame: windowFrame display: YES animate: YES];
#endif
}

@end

