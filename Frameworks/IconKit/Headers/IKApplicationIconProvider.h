/*
	IKApplicationIconProvider.h

	IKIconProvider subclass which offers when needed special facilities like on 
	the fly composited applications, documents and plugins icons (with its own
	cache mechanism)

	Copyright (C) 2004 Nicolas Roard <nicolas@roard.com>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Nicolas Roard <nicolas@roard.com>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

// FIXME: Must be renamed IKApplication may be and tweaked to fit this new scheme

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UKTest.h>

@interface IKApplicationIconProvider : NSObject <UKTest>
{
  NSString *_path;
  NSString *_identifier;
}

- (id) initWithBundlePath: (NSString *)path;
- (id) initWithBundleIdentifier: (NSString *)identifier;

- (NSImage *) applicationIcon;
- (NSImage *) documentIconForExtension: (NSString *)extension;
- (NSImage *) pluginIcon;

- (void) invalidateCache;
- (void) invalidateCacheAll;
- (void) recache;

@end
