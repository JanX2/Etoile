/*
    NSArrayAdditions.m

    Implementation of the additions to the NSArray class for the
    ProjectManager application.

    Copyright (C) 2005  Saso Kiselkov

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import "NSArrayAdditions.h"

#import "NSSetAdditions.h"
#import "NSDictionaryAdditions.h"

@implementation NSArray (PMAdditions)

/**
 * Creates a mutable autoreleased copy of the receiver, but instead
 * of just making this top-level object mutable, it traverses through
 * all objects in the receiver and recursively replaces any occurence
 * of an array, dictionary or set with their mutable equivalents.
 *
 * @array A mutable copy of the receiver with any contained sets,
 *      dictionaries and arrays recursively replaced with their
 *      mutable equivalents.
 */
- makeDeeplyMutableEquivalent
{
  id (*ObjectAtIndex)(id, SEL, unsigned int);
  void (*AddObject)(id, SEL, id);
  NSMutableArray * mutableCopy;
  unsigned int i, n;
  Class arrayClass = [NSArray class],
        dictionaryClass = [NSDictionary class],
        setClass = [NSSet class];

  n = [self count];

  mutableCopy = [NSMutableArray arrayWithCapacity: n];
  ObjectAtIndex = (id (*)(id, SEL, unsigned int)) [self methodForSelector:
    @selector(objectAtIndex:)];
  AddObject = (void (*)(id, SEL, id)) [mutableCopy methodForSelector:
    @selector(addObject:)];

  for (i = 0; i < n; i++)
    {
      id object;

      object = ObjectAtIndex(self, @selector(objectAtIndex:), i);
      if ([object isKindOfClass: arrayClass] ||
          [object isKindOfClass: dictionaryClass] ||
          [object isKindOfClass: setClass])
        {
          AddObject(mutableCopy, @selector(addObject:), [object
            makeDeeplyMutableEquivalent]);
        }
      else
        {
          AddObject(mutableCopy, @selector(addObject:), object);
        }
    }

  return mutableCopy;
}

@end
