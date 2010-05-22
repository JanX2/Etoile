/*
**  CWMIMEMultipart.m
**
**  Copyright (c) 2001-2004
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

#include <Pantomime/CWMIMEMultipart.h>

#include <Pantomime/CWConstants.h>

//
//
//
@implementation CWMIMEMultipart

- (id) init
{
  self = [super init];
  _parts = [[NSMutableArray alloc] init]; 
  return self;
}


//
//
//
- (void) dealloc
{
  RELEASE(_parts);
  [super dealloc];
}


//
//
//
- (void) addPart: (CWPart *) thePart 
{
  if (thePart)
    {
      [_parts addObject: thePart];
    }
}


//
//
//
- (void) removePart: (CWPart *) thePart
{
  if (thePart)
    {
      [_parts removeObject: thePart];
    }
}


//
//
//
- (NSUInteger) count
{
  return [_parts count];
}


//
//
//
- (CWPart *) partAtIndex: (unsigned int) theIndex
{
  return [_parts objectAtIndex: theIndex];
}

@end
