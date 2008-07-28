/*
    NSSetAdditions.m

    Implementations of the additions to the NSSet class for the
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

#import <Foundation/NSEnumerator.h>
#import "NSSetAdditions.h"

#import "NSDictionaryAdditions.h"
#import "NSArrayAdditions.h"

@implementation NSSet (PMAdditions)

/**
 * Same as -[NSArray makeDeeplyMutableEquivalent].
 *
 * @see [NSArray makeDeeplyMutableEquivalent]
 */
- makeDeeplyMutableEquivalent
{
  NSMutableSet * mutableCopy;
  NSEnumerator * e;
  id object;
  Class arrayClass = [NSArray class],
        dictionaryClass = [NSDictionary class],
        setClass = [NSSet class];

  mutableCopy = [NSMutableSet setWithCapacity: [self count]];
  e = [self objectEnumerator];
  while ((object = [e nextObject]) != nil)
    {
      if ([object isKindOfClass: arrayClass] ||
          [object isKindOfClass: dictionaryClass] ||
          [object isKindOfClass: setClass])
        {
          [mutableCopy addObject: [object makeDeeplyMutableEquivalent]];
        }
      else
        {
          [mutableCopy addObject: object];
        }
    }

  return mutableCopy;
}

@end
