/*
	EXTVFS.h

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

#import "EXTVFSProtocol.h"

@class NSArray;
@class EXTVFSBack;

@interface EXTVFS : NSObject <EXTVFSProtocol>
{
  NSArray *_protocols;
  EXTVFSBack *_basicVFS;
  EXTVFSBack *_virtualVFS;
}

+ (EXTVFS *) sharedInstance;

/*
 * VFS protocol (objective-c related)  method
 */

/*
 * Protocols related methods
 */

// - (NSArray *) supportedProtocols;

/*
 * Destroy and create contexts
 */

// - (BOOL) createContextWithURL: (NSURL *)url; // error: (NSError **)error
// - (BOOL) removeContextWithURL: (NSURL *)url; // error: (NSError **)error

/*
 * Manipulate contexts
 */

// - (BOOL) copyContextWithURL: (NSURL *)source toURL: (NSURL *)destination
//   handler: (id)handler;
// - (BOOL) linkContextWithURL: (NSURL *)source toURL: (NSURL *)destination 
//   handler: (id)handler linkStyle: (EXTLinkStyle) style;
// - (BOOL) moveContextWithURL: (NSURL *)source toURL: (NSURL *)destination 
//   handler: (id)handler;

/*
 * Visit contexts
 */
 
// - (NSArray *) subcontextsAtURL: (NSURL *)url deep: (BOOL)flag;

/*
 * Extra methods
 */
 
- (BOOL) isEntityContextAtURL: (NSURL *)url;
- (BOOL) isVirtualContextAtURL: (NSURL *)url;
 
@end
