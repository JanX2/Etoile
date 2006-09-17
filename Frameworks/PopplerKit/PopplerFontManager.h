/*
 * Copyright (C) 2003  Stefan Kleine Stegemann
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

/**
 * I know about application specific fonts. These include some default
 * fonts that are provided by the PopplerKit framework. In addition,
 * applications can register their own fonts. The fonts known by the
 * font manager complement the system wide fonts which are detected by
 * the poppler library automatically.
 */
@interface PopplerFontManager : NSObject
{
   NSMutableArray* fonts;
}

/**
 * You should use sharedManager to obtain a PopplerFontManager.
 */
- (id) init;

/** 
 * Get the shared PopplerFontManager instance. Returns nil if
 * initialization of this instance failed.
 */
+ (PopplerFontManager*) sharedManager;

/**
 * Get the list of font files.
 */
- (NSArray*) fonts;

/**
 * Add a font.
 */
- (void) addFontFile: (NSString*)aFont;

@end
