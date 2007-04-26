/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PDFContentView.h"

@class Controller;

/**
 * A view that provides standard tools for a PDF document.
 * These tools include things like page navigation controls,
 * zoom controls etc.
 */
@interface DocumentTools : NSObject
{
	Controller *controller;
	id target;
}

/** The frame size of the view is calculated automatically during
    initialization. Thus, the frame's size may be modified to hold
    all tool views. The frame may be heightened but it is never 
    belittled. You can safely use 0, 0 for the frame's size and rely
    on the initialization to determine and set the minimum required
    width.  */
- (id) initWithWindowController: (Controller *)controller target: (id)aTarget;

/** A DocumentTools view will send all actions of it's embeded
    controls to a target object.  */
- (void) setTarget: (id)aTarget;

/** Set the page number to be displayed in the page field.  */
- (void) setPage: (int)aPage;

/** Set the number of pages in the displayed document.  */
- (void) setPageCount: (int)aPageCount;

/** Set the content's for the zoom textfield.  */
- (void) setZoom: (float)aFactor;

/** Set the actual page resize policy. The state of the buttons which
    control the policy is modified accordingly.  */
- (void) setResizePolicy: (ResizePolicy)aPolicy;

/** Transfer focus to page field.  */
- (void) focusPageField;

@end
