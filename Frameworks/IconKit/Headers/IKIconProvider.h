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

@interface IKIconProvider : NSObject
{
  NSMutableDictionary *_systemIconMappingList;
  BOOL _usesThumbnails;
  BOOL _ignoresCustomIcons;
}

+ (IKIconProvider *) sharedInstance;

/*
 * The two methods below implement an automated cache mechanism and a thumbnails
 * generator
 */

- (NSImage *) iconForURL: (NSURL *)url;
- (NSImage *) iconForPath: (NSString *)path;
- (NSImage *) defaultIconForURL: (NSURL *)url;
- (NSImage *) defaultIconForPath: (NSString *)path;

// NOTE: May be rename this method -themeIconForURL:
- (NSImage *) systemIconForURL: (NSURL *)url;

- (BOOL) usesThumbnails;
- (void) setUsesThumbnails: (BOOL)flag;
- (BOOL) ignoresCustomIcons;
- (void) setIgnoresCustomIcons: (BOOL)flag;

- (void) invalidCacheForURL: (NSURL *)url;
- (void) recacheForURL: (NSURL *)url;
- (void) invalidCacheForPath: (NSString *)path;
- (void) recacheForPath: (NSString *)path;

@end
