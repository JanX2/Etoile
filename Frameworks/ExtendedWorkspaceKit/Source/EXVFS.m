/*
	EXVFS.m

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
//#import "EXCometVFS.h"
#import "EXGNUstepVFS.h"
#import "EXWorkspace.h"
#import "EXContext.h"
#import "EXVFSProtocol.h"
#import "ExtendedWorkspaceConfig.h"
#import "EXVFS.h"

static EXVFS *sharedVFS = nil;
static EXWorkspace *workspace = nil;

@implementation EXVFS

+ (void) initialize
{
    	if (self = [EXVFS class])
    	{
		workspace = [EXWorkspace sharedInstance];
    	}
}

+ (EXVFS *) sharedInstance
{
    	if (sharedVFS == nil)
    	{
        	sharedVFS = [EXVFS alloc];
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
        if (VFSBackend == GNUstepVFS)
        {
            _vfs = [[EXGNUstepVFS alloc] init];
        }
        /*
        else
        {
            _vfs = [[EXCometVFS alloc] init];
        }
        */
      
        _protocols = RETAIN([_vfs supportedProtocols]);
    }
  
  return self;
}

- (void) dealloc
{
    RELEASE(_vfs);
    RELEASE(_protocols);
  
    [super dealloc];
}

- (BOOL) respondsToSelector: (SEL)selector
{
	if ([[self class] respondsToSelector: selector] 
		|| [_vfs respondsToSelector: selector])
	{
		return YES;
	}
	
	return NO;
}

- (void) forwardInvocation: (NSInvocation *)inv
{
	[inv invokeWithTarget: _vfs]; 
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

- (BOOL) createEntityContextAtURL: (NSURL *)url error: (NSError **)error
{
    	return [_vfs createEntityContextAtURL: url error: error];
}

- (BOOL) createElementContextAtURL: (NSURL *)url error: (NSError **)error
{
    	return [_vfs createElementContextAtURL: url error: error];
}

- (BOOL) removeContextAtURL: (NSURL *)url handler: (id)handler
{
    	return [_vfs removeContextAtURL: url handler: handler];
}

- (BOOL) removeContextsAtURLs: (NSArray *)urls handler: (id)handler
{
    	return [_vfs removeContextsAtURLs: urls handler: handler];
}

/*
 * Manipulate contexts
 */

- (BOOL) copyContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
{
    	return [_vfs copyContextWithURL: source toURL: destination handler: handler];
}

- (BOOL) copyContextsWithURLs: (NSArray *)sources 
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
    	return [_vfs copyContextsWithURLs: sources toURL: destination handler: handler];
}

- (BOOL) linkContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
                  linkStyle: (EXLinkStyle) style;
{
    	return [_vfs linkContextWithURL: source toURL: destination handler: handler linkStyle: style];
}

- (BOOL) moveContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
{
    	return [_vfs moveContextWithURL: source toURL: destination handler: handler];
}

- (BOOL) moveContextsWithURLs: (NSArray *)sources 
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
    	return [_vfs moveContextsWithURLs: sources toURL: destination handler: handler];
}

/*
 * Visit contexts
 */

- (NSArray *) subcontextsURLsAtURL: (NSURL *)url deep: (BOOL)flag
{
    	return [_vfs subcontextsURLsAtURL: url deep: flag];
}

/*
 * Open, close contexts
 */
 
- (EXVFSHandle *) openContextWithURL: (NSURL *)url mode: (EXVFSContentMode)mode
{
    	return [_vfs openContextWithURL: url mode: mode];
}

- (void) closeContextWithVFSHandle: (EXVFSHandle *)handle
{
    	[_vfs closeContextWithVFSHandle: handle];
}

/*
 * Read, write contexts
 */
  
// We need to pass a context and not an URL, because the context can maintain a handle for a file which is open
// with an URL, we would need to reopen the file each time we want the handle.

- (NSData *) readContextWithVFSHandle: (EXVFSHandle *)handle 
                               lenght: (unsigned long long)lenght 
                                error: (NSError **)error
{
  	return [_vfs readContextWithVFSHandle: handle lenght: lenght error: error];
}

- (void) writeContextWithVFSHandle: (EXVFSHandle *)handle  
                              data: (NSData *)data 
                            lenght: (unsigned long long)lenght 
                             error: (NSError **)error
{  
    	[_vfs writeContextWithVFSHandle: handle data: data lenght: lenght error: error];
}

- (void) setPositionIntoContextWithVFSHandle: (EXVFSHandle *)handle 
                                   start: (EXReadWritePosition)start 
                                  offset: (long long)offset 
                                   error: (NSError **)error
{
    	[_vfs setPositionIntoContextWithVFSHandle: handle start: start offset: offset error: error];
}

- (long long) positionIntoContextWithVFSHandle: (EXVFSHandle *)handle 
                                     error: (NSError **)error
{
    	[_vfs positionIntoContextWithVFSHandle: handle error: error];
}

/*
 * Extra methods
 */
 
- (BOOL) isEntityContextAtURL: (NSURL *)url
{
    	//return [_vfs isEntityContextAtURL: url];
	return NO;
}

- (BOOL) isElementContextAtURL: (NSURL *)url
{
    	//return [_vfs isElementContextAtURL: url];
	return NO;
}

- (BOOL) isVirtualContextAtURL: (NSURL *)url
{
	return NO;
}
 
 /*
  * Private methods
  */

- (int) _FSNumberForPath: (NSString *)path
{
    	return -1;
}

- (NSString *) _pathForFSNumber: (int)number
{
    	return nil;
}

@end
