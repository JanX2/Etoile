/*
**  CWCacheManager.m
**
**  Copyright (c) 2004-2007
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
**  You should have received a copy of the GNU Lesser General Public
**  License along with this library; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#include <Pantomime/CWCacheManager.h>
#include <Pantomime/CWConstants.h>

#include <Foundation/NSArchiver.h>
#include <Foundation/NSException.h>

@implementation CWCacheManager

- (id) initWithPath: (NSString *) thePath
{
  if ((self = [super init]))
    {
      ASSIGN(_path, thePath);
    }
  
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_path);
  [super dealloc];
}

//
//
//
- (NSString *) path
{
  return _path;
}

- (void) setPath: (NSString *) thePath
{
  ASSIGN(_path, thePath);
}


//
//
//
- (void) invalidate
{
  //[_cache removeAllObjects];
}

//
//
//
- (BOOL) synchronize
{
  [self subclassResponsibility: _cmd];
  return NO;
}

//
//
//
- (NSUInteger) count
{
  return _count;
}

@end
