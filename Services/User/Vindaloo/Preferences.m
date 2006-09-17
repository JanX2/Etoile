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

#import "Preferences.h"
#import <PopplerKit/PopplerCachingRenderer.h>

// Preferences constants
NSString* kPageCacheSizePref  = @"PageCacheSize";
NSString* kUseCairoPref       = @"UseCairo";
NSString* kMarkPageBoundaries = @"MarkPageBoundaries";

// shared instance
static Preferences* sharedPrefs = nil;

/**
 * Non-Public methods.
 */
@interface Preferences (Private)
@end


@implementation Preferences

+ (void) initialize
{
   static BOOL done = NO;
   if (!done)
   {
      NSMutableDictionary* stdDefs = [NSMutableDictionary dictionary];
      
      unsigned long defaultCacheSize = [PopplerCachingRenderer defaultCacheSize];
      [stdDefs setObject: [NSNumber numberWithUnsignedLong: defaultCacheSize]
                  forKey: kPageCacheSizePref];

      [stdDefs setObject: [NSNumber numberWithBool: NO] forKey: kUseCairoPref];
      [stdDefs setObject: [NSNumber numberWithBool: YES] forKey: kMarkPageBoundaries];

      [[NSUserDefaults standardUserDefaults] registerDefaults: stdDefs];
      done = YES;
   }
}

- (id) init
{
   self = [super init];
   if (self)
   {
      NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
      pageCacheSize = [[defs objectForKey: kPageCacheSizePref] unsignedLongValue];
      useCairo = [[defs objectForKey: kUseCairoPref] boolValue];
      markPageBoundaries = [[defs objectForKey: kMarkPageBoundaries] boolValue];
   }
   return self;
}

+ (Preferences*) sharedPrefs
{
   if (!sharedPrefs)
   {
      sharedPrefs = [[Preferences alloc] init];
   }
   return sharedPrefs;
}

- (unsigned long) pageCacheSize
{
   return pageCacheSize;
}

- (void) setPageCacheSize: (unsigned long)aSize
{
   pageCacheSize = aSize;
}

- (BOOL) useCairo
{
   return useCairo;
}

- (void) setUseCairo: (BOOL)aFlag
{
   useCairo = aFlag;
}

- (BOOL) markPageBoundaries
{
   return markPageBoundaries;
}

- (void) setMarkPageBoundaries: (BOOL)aFlag
{
   markPageBoundaries = aFlag;
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation Preferences (Private)
@end
