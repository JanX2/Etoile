/*
    NSDictionaryAdditions.m

    Implementations of the additions to the NSDictionary class for the
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

#import "NSDictionaryAdditions.h"

#import "NSSetAdditions.h"
#import "NSArrayAdditions.h"

@implementation NSDictionary (PMAdditions)

/**
 * Same as -[NSArray makeDeeplyMutableEquivalent].
 *
 * @see [NSArray makeDeeplyMutableEquivalent]
 */
- makeDeeplyMutableEquivalent
{
  id (*ObjectForKey)(id, SEL, id);
  id (*ObjectAtIndex)(id, SEL, unsigned int);
  void (*SetObjectForKey)(id, SEL, id, id);
  NSMutableDictionary * mutableCopy;
  unsigned int i, n;
  NSArray * allKeys;
  Class arrayClass = [NSArray class],
        dictionaryClass = [NSDictionary class],
        setClass = [NSSet class];

  allKeys = [self allKeys];

  n = [self count];
  mutableCopy = [NSMutableDictionary dictionaryWithCapacity: n];

  ObjectForKey = (id (*)(id, SEL, id)) [self methodForSelector:
    @selector(objectForKey:)];
  ObjectAtIndex = (id (*)(id, SEL, unsigned int)) [allKeys methodForSelector:
    @selector(objectAtIndex:)];
  SetObjectForKey = (void (*)(id, SEL, id, id)) [mutableCopy methodForSelector:
    @selector(setObject:forKey:)];

  for (i = 0; i < n; i++)
    {
      id key, object;

      key = ObjectAtIndex(allKeys, @selector(objectAtIndex:), i);
      object = ObjectForKey(self, @selector(objectForKey:), key);
      if ([object isKindOfClass: arrayClass] ||
          [object isKindOfClass: dictionaryClass] ||
          [object isKindOfClass: setClass])
        {
          SetObjectForKey(mutableCopy, @selector(setObjectForKey:),
            [object makeDeeplyMutableEquivalent], key);
        }
      else
        {
          SetObjectForKey(mutableCopy, @selector(setObjectForKey:),
            object, key);
        }
    }

  return mutableCopy;
}

@end
