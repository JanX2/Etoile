/*
	EXTVFS.m

	Front end VFS class which permits to do files manipulation in a FS agnostic
	way

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>

	Author:   Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2004

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
#import "EXTGNOMEVFS.h"
#import "EXTGNUstepVFS.h"
#import "EXTLibFerrisVFS.h"
#import "EXTWorkspace.h"
#import "EXTContext.h"
#import "ExtendedWorkspaceConfig.h"
#import "EXTVFS.h"

static EXTVFS *sharedVFS = nil;
static EXTWorkspace *workspace = nil;

@implementation EXTVFS

+ (void) initialize
{
  if (self = [EXTVFS class])
    {
      workspace = [EXTWorkspace sharedInstance];
    }
}

+ (EXTVFS *) sharedInstance
{
  if (sharedVFS == nil)
    {
      sharedVFS = [EXTVFS alloc];
      [sharedVFS init];
    }
    
  return sharedVFS;      
}

- (id) init
{
  if (sharedVFS != self)
    {
      RELEASE(self);
      return RETAIN(sharedVFS);
    }
  
  if ((self = [super init])  != nil)
    {
      if (VFSBackend == GNUstep)
        {
          _basicVFS = [[EXTGNUstepVFS alloc] init];
        }
      else
        {
	  _basicVFS = [[EXTGNOMEVFS alloc] init];
	}      
      _virtualVFS = [[EXTLibFerrisVFS alloc] init];
      
      _protocols = [[NSArray alloc] init];
    }
  
  return self;
}

- (void) dealloc
{
  RELEASE(_basicVFS);
  RELEASE(_virtualVFS);
  RELEASE(_protocols);
  
  [super dealloc];
}

/*
 * Protocols related methods
 */

- (NSArray *) supportedProtocols
{
  return _protocols;
}

/*
 * Destroy and create contexts
 */

- (BOOL) createContextWithURL: (NSURL *)url error: (NSError **)error
{
  return NO;
}

- (BOOL) removeContextWithURL: (NSURL *)url handler: (id)handler
{
  return NO;
}

- (BOOL) removeContextsWithURLs: (NSArray *)urls handler: (id)handler
{
  BOOL result;
  NSMutableArray *virtualURLs = [NSMutableArray array];
  NSMutableArray *basicURLs = [NSMutableArray array];
  NSEnumerator *e = [urls objectEnumerator];
  NSURL *obj;
  
  while ((obj = [e nextObject]) != nil)
    {
      if ([[workspace contextForURL: obj] isVirtual]) 
      // Better just a method call like [workspace isVirtualAtURL: obj]
        {
	      [virtualURLs addObject: obj];
	    }
      else
        {
	      [basicURLs addObject: obj];
	    }
    }
  
  if ([virtualURLs count] > 0)
    result = [_virtualVFS removeContextsWithURLs: virtualURLs handler: handler];
  
  if ([basicURLs count] > 0)
    result = [_basicVFS removeContextsWithURLs: basicURLs handler: handler];
    
  return result;
}


/*
 * Manipulate contexts
 */

- (BOOL) copyContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
{
  BOOL result;
  
  if ([[workspace contextForURL: source] isVirtual]
    && [[workspace contextForURL: destination] isVirtual])
    {
      result = [_virtualVFS copyContextWithURL: source 
                                         toURL: destination 
                                       handler: handler];
    }
  else
    {
      result = [_basicVFS copyContextWithURL: source 
                                       toURL: destination 
                                     handler: handler];
    }
    
  return result;
}

- (BOOL) copyContextsWithURLs: (NSArray *)sources 
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
  BOOL result;
  NSMutableArray *virtualSources = [NSMutableArray array];
  NSMutableArray *basicSources = [NSMutableArray array];
  NSEnumerator *e = [sources objectEnumerator];
  NSURL *obj;
  NSMutableArray *contexts = [NSMutableArray array];
  
  while ((obj = [e nextObject]) != nil)
    {
      if ([[workspace contextForURL: obj] isVirtual]) 
      // Better just a method call like [workspace isVirtualAtURL: obj]
        {
	      [virtualSources addObject: obj];
	    }
      else
        {
	      [basicSources addObject: obj];
	    }
    }
  
  if ([virtualSources count] > 0)
    result = [_virtualVFS moveContextsWithURLs: virtualSources 
                                         toURL: destination
                                       handler: handler];
  // In the case the destination is not virtual, the _virtualVFS will call the 
  // _basicVFS to write/move (see below also)
 
  if ([[workspace contextForURL: destination] isVirtual] == NO)
    {
      result = [_basicVFS moveContextsWithURLs: basicSources 
                                         toURL: destination 
                                       handler: handler];
    }
  else // destination is virtual
    {   
      result = [_virtualVFS moveContextsWithURLs: basicSources 
                                           toURL: destination                    
                                         handler: handler];
      
      /*
       * In the _virtualVFS, we will have code like below :
       *
       * e = [basicSources objectEnumerator];
       *
       * while ((obj = [e nextObject]) != nil)
       *  {
       *    context = [workspace contextForURL: obj];
       *    targetURL = [[NSURL urlWithURL: destination] setPath: 
       *     [[destination path] stringByAppendingPathComponent: [context name]]];
       *    [_virtualVFS writeContext: context atURL: targetURL];
       *    [_basicVFS destroyContext: context];
       *  }
       * 
       */
    }  
  
  return result;
}

