/*
	EXVFSBack.m

	Semi-abstract class (partially a cluster) which specifies the files access 
	in a FS agnostic way

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
#import "EXVFSProtocol.h"
#import "EXVFSBack.h"

@implementation EXVFSBack

/*
 * VFS protocol (objective-c related)  method
 */

/*
 * Protocols related methods
 */

- (NSArray *) supportedProtocols
{
  return nil;
}

/*
 * Destroy and create contexts
 */

- (BOOL) createEntityContextWithURL: (NSURL *)url error: (NSError **)error
{
    return NO
}

- (BOOL) createElementContextWithURL: (NSURL *)url error: (NSError **)error
{
    return NO;
}

- (BOOL) removeContextWithURL: (NSURL *)url handler: (id)handler
{
    return NO;
}

- (BOOL) removeContextsWithURLs: (NSArray *)urls handler: (id)handler
{
    return NO;
}

/*
 * Manipulate contexts
 */

- (BOOL) copyContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
{
  return NO;
}

- (BOOL) copyContextsWithURLs: (NSArray *)sources 
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
  return NO;
}

- (BOOL) linkContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
                  linkStyle: (EXLinkStyle) style
{
  return NO;
}

- (BOOL) moveContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
{
  return NO;
}

- (BOOL) moveContextsWithURLs: (NSArray *)sources 
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
  return NO;
}

/*
 * Visit contexts
 */
 
- (NSArray *) subcontextsURLsAtURL: (NSURL *)url deep: (BOOL)flag
{
  return nil;
}
 /*
 * Open, close contexts
 */
 
- (EXVFSHandle *) openContextWithURL: (NSURL *)url mode: (EXVFSContentMode *)mode
{
    return nil;
}

- (void) closeContextWithVFSHandle: (EXVFSHandle *)handle
{

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

}

- (void) writeContextWithVFSHandle: (EXVFSHandle *)handle  
                              data: (NSData *)data 
                            lenght: (unsigned long long)lenght 
                             error: (NSError **)error
{  

}

- (void) setPositionIntoContextVFSHandle: (EXVFSHandle *)handle 
                                   start: (EXReadWritePosition)start 
                                  offset: (long long)offset 
                                   error: (NSError **)error
{

}

- (long long) positionIntoContextVFSHandle: (EXVFSHandle *)handle 
                                     error: (NSError **)error
{

}
 
@end
