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

extern NSString* kPageCacheSizePref;
extern NSString* kUseCairoPref;
extern NSString* kMarkPageBoundaries;

/**
 * Vindaloo Preferences.
 */
@interface Preferences : NSObject
{
   long pageCacheSize;
   BOOL useCairo;
   BOOL markPageBoundaries;
}

+ (Preferences*) sharedPrefs;

- (unsigned long) pageCacheSize;
- (void) setPageCacheSize: (unsigned long)aSize;

- (BOOL) useCairo;
- (void) setUseCairo: (BOOL)aFlag;

- (BOOL) markPageBoundaries;
- (void) setMarkPageBoundaries: (BOOL)aFlag;

@end