- (BOOL) linkContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
                  linkStyle: (EXTLinkStyle) style;
{
  BOOL result;
  
  if ([[workspace contextForURL: source] isVirtual]
    && [[workspace contextForURL: destination] isVirtual])
    {
      [_virtualVFS linkContextWithURL: source 
                                toURL: destination 
                              handler: handler 
                            linkStyle: style];
    }
  else
    {
      [_basicVFS linkContextWithURL: source 
                              toURL: destination 
                            handler: handler 
                          linkStyle: style];
    }
  
  return result;
}

- (BOOL) moveContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
{
  BOOL result;
  
  if ([[workspace contextForURL: source] isVirtual]
    && [[workspace contextForURL: destination] isVirtual])
    {
      result = [_virtualVFS moveContextWithURL: source 
                                         toURL: destination 
                                       handler: handler];
    }
  else
    {
      result = [_basicVFS moveContextWithURL: source 
                                       toURL: destination 
                                     handler: handler];
    }
  
  return result;
}

- (BOOL) moveContextsWithURLs: (NSArray *)sources 
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
  BOOL result;
  NSMutableArray *virtualSources = [NSMutableArray array];
  NSMutableArray *basicSources = [NSMutableArray array];
  NSEnumerator *e = [sources objectEnumerator];
  NSURL *obj;
  NSArray *contexts = [NSMutableArray array];
  
  while ((obj = [e nextObject]) != nil)
    {
      if ([[workspace contextForURL: obj] isVirtual]) 
      // Better just a method call like [workspace isVirtualAtURL: obj]
        {
	      [virtualSources addObject: obj];
	    }
      else
        {
	      [basicSources addObject: obj];
	    }
    }
  if ([virtualSources count] > 0)
    result = [_virtualVFS moveContextsWithURLs: virtualSources 
                                         toURL: destination 
                                       handler: handler];
  // In the case the destination is not virtual, the _virtualVFS will call the 
  // _basicVFS to write/move (see below also)
 
  if ([[workspace contextForURL: destination] isVirtual] == NO)
    {
      result = [_basicVFS moveContextsWithURLs: basicSources 
                                         toURL: destination 
                                       handler: handler];
    }
  else
    {   
      result = [_virtualVFS moveContextsWithURLs: basicSources 
                                           toURL: destination 
                                         handler: handler];
      
      /*
       * In the _virtualVFS, we will have code like below :
       *
       * e = [basicSources objectEnumerator];
       *
       * while ((obj = [e nextObject]) != nil)
       *  {
       *    context = [workspace contextForURL: obj];
       *    targetURL = [[NSURL urlWithURL: destination] setPath: 
       *     [[destination path] stringByAppendingPathComponent: [context name]]];
       *    [_basicVFS writeContext: context atURL: targetURL];
       *    [_virtualVFS destroyContext: context];
       *  }
       * 
       */
    }  
  
  return result;
}

/*
 * Visit contexts
 */

- (NSArray *) subcontextsAtURL: (NSURL *)url deep: (BOOL)flag
{
  if ([[workspace contextForURL: url] isVirtual])
    {
      [_virtualVFS subcontextsAtURL: url deep: flag];
    }
  else
    {
      [_basicVFS subcontextsAtURL: url deep: flag];
    }
    
    return nil;
}

/*
 * Read, write contexts
 */
  
- (NSData *) readContext: (EXTContext *)context 
                  lenght: (unsigned long long)lenght 
                   error: (NSError **)error
{
  NSData *data = nil;
  
  if ([context isVirtual])
    {
      data = [_virtualVFS readContext: context lenght: lenght error: error];
    }
  else
    {
      data = [_basicVFS readContext: context lenght: lenght error: error];
    }
    
    return data;
}

- (void) writeContext: (EXTContext *)context 
                 data: (NSData *)data 
               lenght: (unsigned long long)lenght 
                error: (NSError **)error
{  
  if ([context isVirtual])
    {
      [_virtualVFS writeContext: context 
                           data: data 
                         lenght: lenght 
                          error: error];
    }
  else
    {
      [_basicVFS writeContext: context data: data lenght: lenght error: error];
    }
}

- (void) setPositionIntoContext: (EXTContext *)context 
                          start: (EXTReadWritePosition)start 
                         offset: (long long)offset 
                          error: (NSError **)error
{
  if ([context isVirtual])
    {
      [_virtualVFS setPositionIntoContext: context 
                                    start: start 
                                   offset: offset 
                                    error: error];
    }
  else
    {
      [_basicVFS setPositionIntoContext: context 
                                  start: start 
                                 offset: offset 
                                  error: error];
    }
}

- (long long) positionIntoContext: (EXTContext *)context 
                            error: (NSError **)error
{
  if ([context isVirtual])
    {
      [_virtualVFS positionIntoContext: context error: error];
    }
  else
    {
      [_basicVFS positionIntoContext: context error: error];
    }
}

/*
 * Extra methods
 */
 
- (BOOL) isEntityContextAtURL: (NSURL *)url
{
  return NO;
}

- (BOOL) isVirtualContextAtURL: (NSURL *)url
{
  return NO;
}
 
@end
