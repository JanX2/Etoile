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
#import <PopplerKit/PopplerPage.h>
#import <PopplerKit/PopplerDocument.h>


/**
 * I can render the contents of a PopplerPage directly to
 * the screen.
 */
@protocol PopplerDirectRenderer

- (id) initWithDocument: (PopplerDocument*)aDocument;

- (void) drawPage: (PopplerPage*)aPage
           srcBox: (NSRect)aBox
          atPoint: (NSPoint)aPoint
            scale: (float)aScale;
            
- (void) drawPage: (PopplerPage*)aPage
          atPoint: (NSPoint)aPoint
            scale: (float)aScale;
          
@end


/**
 * I render the contents of a PopplerPage to some buffer. The
 * concrete type of this buffer depends on my implementation.
 */
@protocol PopplerBufferedRenderer

- (id) initWithDocument: (PopplerDocument*)aDocument;

- (id) renderPage: (PopplerPage*)aPage
           srcBox: (NSRect)aBox
            scale: (float)aScale;
            
- (id) renderPage: (PopplerPage*)aPage
            scale: (float)aScale;
            
@end
