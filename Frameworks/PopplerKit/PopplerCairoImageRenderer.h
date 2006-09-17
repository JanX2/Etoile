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
 * I can render the the contents of a PopplerPage to an image
 * buffer using the cairo library. I will only work if the
 * PopplerKit framework has been compiled with cairo support.
 * Otherwise, my render-methods will throw a PopplerException.
 * You can check at runtime whether this renderer is supported
 * by sending the isSupported message to me.
 *
 * My renderPage methods return autoreleased NSBitmapImageReps.
 */
@interface PopplerCairoImageRenderer : NSObject <PopplerBufferedRenderer>
{
   void* output_dev;
   PopplerDocument* document;
}

+ (BOOL) isSupported;

@end
