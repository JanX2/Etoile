/*
	EXTVFSProtocol.h

	Protocol which is implemented by the classes which permits to interact with 
	a VFS.

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

typedef enum _EXTLinkStyle
{
  EXTLinkStyleSoft,
  EXTLinkStyleHard,
  EXTLinkStyleUniversal // Should be used most of the time
} EXTLinkStyle;

typedef enum _EXTReadWritePosition
{
  EXTReadWritePositionStart,
  EXTReadWritePositionCurrent,
  EXTReadWritePositionEnd
} EXTReadWritePosition;

@class NSError;
@class EXTContext;

@protocol EXTVFSProtocol

/*
 * Protocols related methods
 */

- (NSArray *) supportedProtocols;

/*
 * Destroy and create contexts
 */

- (BOOL) createContextWithURL: (NSURL *)url error: (NSError **)error;
- (BOOL) removeContextWithURL: (NSURL *)url handler: (id)handler;
- (BOOL) removeContextsWithURLs: (NSArray *)urls handler: (id)handler;

/*
 * Manipulate contexts
 */

- (BOOL) copyContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler;
- (BOOL) copyContextsWithURLs: (NSArray *)sources 
                        toURL: (NSURL *)destination 
                      handler: (id)handler;
- (BOOL) linkContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
                  linkStyle: (EXTLinkStyle) style;
- (BOOL) moveContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler;
- (BOOL) moveContextsWithURLs: (NSArray *)sources 
                        toURL: (NSURL *)destination 
                      handler: (id)handler;

/*
 * Visit contexts
 */
 
- (NSArray *) subcontextsAtURL: (NSURL *)url deep: (BOOL)flag;
 
/*
 * Read, write contexts
 */
  
- (NSData *) readContext: (EXTContext *)context 
                  lenght: (unsigned long long)lenght 
                   error: (NSError **)error;
- (void) writeContext: (EXTContext *)context 
                 data: (NSData *)data 
               lenght: (unsigned long long)lenght 
                error: (NSError **)error;
- (void) setPositionIntoContext: (EXTContext *)context 
                          start: (EXTReadWritePosition)start 
                         offset: (long long)offset 
                          error: (NSError **)error;
- (long long) positionIntoContext: (EXTContext *)context 
                            error: (NSError **)error;

@end
