/*
	IKIconTheme.h

	IKIconTheme class provides icon theme support (finding, loading icon 
	theme bundles and switching between them)

	Copyright (C) 2007 Quentin Mathe <qmathe@club-internet.fr>

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2007

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface IKIconTheme : NSObject
{
	NSString *_themeName;
	NSBundle *_themeBundle;

	/* Mapping of each specification identifier to multiple identifiers 
	   supported as synonyms (make compatibility straightforward) */
	NSMutableDictionary *_specIdentifiers; 
}

+ (IKIconTheme *) theme;
+ (void) setTheme: (IKIconTheme *)theme;

- (id) initWithPath: (NSString *)path;
- (id) initWithTheme: (NSString *)name;

- (NSString *) iconPathForIdentifier: (NSString *)iconIdentifier;
- (NSURL*) iconURLForIdentifier: (NSString *)iconIdentifier;

- (void) activate;
- (void) deactivate;

@end
