/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

#import "Category.h"

@protocol Category;

/**
 * Send a notification with this name and a database element as the
 * object to make that database element get the focus. (It will get
 * selected in the outline view.)
 */
extern NSString* const DatabaseElementFocusRequestNotification;

@protocol DatabaseElement <NSObject>

/**
 * Returns the super element of this database element. Note that
 * top level elements will return nil here.
 */
-(id<Category>) superElement;

/**
 * Sets the super element for an element
 */
-(void) setSuperElement: (id<Category>) superElement;

/**
 * Archives the element and all its subelements to a plist-conformant
 * NSDictionary object. The "isa" key of the dictionary must have the
 * class name of the archiving object as a value. Don't forget to
 * overwrite this class name in each subclass when archiving to the
 * plist dictionary!
 */
-(NSDictionary*) plistDictionary;

/**
 * Unarchives the element from a plist-conformant NSDictionary object.
 */
-(id) initWithDictionary: (NSDictionary*) aDictionary;

/**
 * Sets the name for the database element. This name is then
 * returned by the -description method.
 */
-(void) setName: (NSString*) aString;

@end


/**
 * Unarchives a database element from a plist dictionary. The plist dictionary
 * must have a "isa" key which indicates the class of the object to be unarchived.
 * The class must also be known to the application.
 */
extern id<DatabaseElement> DatabaseElementFromPlistDictionary( NSDictionary* plistDictionary );


