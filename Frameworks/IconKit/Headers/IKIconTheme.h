/*
	IKIconTheme.h

	IKIconTheme class provides icon theme support (finding, loading icon 
	theme bundles and switching between them)

	Copyright (C) 2007 Quentin Mathe <qmathe@club-internet.fr>

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  February 2007

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

@protocol UKTest;


@interface IKIconTheme : NSObject <UKTest>
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
