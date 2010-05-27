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

#import "PopplerCachingRenderer.h"
#import "PopplerDocument+Rendering.h"
#import "MKLRUCache.h"

#include <math.h>

// default cache size
const unsigned long kDefaultCacheSize = 10485760;

// Helps to build hashcodes. The first number has to
// be an odd prime number.
#define FIRST_TERM(x) 37 * x

/**
 * A key for putting render results in dictionaries.
 */
@interface CacheKey : NSObject
{
   int    pageNum;
   NSRect srcBox;
   float  scale;
}

- (id) initWithPageNum: (unsigned)aPageNum
                srcBox: (NSRect)aBox
                 scale: (float)aScale;
                 
+ (id) keyWithPageNum: (unsigned)aPageNum
               srcBox: (NSRect)aBox
                scale: (float)aScale;

@end


/**
 * Non-Public methods.
 */
@interface PopplerCachingRenderer (Private)
@end


@implementation PopplerCachingRenderer

- (id) initWithDocument: (PopplerDocument*)aDocument
{
   return [self initWithRenderer: [aDocument bufferedRenderer]];
}

- (id) initWithRenderer: (id<PopplerBufferedRenderer>)aRenderer
{
   NSAssert(aRenderer, @"nil renderer");
   
   self = [super init];
   if (self)
   {
      renderer = [(NSObject*)aRenderer retain];
      cache = [[MKLRUCache alloc] initWithMaxSize: [PopplerCachingRenderer defaultCacheSize]];
   }
   return self;
}

- (void) dealloc
{
   [(NSObject*)cache release];
   [(NSObject*)renderer release];
   [super dealloc];
}

+ (unsigned long) defaultCacheSize
{
   return kDefaultCacheSize;
}

- (void) setCacheSize: (unsigned long)aSize
{
   [cache setMaximumSize: aSize];
}

- (id) renderPage: (PopplerPage*)aPage
           srcBox: (NSRect)aBox
            scale: (float)aScale
{
   CacheKey* key = [CacheKey keyWithPageNum: [aPage index]
                                     srcBox: aBox
                                      scale: aScale];

   id cachedResult = [cache objectForKey: key];
   if (!cachedResult)
   {
      cachedResult =  [renderer renderPage: aPage
                                    srcBox: aBox
                                     scale: aScale];
      NS_DURING
         [cache putObject: cachedResult forKey: key];
      NS_HANDLER
         NSLog(@"failed to cache rendered page for key %@: %@",
               [key description], [localException reason]);
      NS_ENDHANDLER
   }

   return cachedResult;
}
            
- (id) renderPage: (PopplerPage*)aPage
            scale: (float)aScale
{
   return [self renderPage: aPage
                    srcBox: NSMakeRect(-1, -1, -1, -1)
                     scale: aScale];
}


@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation PopplerCachingRenderer (Private)
@end


/* ----------------------------------------------------- */
/*  Class CacheKey                                       */
/* ----------------------------------------------------- */

@implementation CacheKey

- (id) initWithPageNum: (unsigned)aPageNum
                srcBox: (NSRect)aBox
                 scale: (float)aScale
{
   self = [super init];
   if (self)
   {
      srcBox = aBox;
      scale = aScale;
      pageNum = aPageNum;
   }
   return self;
}

                 
+ (id) keyWithPageNum: (unsigned)aPageNum
               srcBox: (NSRect)aBox
                scale: (float)aScale
{
   return [[[CacheKey alloc] initWithPageNum: aPageNum
                                      srcBox: aBox
                                       scale: aScale] autorelease];
}

- (NSUInteger) hash
{
   unsigned result = 23; // SEED
   result = FIRST_TERM(result) + pageNum;

   // convert the scale factor to int, using 4 decimal
   // precision. This should be sufficient since 0.75411
   // and 0.75412 doesn't really make a difference to the
   // human sitting in front of the screen
   result = FIRST_TERM(result) + (int)(scale * 10000);

   // we also use a 4 decimal precision for the rectangle
   result = FIRST_TERM(result) + (int)(NSMinX(srcBox) * 10000);
   result = FIRST_TERM(result) + (int)(NSMinY(srcBox) * 10000);
   result = FIRST_TERM(result) + (int)(NSWidth(srcBox) * 10000);
   result = FIRST_TERM(result) + (int)(NSHeight(srcBox) * 10000);
   
   return result;
}

- (BOOL) isEqual: (id)anObject
{
   if ((!anObject) || (![anObject isKindOfClass: [CacheKey class]]))
   {
      return NO;
   }
   
   return ([self hash] == [anObject hash]);
}

- (id) copyWithZone: (NSZone*)zone
{
   return [self retain];
}

- (NSString*) description
{
   return [NSString stringWithFormat:
             @"{page=%d, scale=%f, srcBox=(%f, %f, %f, %f)}",
             pageNum, scale, NSMinX(srcBox), NSMinY(srcBox),
             NSWidth(srcBox), NSHeight(srcBox)];
}

@end
