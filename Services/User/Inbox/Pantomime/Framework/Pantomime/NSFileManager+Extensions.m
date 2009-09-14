/*
**  NSFileManager+Extensions.m
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

#include <Pantomime/NSFileManager+Extensions.h>

#include <Foundation/NSValue.h>

//
//
//
@implementation NSFileManager (PantomimeFileManagerExtensions)

- (void) enforceMode: (unsigned long) theMode
	      atPath: (NSString *) thePath

{
  NSMutableDictionary *currentFileAttributes;
  
  unsigned long current_attributes, desired_attributes;
  
  
  currentFileAttributes = [[NSMutableDictionary alloc] initWithDictionary: [self fileAttributesAtPath: thePath
										 traverseLink: YES]];
  
  current_attributes = [currentFileAttributes filePosixPermissions];
  desired_attributes = theMode;
  
  if (current_attributes != desired_attributes)
    {
      [currentFileAttributes setObject: [NSNumber numberWithUnsignedLong: desired_attributes]
			     forKey: NSFilePosixPermissions];
      
      [self changeFileAttributes: currentFileAttributes  atPath: thePath];
    }
  
  [currentFileAttributes release];
}

@end
