/*
	EXBasicFSAttributesExtracter.m

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
#import "EXVFS.h"
#import "EXContext.h"
#import "EXBasicFSAttributesExtracter.h"

static EXBasicFSAttributesExtracter *sharedExtracter;

@implementation EXBasicFSAttributesExtracter <EXExtracter>

/* Extract the basic FS attributes below from the file :
 * - name
 * - creation date
 * - modification date
 * - size
 * - inode
 * - Extension
 * To support later :
 * - permissions
 * - owner
 * - group
 */
 
// Basic methods

+ (EXBasicFSAttributesExtracter *) sharedInstance
{
    if (sharedExtracter == nil)
    {
        sharedExtracter = [EXBasicFSAttributesExtracter alloc];    
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
        _vfs = [EXVFS sharedInstance];
    }
  
  return self;
}

- (NSDictionary *) attributesForContext: (EXContext *)context
{
    NSURL *url = [context URL];
    NSString *lastPathComponent = [[url path] lastPathComponent];
    NSMutableDictionary *dict = [_vfs posixAttributesAtURL: url];
    
    [dict setObject: [lastPathComponent stringByDeletingPathExtension]
        forKey: EXAttributeName];
    [dict setObject: [lastPathComponent pathExtension] forKey: EXAttributeExtension];
    
    return dict;
}

- (id) attributeWithName: (NSString *)name forContext: (EXContext *)context
{
    NSURL *url = [context URL];
    
    if ([name isEqualToString: EXAttributeName])
    {
       return  [[[url path] lastPathComponent] stringByDeletingPathExtension];
    }
    else if ([name isEqualToString: EXAttributeExtension])
    {
        return [[[url path] lastPathComponent] pathExtension];
    }
    else
    {
        return [_vfs posixAttributeWithName: name atURL: url];
    }
}

// For the file size
// We extract just the size of the files, otherwise we return -100 when we have
// encountered a folder.
// When the initial complete indexing is terminated, we calculate the size of each folder
// by iterating over the size entries in the database.

@end
