/*
	EXTWorkspace.m

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "EXTVFS.h"
#import "EXTDataCruxWorkspace.h"
#import "EXTLibferrisWorkspace.h"
#import "EXTContext.h"
#import "ExtendedWorkspaceConfig.h"
#import "EXTWorkspace.h"

static EXTWorkspace *sharedWorkspace = nil;
static EXTVFS *vfs = nil;

@implementation EXTWorkspace

// Basic methods

+ (EXTWorkspace *) sharedInstance
{
  if (sharedWorkspace == nil)
    {
      if (AttributesBackend == DataCruxSQLlite)
        {
          sharedWorkspace = [EXTDataCruxWorkspace alloc];
        }
      else if (AttributesBackend == LibferrisSQLlite)
        {
          sharedWorkspace = [EXTLibFerrisWorkspace alloc];
	} 
      else
        {
          sharedWorkspace = [EXTWorkspace alloc];
	}     
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
      vfs = [EXTVFS sharedInstance];
    }
  
  return self;
}

// Starting from here all the methods are abstract aka subclass responsability
// Except when EXTVFS class is used, it is called here (within these class 
// methods), and by overriding the subclasses the behavior is refined to handle
// metatadas and simulated FS (like an XML FS which would be handled by 
// libferris)

// General Context related methods

- (EXTContext *) contextForUniversalUniqueIdentifier: (NSString *)identifier
{
  [self subclassResponsibility: _cmd];
}

- (EXTContext *) contextForPath: (NSString *)path // Can be an XPath
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  return [self contextForURL: url];
}

- (EXTContext *) contextForURL: (NSURL *)url
{
  EXTContext *context = [[EXTContext alloc] initWithURL: url];
  
  return context;
}

// Entity context aka Folder context conte related methods

- (EXTContext *) entityContextForUniversalUniqueIdentifier: 
  (NSString *)identifier
{
  [self subclassResponsibility: _cmd];
}

- (EXTContext *) entityContextForPath: (NSString *)path
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  return [self entityContextForURL: url];
}

- (EXTContext *) entityContextForURL: (NSURL *)url
{
  EXTContext *context;
  NSURL *standardizedURL;
  
  standardizedURL = [url standardizedURL]; // Standardize query 
  /* 
  while (![vfs isEntityAtURL: standardizedURL])
    {
      NSString *path = [standardizedURL path];
      
      if ([path isEqualToString: @""])
        exit;
	
      path = [path stringByDeletingLastPathComponent];
      [standardizedURL setPath: path];
    }
  */ 
  context = [[EXTContext alloc] initWithURL: standardizedURL];
  
  return context;
}

// In the case we have a mountable object, each component which can be mounted
// inside it are seen as entity or element contexts.

// Element context aka File context related methods

- (EXTContext *) elementContextForUniversalUniqueIdentifier: 
  (NSString *)identifier
{
  [self subclassResponsibility: _cmd];
}

- (EXTContext *) elementContextForPath: (NSString *)path // Can be an XPath
{
  NSURL *url = [NSURL fileURLWithPath: path];
  
  return [self elementContextForURL: url];
}

- (EXTContext *) elementContextForURL: (NSURL *)url
{
  EXTContext *context;
  NSURL *standardizedURL;
  
  standardizedURL = [url standardizedURL]; // Standardize query 
  if ([vfs isEntityContextAtURL: standardizedURL])
    return nil;
  context = [[EXTContext alloc] initWithURL: standardizedURL];
  
  return context;
}

// Indexation related methods

- (void) indexContext: (EXTContext *)context // Include subcontexts indexing
{
  [self subclassResponsibility: _cmd];
}

- (void) runIndexationAtPath: (NSString *) path force:  (BOOL)flag
{
  [self subclassResponsibility: _cmd];
}

- (void) runIndexationForce: (BOOL)flag // should be able to specify the volume
// Force flag when YES triggers a new full reindexation
{
  [self subclassResponsibility: _cmd];
}

// Search related methods

- (EXTSearchResult *) searchWithQuery: (EXTQuery *)query 
                               update: (BOOL)flag 
                              handler: (id <EXTQueryHandler>)handler
// Rely on the TrackerKit to return a tree structure in the case the query has 
// been inited with a structural key
{
  [self subclassResponsibility: _cmd];
}

- (EXTSearchResult *) searchWithQuery: (EXTQuery *)query 
                               update: (BOOL)flag 
                             handlers: (id <EXTQueryHandler>)firstHandler, ...
{
  [self subclassResponsibility: _cmd];
}

- (EXTSearchResult *) searchForName: (NSString *)name 
                 insideContextsPath: (NSArray *)paths // Can be an XPath
{
  [self subclassResponsibility: _cmd];
}

- (EXTSearchResult *) searchForKeywords: (EXTKeywordsAttribute *)keywords 
                     insideContextsPath: (NSArray *)paths // Can be an XPath
{
  [self subclassResponsibility: _cmd];
}

@end
