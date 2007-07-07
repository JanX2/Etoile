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
#import "DefinitionWriter.h"
#import "HistoryManager.h"

@interface AppController : NSObject <DefinitionWriter>
{
	@private
	IBOutlet NSTextView* searchResultView;
	IBOutlet NSWindow* dictionaryContentWindow;
	
	NSMutableArray* dictionaries;
	HistoryManager* historyManager;
	
	NSToolbarItem* backItem;
	NSToolbarItem* forwardItem;
	NSToolbarItem* searchItem;
	NSSearchField* searchField;
}

- (id)init;

// Some methods called by the GUI
- (void) browseBackClicked: (id)sender;
- (void) browseForwardClicked: (id)sender;
- (void) orderFrontPreferencesPanel: (id)sender;
- (void) searchAction: (id)sender;

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
