/*
	EXTWorkspace.h

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
@class EXTSearchResult;
@class EXTContext;
@class EXTQuery;
@class EXTKeywordsAttribute;
@protocol EXTQueryHandler;

@interface EXTWorkspace : NSObject // Class cluster
{

}

// Basic methods

+ (EXTWorkspace *) sharedInstance;

// Starting from here all the methods are abstract aka subclass responsability
// Except when gnome-vfs is used, it is called here (within these class 
// methods), and by overriding the subclasses refines the behavior to handle 
// metatadas and simulated FS (like an XML FS which would be handled by 
// libferris)

// General Context related methods

- (EXTContext *) contextForUniversalUniqueIdentifier: (NSString *)identifier;
- (EXTContext *) contextForPath: (NSString *)path; // Can be an XPath
- (EXTContext *) contextForURL: (NSURL *)url;

// Entity Context related methods

- (EXTContext *) entityContextForUniversalUniqueIdentifier: 
  (NSString *)identifier;
- (EXTContext *) entityContextForPath: (NSString *)path;
- (EXTContext *) entityContextForURL: (NSURL *)url;

// If a file is mountable, each component inside it are seen as entity contexts.

// Element Context related methods

- (EXTContext *) elementContextForUniversalUniqueIdentifier: 
  (NSString *)identifier;
- (EXTContext *) elementContextForPath: (NSString *)path; // Can be an XPath
- (EXTContext *) elementContextForURL: (NSURL *)url;

// Indexation related methods

- (void) indexContext: (EXTContext *)context; // Include subcontexts indexing
- (void) runIndexationAtPath: (NSString *) path force:  (BOOL)flag;
- (void) runIndexationForce: (BOOL)flag; // should be able to specify the volume
// Force flag when YES triggers a new full reindexation

// Search related methods

- (EXTSearchResult *) searchWithQuery: (EXTQuery *)query 
                               update: (BOOL)flag 
                              handler: (id <EXTQueryHandler>)handler;
// Rely on the TrackerKit to return a tree structure in the case the query has
// been inited with a structural key
- (EXTSearchResult *) searchWithQuery: (EXTQuery *)query 
                               update: (BOOL)flag 
                             handlers: (id <EXTQueryHandler>)firstHandler,...;

- (EXTSearchResult *) searchForName: (NSString *)name 
                 insideContextsPath: (NSArray *)paths; // Can be an XPath
- (EXTSearchResult *) searchForKeywords: (EXTKeywordsAttribute *)keywords 
                     insideContextsPath: (NSArray *)paths; // Can be an XPath

@end
