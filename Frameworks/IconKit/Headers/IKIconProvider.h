/*
	IKIconProvider.h

	IconKit provider class which permits to obtain icons with a set of 
	facilities supported in the background like cache mechanism and thumbnails 
	generator

	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Nicolas Roard <nicolas@roard.com>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

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

@interface IKIconProvider : NSObject
{

}

+ (IKIconProvider) sharedInstance;

/*
 * The two methods below implement an automated cache mechanism and a thumbnails
 * generator
 */

- (NSImage *) iconForURL: (NSURL *)url;
- (NSImage *) iconForPath: (NSString *)path;

- (BOOL) usesThumbnails;
- (void) setUsesThumbnails: (BOOL)flag;
- (BOOL) ignoresCustomIcons;
- (void) setIgnoresCustomIcons: (BOOL)flag;

- (void) invalidCacheForURL: (NSURL *)url;
- (void) recacheForURL: (NSURL *)url;
- (void) invalidCacheForPath: (NSString *)path;
- (void) recacheForPath: (NSString *)path;

@end
