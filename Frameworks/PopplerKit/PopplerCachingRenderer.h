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
 * I decorate some PopplerBufferedRenderer and cache the
 * results. I'm using a cache with a maximum size. If the
 * sum of the sizes of the objects in the cache is greater
 * than the maximum size, objects are removed from cache using
 * a LRU strategy.
 *
 * The default size for the cache is 10 megs.
 */
@interface PopplerCachingRenderer : NSObject <PopplerBufferedRenderer>
{
   id<PopplerBufferedRenderer> renderer;
   id                          cache;
}

/** Initialize me with a document as specified by the PopplerBufferedRenderer.
    I will use the best available renderer for this document.  */
- (id) initWithDocument: (PopplerDocument*)aDocument;
    
/** Initialize me with an existing renderer.  */
- (id) initWithRenderer: (id<PopplerBufferedRenderer>)aRenderer;

/** Set the cache size for this renderer. Use 0 to disable caching.  */
- (void) setCacheSize: (unsigned long)aSize;

/** Get the default cache size.  */
+ (unsigned long) defaultCacheSize;

@end
