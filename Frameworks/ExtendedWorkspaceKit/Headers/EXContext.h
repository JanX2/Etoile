/*
	EXContext.h

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

#import "ExtendedWorkspaceConfig.h"

@class NSMutableDictionary;
@class NSDate;
@class NSString;
@class NSArray;
// Needed until we have created the equivalent classes
@class EXAttribute;
@class EXKeywordsAttribute;
@class EXPresentationAttribute;
@class EXPreviewAttribute;
@class EXTypeAttribute;
@class EXContentHandle;

extern NSString *EXCreationDateAttributeKey;
extern NSString *EXModificationDateAttributeKey;
extern NSString *EXNameAttributeKey;
extern NSString *EXSizeAttributeKey;

@interface EXContext : NSObject
{
  NSMutableDictionary *_attributes;
  NSURL *_url;
  EXVFSHandle *_handle;
}

- (id) initWithURL: (NSURL *)url;

/*
 * Facility methods
 */
 
- (NSDate *) creationDate;
- (NSString *) extension;
- (NSArray *) dependencies;
- (BOOL) isVirtual;

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

- (EXKeywordsAttribute *) keywords;
- (NSDate *) modificationDate;
- (NSString *) name;
- (EXPresentationAttribute *) presentation;
- (EXPreviewAttribute *) preview;
- (int) size;
- (EXTypeAttribute *) type;
- (NSString *) universalUniqueIdentifier;
- (NSURL *) URL;
- (EXVFSHandle *) handleForContent;

/*
 * Canonic methods
 */
 
- (id) attributeForKey: (NSString *)key;
- (NSDictionary *) attributes;
- (void) setAttribute: (id)attribute forKey: (NSString *)key;

/*
 * Search methods
 *
 * A search context is a context which stores a live search query wich needs to
 * be updated each time the observed context is changed. In the workspace
 * application, the search context are incarned by the stack object metaphor.
 */
 
- (void) addSearchContextObserver: (EXContext *)context;
- (void) removeSearchContextObserver: (EXContext *)context;

/*
 * Other facility methods
 */
 
- (void) appendExtension;
- (BOOL) isEntity;
- (void) package;
- (void) packageWithoutExtension;
- (NSArray *) subcontexts;

@end
