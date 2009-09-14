/*
**  CWFolderInformation.m
**
**  Copyright (c) 2002-2004
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

#include <Pantomime/CWFolderInformation.h>

//
//
//
@implementation CWFolderInformation

- (id) init
{
  self = [super init];

  _nb_of_messages = _nb_of_unread_messages = _size = 0;

  return self;
}


//
//
//
- (unsigned int) nbOfMessages
{
  return _nb_of_messages;
}


//
//
//
- (void) setNbOfMessages: (unsigned int) theValue
{
  _nb_of_messages = theValue;
}


//
//
//
- (unsigned int) nbOfUnreadMessages
{
  return _nb_of_unread_messages;
}


//
//
//
- (void) setNbOfUnreadMessages: (unsigned int) theValue
{
  _nb_of_unread_messages = theValue;
}


//
//
//
- (unsigned int) size
{
  return _size;
}


//
//
//
- (void) setSize: (unsigned int) theSize
{
  _size = theSize;
}

@end
