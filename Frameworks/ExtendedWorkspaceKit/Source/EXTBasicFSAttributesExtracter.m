/*
	EXTBasicFSAttributesExtracter.m

	FS related attributes class to extract them out of contexts

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>

	Author:   Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2004

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "EXTVFS.h"
#import "ExtendedWorkspaceConfig.h"
#import "EXTContext.h"
#import "EXTBasicFSAttributesExtracter.h"

static EXTBasicFSAttributesExtracter *sharedExtracter;

@implementation EXTBasicFSAttributesExtracter 
// Does not implement EXTExtracter protocol, use a custom interface

/* Extract the basic FS attributes below from the file :
 * - name
 * - creation date
 * - modification date
 * - size
 * - inode
 * - extension
 * To support later :
 * - permissions
 * - owner
 * - group
 */
 
// Basic methods

+ (EXTBasicFSAttributesExtracter *) sharedInstance
{
  if (sharedExtracter == nil)
    {
      sharedExtracter = [EXTBasicFSAttributesExtracter alloc];    
      [sharedExtracter init];
    }
    
  return sharedExtracter;      
}

- (id) init
{
  if (sharedExtracter != self)
    {
      RELEASE(self);
      return RETAIN(sharedExtracter);
    }
  
  if ((self = [super init])  != nil)
    {
      // Nothing to do
    }
  
  return self;
}

- (void) setActiveContext: (EXTContext *) context
{
  ASSIGN(_context, context);
}

// The methods below can return null value or -1 especially when the context is 
// not an entity context
- (EXTContext *) activeContext
{
  return _context;
}

- (NSDate *) creationDate
{
  return nil; // call gnome-vfs
}

- (NSString *) extension
{
  return nil;
}

- (int) inode
{
  return -1; // call gnome-vfs
}

- (NSDate *) modificationDate
{
  return nil; // call gnome-vfs
}

- (NSString *) name
{
  return [[[_context URL] path] lastPathComponent]; 
  // May be we can do something better here
}

- (int) size
{
  return -1; // call gnome-vfs
}

@end
