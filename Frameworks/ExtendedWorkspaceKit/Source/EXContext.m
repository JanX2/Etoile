/*
	EXContext.m

	Context which implements support to interact with files and entities

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
#import "EXAttributesCore.h"
#import "EXVFS.h"
#import "EXContext.h"

// Needed until we have created the equivalent classes
@class EXKeywordsAttribute;
@class EXPresentationAttribute;
@class EXPreviewAttribute;
@class EXTypeAttribute;

static EXVFS *vfs = nil;

NSString *EXAttributeCreationDate = @"EXAttributeCreationDate";
NSString *EXAttributeModificationDate = @"EXAttributeModificationDate";
NSString *EXAttributeName = @"EXAttributeName";
NSString *EXAttributeSize = @"EXAttributeSize";
NSString *EXAttributeFSNumber = @"EXAttributeFSNumber";
NSString *EXAttributeFSType = @"EXAttributeFSType";
NSString *EXAttributePosixPermissions = @"EXAttributePosixPermissions";
NSString *EXAttributeOwnerName = @"EXAttributeOwnerName";
NSString *EXAttributeOwnerNumber = @"EXAttributeOwnerNumber";
NSString *EXAttributeGroupOwnerName = @"EXAttributeGroupOwnerName";
NSString *EXAttributeGroupOwnerNumber = @"EXAttributeGroupOwnerNumber";
NSString *EXAttributeDeviceNumber = @"EXAttributeDeviceNumber";
NSString *EXAttributeExtension = @"EXAttributeExtension";

NSString *EXFSTypeDirectory = @"EXFSTypeDirectory";
NSString *EXFSTypeRegular = @"EXFSTypeRegular";
NSString *EXFSTypeLink = @"EXFSTypeLink"; // ExtendedWorkspaceKit custom link
NSString *EXFSTypeSymbolicLink = @"EXFSTypeSymbolicLink";
NSString *EXFSTypeSocket = @"EXFSTypeSocket";
NSString *EXFSTypeCharacterSpecial = @"EXFSTypeCharacterSpecial";
NSString *EXFSTypeBlockSpecial = @"EXFSTypeBlockSpecial";
NSString *EXFSTypeUnknown = @"EXFSTypeUnknown";

@interface EXContext (Private)
- (void) _setAttributes: (NSMutableDictionary *)dict;
- (void) _setHandleForContent: (EXVFSHandle *)handle;
@end

@implementation EXContext

- (id) initWithURL: (NSURL *)url
{
    if ((self = [super init]) != nil)
    {
        EXAttributesCore *infoCore = [EXAttributesCore sharedInstance];
        
        vfs = [EXVFS sharedInstance];
        ASSIGN(_url, url);
        [infoCore loadAttributesForContext: self];
    }
    
    return self;
}

- (void) dealloc
{
    RELEASE(_attributes);
    RELEASE(_url);
    [super dealloc];
}

/*
 * Facility methods
 */
 
- (NSDate *) creationDate
{
  return [_attributes objectForKey: EXAttributeCreationDate];
}

- (NSString *) extension
{
  return [_attributes objectForKey: EXAttributeExtension];
}

- (NSArray *) dependencies
{
  return nil; // Must be implemented later
}

- (BOOL) isVirtual
{
  return NO; // return [_url isVirtual];
}

/*
 * Entity context which is file returns :
 * NO for isMountable
 * NO for isVirtual
 *
 * Entity context which is not a file returns :
 * YES for isMountable
 * YES for isVirtual
 *
 * Element context returns:
 * NO for isMountable
 * YES for isVirtual
 *
 * isMountable equals to isVirtual && isEntityContext
 */

- (EXKeywordsAttribute *) keywords
{
  return nil;
}

- (NSDate *) modificationDate
{
  return [_attributes objectForKey: EXAttributeModificationDate];
}

- (NSString *) name
{
  return [_attributes objectForKey: EXAttributeName];
}

- (EXPresentationAttribute *) presentation
{
  return nil;
}

- (EXPreviewAttribute *) preview
{
  return nil;
}

- (int) size
{
  return [[_attributes objectForKey: EXAttributeSize] intValue];
}

- (EXTypeAttribute *) type
{
  return nil;
}

- (NSString *) universalUniqueIdentifier
{
  return nil;
}

- (NSURL *) URL
{
  return _url;
}

- (EXVFSHandle *) handleForContent
{
  return _handle;
}

// Private setter

- (void) _setHandleForContent: (EXVFSHandle *)handle
{
  _handle = handle;
}

/*
 * Canonic methods
 */
 
- (id) attributeForKey: (NSString *)key
{
  return [_attributes objectForKey: key];
}

- (NSDictionary *) attributes
{
  return _attributes;
}

- (void) setAttribute: (id)attribute forKey: (NSString *)key
{
  [_attributes setObject: attribute forKey: key];
  
  // Will do nothing more here until we add database and FS synchronization
  // Later we will put the attribute in the database on each call
}

/*
 * Search methods
 *
 * A search context is a context which stores a live search query wich needs to
 * be updated each time the observed context is changed. In the workspace
 * application, the search context are incarned by the stack object metaphor.
 */

- (void) addSearchContextObserver: (EXContext *)context
{

}

- (void) removeSearchContextObserver: (EXContext *)context
{

}

/*
 * Other facility methods
 */

- (void) appendExtension
{

}

- (BOOL) isEntity
{
  return YES;
}

// Put the context in a folder with a file which includes the metatadas related
// to this context and its content, extracted from the EXTMA database, and add
// an extension to each file which hasn't one.
- (void) package
{

}

- (void) packageWithoutExtension
{

}

- (NSArray *) subcontexts
{
  return [vfs subcontextsAtURL: _url deep: NO];
}

- (BOOL) stored
{
  return _stored;
}

// Open the context in the mode read/write
- (EXTVFSHandle *) open
{
    return [vfs openContextWithURL: [self URL] mode: EXVFSReadWriteContentMode];
}

— (void) close
{
    return [vfs closeContextWithVFSHandle : [self handleForContent]];
}

- (BOOL) storeAtURL: (NSURL *)url
{
  BOOL result;
  
  if (isEntity)
    {
      result = [vfs createEntityContextAtURL: url];
    }
  else
    {
      result = [vfs createElementContextAtURL: url];
    }
    
  if (result)  
    {
      // result = [self synchronize]; 
      // Not needed, it is done automatically when EXK receives the notification
      // from the VFS for -createXXXContextAtURL:
      _stored = YES;
    }
  
  return result;
}

- (BOOL) storeAtPath: (NSString *)path
{
  return [self storeAtURL: [NSURL fileURLWithPath: path]];
}

/*
 * Private methods
 */
 
- (void) _setAttributes: (NSMutableDictionary *)dict
{
    ASSIGN(_attributes, dict);
}

@end
