/*
	EXWorkspace.m

	Workspace class which implements support for an EXended workspace

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "EXVFS.h"
#import "EXAttributesCore.h"
#import "EXContentIndexCore.h"
#import "EXSearchCore.h"
#import "EXContext.h"
#import "ExtendedWorkspaceConfig.h"
#import "EXWorkspace.h"

static EXWorkspace *sharedWorkspace = nil;
static EXVFS *vfs = nil;
static EXAttributesCore *infoCore = nil;
static EXContentIndexCore *indexCore = nil;
static EXSearchCore *searchCore = nil;

@implementation EXWorkspace

// Basic methods

+ (EXWorkspace *) sharedInstance
{
  if (sharedWorkspace == nil)
    {
      sharedWorkspace = [EXWorkspace alloc];   
      sharedWorkspace = [sharedWorkspace init];
    }
    
  return sharedWorkspace;      
}

- (id) init
{
  if (sharedWorkspace != self)
    {
      RELEASE(self);
      return RETAIN(sharedWorkspace);
    }
  
  if ((self = [super init])  != nil)
    {
      vfs = [EXVFS sharedInstance];
      infoCore = [EXAttributesCore sharedInstance];
      indexCore = [EXContentIndexCore sharedInstance];
      searchCore = [EXSearchCore sharedInstance];
    }
  
  return self;
}

// In the future...
// Written from here all the methods could be abstract aka subclass responsability
// except when EXVFS class would be used, it would be called here (within these class 
// methods), and by overriding the subclasses the behavior would be refined to handle
// metatadas and simulated FS (like an XML virtual FS).

// General Context related methods

- (EXContext *) contextForUniversalUniqueIdentifier: (NSString *)identifier
{
    NSURL *url;
  
    // Ask the infoCore
  
    return [self contextForUR: url];
}

- (EXContext *) contextForPath: (NSString *)path // Can be an XPath
{
    NSURL *url = [NSURL fileURLWithPath: path];
  
    return [self contextForURL: url];
}

- (EXContext *) contextForURL: (NSURL *)url
{
    return [[EXContext alloc] initWithURL: url];
  
    // Ask the infoCore is done in -[EXContext initWithURL:]
    // With methods like
    // [infoCore loadAttributesForContext: context]
    // [infoCore updateAttributesForContext: context]
}

// Entity context aka Folder context related methods

- (EXContext *) entityContextForUniversalUniqueIdentifier: (NSString *)identifier
{
    NSURL *url;
  
    // Ask the infoCore
  
    return [self entityContextForURL: url];
}

- (EXContext *) entityContextForPath: (NSString *)path
{
    NSURL *url = [NSURL fileURLWithPath: path];
  
    return [self entityContextForURL: url];
}

- (EXContext *) entityContextForURL: (NSURL *)url
{
    EXContext *context;
    NSURL *standardizedURL;
  
    standardizedURL = [url standardizedURL]; // Makes the url standard
  
    /* 
    while (![vfs isEntityAtURL: standardizedURL])
    {
        NSString *path = [standardizedURL path];
      
        if ([path isEqualToString: @"/"])
            return;
	
        path = [path stringByDeletingLastPathComponent];
        [standardizedURL setPath: path];
    }
     */ 
  
    context = [[EXContext alloc] initWithURL: standardizedURL];
  
    return context;
}

// In the case we have a mountable object, each component which can be mounted
// inside it are seen as entity or element contexts.

// Element context aka File context related methods

- (EXContext *) elementContextForUniversalUniqueIdentifier: (NSString *)identifier
{
    NSURL *url;
  
    // Ask the infoCore
  
    return [self elementContextForURL: url];
}

- (EXContext *) elementContextForPath: (NSString *)path // Can be an XPath
{
    NSURL *url = [NSURL fileURLWithPath: path];
  
    return [self elementContextForURL: url];
}

- (EXContext *) elementContextForURL: (NSURL *)url
{
    NSURL *standardizedURL = [url standardizedURL]; 
    // Makes the url standard in order to have not to do at the VFS level
    // The return related method call induces to redo it otherwise
  
    if ([vfs isEntityContextAtURL: standardizedURL])
        return nil;
    
    return [[EXContext alloc] initWithURL: standardizedURL];
}

// Indexation related methods

- (void) indexContext: (EXContext *)context deep: (BOOL)flag // Includes subcontexts indexing when flag is YES
{
    [indexCore indexContext: context deep: flag];
}

- (void) indexAtPath: (NSString *) path update:  (BOOL)flag // Includes subpaths
// Updates flag when NO triggers a new full reindexing, otherwise just updates the indexes
{
    NSURL *url = [NSURL fileURLwithPath: path];
  
    [indexCore indexAtURL: url update: flag];
}

- (void) indexAtURL: (NSString *) path update:  (BOOL)flag // Includes subURLs
// Updates flag when NO triggers a new full reindexing, otherwise just updates the indexes
{
    [indexCore indexAtURL: url update: flag];
}

- (void) indexVolumes: (NSArray *)volumes update: (BOOL)flag // Should be able to specify the volume
// Updates flag when NO triggers a new full reindexing, otherwise just updates the indexes
{
    // [indexCore indexAllWithUpdate: flag];
}

// Search related methods

- (EXSearchResult *) searchWithQuery: (EXQuery *)query 
                              update: (BOOL)flag 
                             handler: (id <EXQueryHandler>)handler
// Rely on the TrackerKit to return a tree structure in the case the query has 
// been inited with a structural key
{
    return [searchCore searchWithQuery update: flag handler: handler];
}

- (EXSearchResult *) searchWithQuery: (EXQuery *)query 
                               update: (BOOL)flag 
                             handlers: (id <EXQueryHandler>)firstHandler, ...
{
    return [searchCore searchWithQuery update: flag handlers: handler];
}

- (EXSearchResult *) searchForName: (NSString *)name 
                 insideContextsPath: (NSArray *)paths // Can be an XPath
{
    return [searchCore searchForName: name insideContextsPath: paths];
}

- (EXSearchResult *) searchForKeywords: (EXKeywordsAttribute *)keywords 
                     insideContextsPath: (NSArray *)paths // Can be an XPath
{
    return [searchCore searchForKeywords: keywords insideContextsPath: paths];
}

@end
