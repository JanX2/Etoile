/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <AppKit/AppKit.h>
#import "DictConnection.h"
#import "HistoryManager.h"

@interface AppController : NSObject
{
	@private
	IBOutlet NSTextView *searchResultView;
	IBOutlet NSWindow *dictionaryContentWindow;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSButton *backButton;
	IBOutlet NSButton *forwardButton;
	
	NSMutableArray* dictionaries;
	HistoryManager* historyManager;
	NSArray *definitions; /* Currently displayed definitions */
#if 0	
	NSToolbarItem* backItem;
	NSToolbarItem* forwardItem;
	NSToolbarItem* searchItem;
#endif
}

- (id)init;

// Some methods called by the GUI
- (void) browseBackClicked: (id) sender;
- (void) browseForwardClicked: (id) sender;
- (void) orderFrontPreferencesPanel: (id) sender;
- (void) searchAction: (id) sender;
- (void) increaseFontSize: (id) sender;
- (void) decreaseFontSize: (id) sender;

// TextView delegate stuff
- (BOOL) textView: (NSTextView*) textView clickedOnLink: (id) link
          atIndex: (unsigned) charIndex;

- (void) updateGUI;

// ...from the Links in the text field
- (void) clickSearchNotification: (NSNotification*)aNotification;

- (void) defineWord: (NSString*) aWord;

@end

@interface AppController (HistoryManagerDelegate)
- (BOOL) historyManager: (HistoryManager*) aHistoryManager
          needsBrowseTo: (id) aLocation;
@end
