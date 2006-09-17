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
#import <PopplerKit/PopplerRenderer.h>

/**
 * I decorate some PopplerBufferedRenderer that produces NSImageReps
 * and draw these bitmaps directly to the screen.
 *
 * I use a very simple caching mechanism to improve performance. I remember
 * the last rendered image together with the page index, source box and the
 * scale factor. If you ask me subsequently to render the same page with the
 * same scale factor and the same source box I will use the cached image instead
 * of rendering it again.
 */
@interface PopplerDirectBufferedRenderer : NSObject <PopplerDirectRenderer>
{
   id<PopplerBufferedRenderer>  bufferedRenderer;
   NSImageRep*                  lastImage;
   unsigned                     lastPageIndex;
   float                        lastScale;
   NSRect                       lastSrcBox;
}

/** Initialize me with a document. I will use the best available buffered
    renderer for this document.  */
- (id) initWithDocument: (PopplerDocument*)aDocument;

/** Initialize me with a renderer.  */
- (id) initWithRenderer: (id<PopplerBufferedRenderer>)aRenderer;

@end
