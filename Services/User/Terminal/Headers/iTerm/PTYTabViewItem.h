/*
 **  PTYTabViewItem.h
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Ujwal S. Setlur
 **
 **  Project: iTerm
 **
 **  Description: NSTabViewItem subclass. Implements attributes for label.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PTYTabViewItem : NSTabViewItem {

    NSDictionary *labelAttributes;
    BOOL dragTarget;
    BOOL bell;
    NSImage *warningImage;

}

- (id) initWithIdentifier: (id) anIdentifier;
- (void) dealloc;

// Override this to be able to customize the label attributes
- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)tabRect;
- (NSSize) sizeOfLabel: (BOOL) shouldTruncateLabel;

// set/get custom label
- (NSDictionary *) labelAttributes;
- (void) setLabelAttributes: (NSDictionary *) theLabelAttributes;
- (void) setBell:(BOOL)b;

// drag-n-drop utilities
- (void) becomeDragTarget;
- (void) resignDragTarget;

@end
