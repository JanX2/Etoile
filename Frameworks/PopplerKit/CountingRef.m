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

#import "CountingRef.h"

/**
 * Non-Public methods.
 */
@interface CountingRef(Private)
@end


@implementation CountingRef

- (id) initWithPtr: (void*)aPtr delegate: (id)aDelegate
{
   NSAssert(aDelegate, @"no delegate for reference");
   
   if ((self = [super init]))
   {
      ptr      = aPtr;
      delegate = [(id)aDelegate retain];
   }

   return self;
}

- (void) dealloc
{
   [(NSObject*)delegate freePtrForReference: self];
   ptr = NULL;
   [(id)delegate release];

   [super dealloc];
}

- (void*) ptr
{
   return ptr;
}

- (BOOL) isNULL
{
   return (ptr == NULL ? YES : NO);
}

@end
