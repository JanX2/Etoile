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

@interface AppController : NSObject
{
	@private
	IBOutlet NSTextField* searchStringControl;
	IBOutlet NSTextView* searchResultView;
	IBOutlet NSButton* browseBackButton;
	IBOutlet NSButton* browseForwardButton;
	IBOutlet NSWindow* dictionaryContentWindow;
	
	NSMutableArray* dictionaries;
	HistoryManager* historyManager;
	
	NSToolbarItem* backItem;
	NSToolbarItem* forwardItem;
	NSToolbarItem* searchItem;
	NSSearchField* searchField;
}

-(id)init;


// Some methods called by the GUI
-(void) browseBackClicked: (id)sender;
-(void) browseForwardClicked: (id)sender;
-(void) orderFrontPreferencesPanel: (id)sender;


// TextView delegate stuff
-(BOOL) textView: (NSTextView*) textView
   clickedOnLink: (id) link
	 atIndex: (unsigned) charIndex;

-(void)updateGUI;


// Listen for actions...

// ...from the GUI
-(void) searchAction: (id)sender;

// ...from the Links in the text field
-(void) clickSearchNotification: (NSNotification*)aNotification;

// ..from the system
-(void) applicationWillTerminate: (NSNotification*) theNotification;
-(void) applicationDidFinishLaunching: (NSNotification*) theNotification;


-(void) defineWord: (NSString*)aWord;

@end


@interface AppController (DefinitionWriter) <DefinitionWriter> 

-(void) clearResults;
-(void) writeBigHeadline: (NSString*) aString;
-(void) writeHeadline: (NSString*) aString;
-(void) writeLine: (NSString*) aString;
-(void) writeString: (NSString*) aString
	       link: (id) aClickable;

// not part of the protocol
-(void) writeString: (NSString*) aString
	 attributes: (NSDictionary*) attributes;

@end

@interface AppController (HistoryManagerDelegate) <HistoryManagerDelegate>
-(BOOL) historyManager: (HistoryManager*) aHistoryManager
	 needsBrowseTo: (id) aLocation;
@end
