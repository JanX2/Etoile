/*
 * Name: OgreFindPanelController.h
 * Project: OgreKit
 *
 * Creation Date: Sep 13 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <AppKit/AppKit.h>
#import <OgreKit/OGRegularExpression.h>

@class OgreTextFinder, OgreFindResult, OgreFindPanel;

@interface OgreFindPanelController : NSResponder
{
	IBOutlet OgreTextFinder		*textFinder;
	IBOutlet OgreFindPanel		*findPanel;

	unsigned int options;
	OgreSyntax syntax;
}

- (IBAction)showFindPanel:(id)sender;
- (void)close;

- (OgreTextFinder*)textFinder;
- (void)setTextFinder:(OgreTextFinder*)aTextFinder;

- (NSPanel*)findPanel;
- (void)setFindPanel:(NSPanel*)aPanel;

- (NSDictionary*)history;

- (unsigned int) options;
- (void) setOptions: (unsigned int) options;

- (OgreSyntax) syntax;
- (void) setSyntax: (OgreSyntax) syntax;

/* Simple action for find panel  */
- (void) findNext: (id) sender;
- (void) findPrevious: (id) sender;

@end
