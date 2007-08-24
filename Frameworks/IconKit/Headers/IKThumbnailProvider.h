/*
	IKThumbnailProvider.h

	IconKit thumbnail provider class which permits to obtain and store thumbnails  
	with a standard architecture available for the GNUstep applications (it is 
	possible to store custom thumbnails)
	IKThumbnailProvider is Freedesktop compatible
	
	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Nicolas Roard <nicolas@roard.com>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	   this list of conditions and the following disclaimer.
	2. Redistributions in binary form must reproduce the above copyright notice,
	   this list of conditions and the following disclaimer in the documentation
	   and/or other materials provided with the distribution.
	3. The name of the author may not be used to endorse or promote products
	   derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
	MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
	EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
	OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
	IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
	OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

typedef enum _IKThumbnailSize
{
  IKThumbnailSizeNormal,
  IKThumbnailSizeLarge
} IKThumbnailSize;

@interface IKThumbnailProvider : NSObject
{

}

+ (IKThumbnailProvider *) sharedInstance;

/*
 * Thumbnails are stored in ~/GNUstep/Library/Caches/IconKit/Thumbnails.
 * For Freedesktop compatibility, we add ~/.thumbnails soft link to the default
 * path.
 * The directory structure is
 * Thumbnails/normal which contains thumbnails with 128*128 size
 * Thumbnails/large which contains thumbnails with 256*256 size
 * Thumbnails/fail which tracks thumbnails creation errors.
 * Each thumbnail name is a MD5 hash of the original file URL.
 * Delete not valid thumbnails is the job of the user Workspace application.
 */

- (NSImage *) thumbnailForURL: (NSURL *)url 
                         size: (IKThumbnailSize)thumbnailSize;
- (NSImage *) thumbnailForPath: (NSString *)path 
                          size: (IKThumbnailSize) thumbnailSize;

- (void) setThumbnail: (NSImage *)thumbnail forURL: (NSURL *)url;
- (void) setThumbnail: (NSImage *)thumbnail forPath: (NSString *)path;

- (void) recacheForURL: (NSURL *)url;
- (void) recacheForPath: (NSString *)path;
- (void) invalidCacheForURL: (NSURL *)url;
- (void) invalidCacheForPath: (NSString *)path;
- (void) invalidCacheAll;

@end
