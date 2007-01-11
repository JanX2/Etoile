/*
	EXWorkspace.h

	Workspace class which implements support for an extended workspace

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>

	Author:   Quentin Mathe <qmathe@club-internet.fr>
	Created:  8 June 2004

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
@class NSURL;
@class NSArray;
@class EXSearchResult;
@class EXContext;
@class EXQuery;
@class EXKeywordsAttribute;
@protocol EXQueryHandler;

@interface EXWorkspace : NSObject
{

}

// Basic methods

+ (EXWorkspace *) sharedInstance;

// General Context related methods

- (EXContext *) contextForUniversalUniqueIdentifier: (NSString *)identifier;
- (EXContext *) contextForPath: (NSString *)path; // Can be an XPath
- (EXContext *) contextForURL: (NSURL *)url; // Uses -[EXContext initWithURL:]

// Entity Context related methods

- (EXContext *) entityContextForUniversalUniqueIdentifier: (NSString *)identifier;
- (EXContext *) entityContextForPath: (NSString *)path;
- (EXContext *) entityContextForURL: (NSURL *)url;

// If a file is mountable, each component inside it are seen as entity contexts.

// Element Context related methods

- (EXContext *) elementContextForUniversalUniqueIdentifier: (NSString *)identifier;
- (EXContext *) elementContextForPath: (NSString *)path; // Can be an XPath
- (EXContext *) elementContextForURL: (NSURL *)url;

// Indexation related methods

- (void) indexContext: (EXContext *)context deep: (BOOL)flag;
// Includes subcontexts indexing when flag is YES

- (void) indexAtPath: (NSString *)path update:  (BOOL)flag; 
// Includes subpaths
// Updates flag when NO triggers a new full reindexing, otherwise just updates the indexes


- (void) indexAtURL: (NSURL *)url update:  (BOOL)flag;
// Includes subURLs
// Updates flag when NO triggers a new full reindexing, otherwise just updates the indexes

- (void) indexVolumes: (NSArray *)volumes update: (BOOL)flag; 
// Should be able to specify the volume
// Updates flag when NO triggers a new full reindexing, otherwise just updates the indexes

// Search related methods

- (EXSearchResult *) searchWithQuery: (EXQuery *)query 
                               update: (BOOL)flag 
                              handler: (id <EXQueryHandler>)handler;
// Rely on the TrackerKit to return a tree structure in the case the query has
// been inited with a structural key
- (EXSearchResult *) searchWithQuery: (EXQuery *)query 
                               update: (BOOL)flag 
                             handlers: (id <EXQueryHandler>)firstHandler,...;

- (EXSearchResult *) searchForName: (NSString *)name 
                 insideContextsPath: (NSArray *)paths; // Can be an XPath
- (EXSearchResult *) searchForKeywords: (EXKeywordsAttribute *)keywords 
                     insideContextsPath: (NSArray *)paths; // Can be an XPath

@end
