/*
	EXSearchCore.h

	Search related class which implements the search coordinated over contexts content 
	and contexts attributes

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>

	Author:   Quentin Mathe <qmathe@club-internet.fr>
	Created:  August 2004

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

@class NSString;
@class NSArray;
@class EXAttributesCore;
@class EXContentIndexCore;
@class EXQuery;
@class EXKeywordsAttribute;
@class EXSearchResult;
@protocol EXQueryHandler;

@interface EXSearchCore : NSObject
{
  EXAttributesCore *_infoCore;
  EXContentIndexCore *_indexCore;
}

// Basic methods

+ (EXSearchCore *) sharedInstance;

// Search related methods

- (EXSearchResult *) searchWithQuery: (EXQuery *)query 
                               update: (BOOL)flag 
                              handler: (id <EXQueryHandler>)handler;
// Rely on the TrackerKit to return a tree structure in the case the query has 
// been inited with a structural key

- (EXSearchResult *) searchWithQuery: (EXQuery *)query 
                               update: (BOOL)flag 
                             handlers: (id <EXQueryHandler>)firstHandler, ...;
                             
- (EXSearchResult *) searchForName: (NSString *)name 
                 insideContextsPath: (NSArray *)paths; // Can be an XPath

- (EXSearchResult *) searchForKeywords: (EXKeywordsAttribute *)keywords 
                     insideContextsPath: (NSArray *)paths; // Can be an XPath

@end
