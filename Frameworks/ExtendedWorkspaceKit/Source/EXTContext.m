/*
	EXTContext.m

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
#import "EXTBasicFSAttributesExtracter.h"
#import "EXTVFS.h"
#import "EXTContext.h"

// Needed until we have created the equivalent classes
@class EXTKeywordsAttribute;
@class EXTPresentationAttribute;
@class EXTPreviewAttribute;
@class EXTTypeAttribute;

NSString *EXTCreationDateAttributeKey = @"EXTCreationDateAttributeKey";
NSString *EXTModificationDateAttributeKey = @"EXTModificationDateAttributeKey";
NSString *EXTNameAttributeKey = @"EXTNameAttributeKey";
NSString *EXTSizeAttributeKey = @"EXTSizeAttributeKey";

@interface EXTContext (Private)
- (void) _setHandleForContent: (EXTVFSHandle *)handle;
@end

@implementation EXTContext

- (id) initWithURL: (NSURL *)url
{
  if ((self = [super init]) != nil)
    {
      EXTBasicFSAttributesExtracter *basicExtracter = 
        [EXTBasicFSAttributesExtracter sharedInstance];
      
      ASSIGN(_url, url);
      
      [self setAttribute: [basicExtracter name] forKey: EXTNameAttributeKey];
    }
    
  return self;
}

/*
 * Facility methods
 */
 
- (NSDate *) creationDate
{
  return [_attributes objectForKey: EXTCreationDateAttributeKey];
}

- (NSString *) extension
{
  return nil;
}

- (NSArray *) dependencies
{
  return nil;
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

- (EXTKeywordsAttribute *) keywords
{
  return nil;
}

- (NSDate *) modificationDate
{
  return [_attributes objectForKey: EXTModificationDateAttributeKey];
}

- (NSString *) name
{
  return [_attributes objectForKey: EXTNameAttributeKey];
}

- (EXTPresentationAttribute *) presentation
{
  return nil;
}

- (EXTPreviewAttribute *) preview
{
  return nil;
}

- (int) size
{
  return [[_attributes objectForKey: EXTSizeAttributeKey] intValue];
}

- (EXTTypeAttribute *) type
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

- (EXTVFSHandle *) handleForContent
{
  return _handle;
}

// Private setter

- (void) _setHandleForContent: (EXTVFSHandle *)handle
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

- (void) addSearchContextObserver: (EXTContext *)context
{

}

- (void) removeSearchContextObserver: (EXTContext *)context
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
  return [[EXTVFS sharedInstance] subcontextsAtURL: _url deep: NO];
}

@end
