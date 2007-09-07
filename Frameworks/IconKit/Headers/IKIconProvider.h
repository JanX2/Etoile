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

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
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
