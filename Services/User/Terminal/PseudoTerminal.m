// -*- mode:objc -*-
// $Id: PseudoTerminal.m,v 1.315 2006/03/02 22:31:00 yfabian Exp $
//
/*
 **  PseudoTerminal.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian, Ujwal S. Setlur
 **	     Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: Session and window controller for iTerm.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

// Debug option
#define DEBUG_ALLOC           0
#define DEBUG_METHOD_TRACE    0

#import <iTerm/iTerm.h>
#import <iTerm/PseudoTerminal.h>
#import <iTerm/PTYScrollView.h>
#import <iTerm/NSStringITerm.h>
#import <iTerm/PTYSession.h>
#import <iTerm/VT100Screen.h>
#import <iTerm/PTYTabView.h>
#import <iTerm/PTYTabViewItem.h>
#import <iTerm/PreferencePanel.h>
#import <iTerm/iTermController.h>
#import <iTerm/PTYTask.h>
#import <iTerm/PTYTextView.h>
#import <iTerm/VT100Terminal.h>
#import <iTerm/VT100Screen.h>
#import <iTerm/PTYSession.h>
#import <iTerm/PTToolbarController.h>
#import <iTerm/FindPanelWindowController.h>
#import <iTerm/ITAddressBookMgr.h>
#import <iTerm/ITConfigPanelController.h>
#import <iTerm/ITSessionMgr.h>
#import <iTerm/iTermTerminalProfileMgr.h>
#import <iTerm/iTermDisplayProfileMgr.h>
#import <iTerm/Tree.h>
#include <unistd.h>

// keys for attributes:
NSString *columnsKey = @"columns";
NSString *rowsKey = @"rows";
// keys for to-many relationships:
NSString *sessionsKey = @"sessions";

#define TABVIEW_TOP_OFFSET				29
#define TABVIEW_BOTTOM_OFFSET			27
#define TABVIEW_LEFT_RIGHT_OFFSET		29
#define TOOLBAR_OFFSET					0

// just to keep track of available window positions
#define CACHED_WINDOW_POSITIONS		100
static unsigned int windowPositions[CACHED_WINDOW_POSITIONS];  

@implementation PseudoTerminal

- (id)initWithWindowNibName: (NSString *) windowNibName
{
    int i;
    
    if ((self = [super initWithWindowNibName: windowNibName]) == nil)
		return nil;
    
    // Look for an available window position
    for (i = 0; i < CACHED_WINDOW_POSITIONS; i++)
    {
		if(windowPositions[i] == 0)
		{
			[[self window] setFrameAutosaveName: [NSString stringWithFormat: @"iTerm Window %d", i]];
			windowPositions[i] = (unsigned int) self;
			break;
		}
    }
	     
	[self _commonInit];
	
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
	
    return self;
}

- (id)init
{
    return ([self initWithWindowNibName: @"PseudoTerminal"]);
}

+ (NSSize) viewSizeForColumns: (int) columns andRows: (int) rows withFont: (NSFont *) aFont
{
	NSParameterAssert(aFont != nil);
	NSParameterAssert (columns != 0);
	NSParameterAssert (rows != 0);
	
	int cw, ch;
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSSize sz, textViewSize, scrollViewSize, tabViewSize;
	
    [dic setObject:aFont forKey:NSFontAttributeName];
    sz = [@"W" sizeWithAttributes:dic];
	
	cw = sz.width;
	ch = [aFont defaultLineHeightForFont];
	
	textViewSize.width = cw * columns + MARGIN * 2;
	textViewSize.height = ch * rows;
	
	scrollViewSize = [PTYScrollView frameSizeForContentSize:textViewSize
									  hasHorizontalScroller:NO
										hasVerticalScroller:YES
												 borderType:NSNoBorder];
	
	tabViewSize = scrollViewSize;
	tabViewSize.height = scrollViewSize.height + 20;
	
	return (tabViewSize);
	
}


// Do not use both initViewWithFrame and initWindow
// initViewWithFrame is mainly meant for embedding a terminal view in a non-iTerm window.
- (PTYTabView*) initViewWithFrame: (NSRect) frame
{
    NSFont *aFont1, *aFont2;
    NSSize contentSize;
	NSString *displayProfile;
	
	// sanity check
	if(TABVIEW != nil)
		return (TABVIEW);
    
    // Create the tabview
    TABVIEW = [[PTYTabView alloc] initWithFrame: frame];
    [TABVIEW setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
    [TABVIEW setAllowsTruncatedLabels: NO];
    [TABVIEW setControlSize: NSSmallControlSize];
    [TABVIEW setAutoresizesSubviews: YES];
	
    aFont1 = FONT;
    if(aFont1 == nil)
    {
		NSDictionary *defaultSession = [[ITAddressBookMgr sharedInstance] defaultBookmarkData];
		displayProfile = [defaultSession objectForKey: KEY_DISPLAY_PROFILE];
		if(displayProfile == nil)
			displayProfile = [[iTermDisplayProfileMgr singleInstance] defaultProfileName];
		aFont1 = [[iTermDisplayProfileMgr singleInstance] windowFontForProfile: displayProfile];
		aFont2 = [[iTermDisplayProfileMgr singleInstance] windowNAFontForProfile: displayProfile];
		[self setFont: aFont1 nafont: aFont2];
    }
    
    NSParameterAssert(aFont1 != nil);
    // Calculate the size of the terminal
    contentSize = [NSScrollView contentSizeForFrameSize: [TABVIEW contentRect].size
								  hasHorizontalScroller: NO
									hasVerticalScroller: YES
											 borderType: NSNoBorder];
	
    [self setCharSizeUsingFont: aFont1];
    [self setWidth: (int) ((contentSize.width - MARGIN * 2)/charWidth + 0.1)
			height: (int) (contentSize.height/charHeight + 0.1)];
	
    return ([TABVIEW autorelease]);
}

// Do not use both initViewWithFrame and initWindow
- (void)initWindow
{
	// sanity check
    if(TABVIEW != nil)
		return;
	
    _toolbarController = [[PTToolbarController alloc] initWithPseudoTerminal:self];
    
    // Create the tabview
    TABVIEW = [[PTYTabView alloc] initWithFrame:[[[self window] contentView] bounds]];
    [TABVIEW setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
    [TABVIEW setAllowsTruncatedLabels: NO];
    [TABVIEW setControlSize: NSSmallControlSize];
    // Add to the window
    [[[self window] contentView] addSubview: TABVIEW];
    [[[self window] contentView] setAutoresizesSubviews: YES];
    [TABVIEW release];
	
    [[self window] setDelegate: self];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(_reloadAddressBook:)
                                                 name: @"iTermReloadAddressBook"
                                               object: nil];	
	
	[bookmarksView setDataSource: [PreferencePanel sharedInstance]];
	[bookmarksView setDelegate: self];
	[bookmarksView setTarget: self];
	[bookmarksView setDoubleAction: @selector(doubleClickedOnBookmarksView:)];
    
    [self setWindowInited: YES];
}

- (ITSessionMgr*)sessionMgr;
{
    return _sessionMgr;
}

- (void)setupSession: (PTYSession *) aSession
		       title: (NSString *)title
{
    NSDictionary *addressBookPreferences;
    NSDictionary *tempPrefs;
	NSString *terminalProfile, *displayProfile;
	iTermTerminalProfileMgr *terminalProfileMgr;
	iTermDisplayProfileMgr *displayProfileMgr;
	ITAddressBookMgr *bookmarkManager;
		
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal setupSession]",
          __FILE__, __LINE__);
#endif
	
    NSParameterAssert(aSession != nil);    
	
	// get our shared managers
	terminalProfileMgr = [iTermTerminalProfileMgr singleInstance];
	displayProfileMgr = [iTermDisplayProfileMgr singleInstance];
	bookmarkManager = [ITAddressBookMgr sharedInstance];	
	
    // Init the rest of the session
    [aSession setParent: self];
	
    // set some default parameters
    if([aSession addressBookEntry] == nil)
    {
		// get the default entry
		addressBookPreferences = [[ITAddressBookMgr sharedInstance] defaultBookmarkData];
		[aSession setAddressBookEntry:addressBookPreferences];
		tempPrefs = addressBookPreferences;
    }
    else
    {
		tempPrefs = [aSession addressBookEntry];
    }
	
	terminalProfile = [tempPrefs objectForKey: KEY_TERMINAL_PROFILE];
	displayProfile = [tempPrefs objectForKey: KEY_DISPLAY_PROFILE];
	
    if(WIDTH == 0 && HEIGHT == 0)
    {
		[self setColumns: [displayProfileMgr windowColumnsForProfile: displayProfile]];
		[self setRows: [displayProfileMgr windowRowsForProfile: displayProfile]];
		[self setAntiAlias: [displayProfileMgr windowAntiAliasForProfile: displayProfile]];
    }
    [aSession initScreen: [TABVIEW contentRect] width:WIDTH height:HEIGHT];
    if(FONT == nil) 
	{
		[self setFont: [displayProfileMgr windowFontForProfile: displayProfile] 
			   nafont: [displayProfileMgr windowNAFontForProfile: displayProfile]];
		[self setCharacterSpacingHorizontal: [displayProfileMgr windowHorizontalCharSpacingForProfile: displayProfile] 
								   vertical: [displayProfileMgr windowVerticalCharSpacingForProfile: displayProfile]];
    }
    
    [aSession setPreferencesFromAddressBookEntry: tempPrefs];
	 	
    [[aSession SCREEN] setDisplay:[aSession TEXTVIEW]];
	[[aSession TEXTVIEW] setFont:FONT nafont:NAFONT];
	[[aSession TEXTVIEW] setAntiAlias: antiAlias];
    [[aSession TEXTVIEW] setLineHeight: charHeight];
    [[aSession TEXTVIEW] setLineWidth: WIDTH * charWidth];
	[[aSession TEXTVIEW] setCharWidth: charWidth];
	// NSLog(@"%d,%d",WIDTH,HEIGHT);
		
    [[aSession TERMINAL] setTrace:YES];	// debug vt100 escape sequence decode
	
    // tell the shell about our size
    [[aSession SHELL] setWidth:WIDTH  height:HEIGHT];
	
    if (title) 
    {
        [self setWindowTitle: title];
        [aSession setName: title];
    }
}

- (void) switchSession: (id) sender
{
    [self selectSessionAtIndex: [sender tag]];
}

- (void) setCurrentSession: (PTYSession *) aSession
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal setCurrentSession:%@]",
          __FILE__, __LINE__, aSession);
#endif
    
    [TABVIEW selectTabViewItemWithIdentifier: aSession];
    if ([_sessionMgr currentSession]) 
        [[_sessionMgr currentSession] resetStatus];
    
    [_sessionMgr setCurrentSession:aSession];
    
    	
    [self setWindowTitle];
    [[_sessionMgr currentSession] setLabelAttribute];
    [[TABVIEW window] makeFirstResponder:[[_sessionMgr currentSession] TEXTVIEW]];

    [[TABVIEW window] setNextResponder:self];
	
    // send a notification
    [[NSNotificationCenter defaultCenter] postNotificationName: @"iTermSessionDidBecomeActive" object: aSession];
}

- (void)selectSessionAtIndexAction:(id)sender
{
    [self selectSessionAtIndex:[sender tag]];
}

- (void) newSessionInTabAtIndex: (id) sender
{
    [[iTermController sharedInstance] launchBookmark: [sender representedObject] inTerminal:self];
}

- (void) selectSessionAtIndex: (int) sessionIndex
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal selectSessionAtIndex:%d]",
          __FILE__, __LINE__, sessionIndex);
#endif
    if (sessionIndex < 0 || sessionIndex >= [_sessionMgr numberOfSessions]) 
        return;
	
    [self setCurrentSession:[_sessionMgr sessionAtIndex:sessionIndex]];
}

- (void) insertSession: (PTYSession *) aSession atIndex: (int) index
{
    PTYTabViewItem *aTabViewItem;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal insertSession: 0x%x atIndex: %d]",
          __FILE__, __LINE__, aSession, index);
#endif    
	
    if(aSession == nil)
		return;
	
    if (![_sessionMgr containsSession:aSession])
    {
		[aSession setParent:self];
        
		if ([_sessionMgr numberOfSessions] == 0)
		{
			// Tell us whenever something happens with the tab view
			[TABVIEW setDelegate: self];
		}	
		
		// create a new tab
		aTabViewItem = [[PTYTabViewItem alloc] initWithIdentifier: aSession];
		NSParameterAssert(aTabViewItem != nil);
		[aTabViewItem setLabel: [aSession name]];
		[aTabViewItem setView: [aSession view]];
		[[aSession SCROLLVIEW] setLineScroll: charHeight];
        [[aSession SCROLLVIEW] setPageScroll: HEIGHT*charHeight/2];
		[TABVIEW insertTabViewItem: aTabViewItem atIndex: index];
		
        [aTabViewItem release];
		[aSession setTabViewItem: aTabViewItem];
		[self selectSessionAtIndex:index];
		
		if ([TABVIEW numberOfTabViewItems] == 1)
		{
            [[aSession TEXTVIEW] scrollEnd];
		}
		else if ([TABVIEW numberOfTabViewItems] == 2)
		{
			[self windowDidResize: nil];
			[self setWindowSize: YES];
		}
			
		if([self windowInited])
			[[self window] makeKeyAndOrderFront: self];
		[[iTermController sharedInstance] setCurrentTerminal: self];
    }
}

- (void) closeSession: (PTYSession*) aSession
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, aSession);
#endif    
	
    NSTabViewItem *aTabViewItem;
    
    if((_sessionMgr == nil) || ![_sessionMgr containsSession:aSession])
        return;
    
    if([_sessionMgr numberOfSessions] == 1 && [self windowInited])
    {
        [[self window] close];
        return;
    }
		
	[aSession retain];  
	aTabViewItem = [aSession tabViewItem];
	[aTabViewItem retain];
	[aSession terminate];
	[aSession release];
	[TABVIEW removeTabViewItem: aTabViewItem];
	[aTabViewItem release];	
		
}

- (IBAction) closeCurrentSession: (id) sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal closeCurrentSession]",
          __FILE__, __LINE__);
#endif
	
    if(_sessionMgr == nil)
        return;
	
    if (![[_sessionMgr currentSession] exited])
    {
		if ([[PreferencePanel sharedInstance] promptOnClose] &&
			NSRunAlertPanel(NSLocalizedStringFromTableInBundle(@"The current session will be closed",@"iTerm", [NSBundle bundleForClass: [self class]], @"Close Session"),
							NSLocalizedStringFromTableInBundle(@"All unsaved data will be lost",@"iTerm", [NSBundle bundleForClass: [self class]], @"Close window"),
							NSLocalizedStringFromTableInBundle(@"OK",@"iTerm", [NSBundle bundleForClass: [self class]], @"OK"),
							NSLocalizedStringFromTableInBundle(@"Cancel",@"iTerm", [NSBundle bundleForClass: [self class]], @"Cancel")
							,nil) == 0) return;
    }
	
    [self closeSession:[_sessionMgr currentSession]];
}

- (IBAction)previousSession:(id)sender
{
    int theIndex;
    
    if ([_sessionMgr currentSessionIndex] == 0)
        theIndex = [_sessionMgr numberOfSessions] - 1;
    else
        theIndex = [_sessionMgr currentSessionIndex] - 1;
    
    [self selectSessionAtIndex: theIndex];    
}

- (IBAction) nextSession:(id)sender
{
    int theIndex;
	
    if ([_sessionMgr currentSessionIndex] == ([_sessionMgr numberOfSessions] - 1))
        theIndex = 0;
    else
        theIndex = [_sessionMgr currentSessionIndex] + 1;
    
    [self selectSessionAtIndex: theIndex];
}

- (NSString *) currentSessionName
{
    return ([[_sessionMgr currentSession] name]);
}

- (void) setCurrentSessionName: (NSString *) theSessionName
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal setCurrentSessionName]",
          __FILE__, __LINE__);
#endif
    NSMutableString *title = [NSMutableString string];
    
    if(theSessionName != nil)
    {
        [[_sessionMgr currentSession] setName: theSessionName];
        [[[_sessionMgr currentSession] tabViewItem] setLabel: theSessionName];
    }
    else {
        NSString *progpath = [NSString stringWithFormat: @"%@ #%d", [[[[[_sessionMgr currentSession] SHELL] path] pathComponents] lastObject], [_sessionMgr currentSessionIndex]];
		
        if ([[_sessionMgr currentSession] exited])
            [title appendString:@"Finish"];
        else
            [title appendString:progpath];
		
        [[_sessionMgr currentSession] setName: title];
        [[[_sessionMgr currentSession] tabViewItem] setLabel: title];
		
    }
    [self setWindowTitle];
}

- (PTYSession *) currentSession
{
    return [_sessionMgr currentSession];
}

- (int) currentSessionIndex
{
    return ([_sessionMgr currentSessionIndex]);
}

- (void)dealloc
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseObjects];
    [_toolbarController release];
	
    [super dealloc];
}

- (void)releaseObjects
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
	
    // Release all our sessions
    [_sessionMgr release];
    _sessionMgr = nil;
}

- (void)startProgram:(NSString *)program
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal startProgram:%@]",
		  __FILE__, __LINE__, program );
#endif
    [[_sessionMgr currentSession] startProgram:program
									 arguments:[NSArray array]
								   environment:[NSDictionary dictionary]];
		
}

- (void)startProgram:(NSString *)program arguments:(NSArray *)prog_argv
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal startProgram:%@ arguments:%@]",
          __FILE__, __LINE__, program, prog_argv );
#endif
    [[_sessionMgr currentSession] startProgram:program
									 arguments:prog_argv
								   environment:[NSDictionary dictionary]];
		
}

- (void)startProgram:(NSString *)program
		   arguments:(NSArray *)prog_argv
		 environment:(NSDictionary *)prog_env
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal startProgram:%@ arguments:%@]",
          __FILE__, __LINE__, program, prog_argv );
#endif
    [[_sessionMgr currentSession] startProgram:program
									 arguments:prog_argv
								   environment:prog_env];
	
    if ([[[self window] title] compare:@"Window"]==NSOrderedSame) 
		[self setWindowTitle];

}

- (void) setWidth: (int) width height: (int) height
{
    WIDTH = width;
    HEIGHT = height;
}

- (int)width;
{
    return WIDTH;
}

- (int)height;
{
    return HEIGHT;
}

- (void)setCharSizeUsingFont: (NSFont *)font
{
	int i;
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    NSSize sz;
    [dic setObject:font forKey:NSFontAttributeName];
    sz = [@"W" sizeWithAttributes:dic];
	
	charWidth = (sz.width * charHorizontalSpacingMultiplier);
	charHeight = ([font defaultLineHeightForFont] * charVerticalSpacingMultiplier);

	for(i=0;i<[_sessionMgr numberOfSessions]; i++) 
    {
        PTYSession* session = [_sessionMgr sessionAtIndex:i];
		[[session TEXTVIEW] setCharWidth: charWidth];
		[[session TEXTVIEW] setLineHeight: charHeight];
    }
	
	
	[[self window] setResizeIncrements: NSMakeSize(charWidth, charHeight)];
	
}	
- (int)charWidth
{
	return charWidth;
}

- (int)charHeight
{
	return charHeight;
}

- (float) charSpacingHorizontal
{
	return (charHorizontalSpacingMultiplier);
}

- (float) charSpacingVertical
{
	return (charVerticalSpacingMultiplier);
}


- (void)setWindowSize: (BOOL) resizeContentFrames
{    
    NSSize size, vsize, winSize;
    NSWindow *thisWindow;
    int i;
    NSRect tabviewRect, oldFrame;
    NSPoint topLeft;
    PTYTextView *theTextView;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal setWindowSize]", __FILE__, __LINE__ );
#endif
    
    if([self windowInited] == NO)
		return;
    
    // Resize the tabview first if necessary
    if([TABVIEW tabViewType] == NSTopTabsBezelBorder)
    {
		tabviewRect = [[[self window] contentView] frame];
		tabviewRect.origin.x -= 10;
		tabviewRect.size.width += 20;
		tabviewRect.origin.y -= 13;
		tabviewRect.size.height += 9;
    }
    else if([TABVIEW tabViewType] == NSLeftTabsBezelBorder)
    {
		tabviewRect = [[[self window] contentView] frame];
		tabviewRect.origin.x += 2;
		tabviewRect.size.width += 7;
		tabviewRect.origin.y -= 13;
		tabviewRect.size.height += 20;
    }
    else if([TABVIEW tabViewType] == NSBottomTabsBezelBorder)
    {
		tabviewRect = [[[self window] contentView] frame];
		tabviewRect.origin.x -= 10;
		tabviewRect.size.width += 20;
		tabviewRect.origin.y += 2;
		tabviewRect.size.height += 5;
    }
    else if([TABVIEW tabViewType] == NSRightTabsBezelBorder)
    {
		tabviewRect = [[[self window] contentView] frame];
		tabviewRect.origin.x -= 10;
		tabviewRect.size.width += 8;
		tabviewRect.origin.y -= 13;
		tabviewRect.size.height += 20;
    }
    else
    {
		tabviewRect = [[[self window] contentView] frame];
		tabviewRect.origin.x -= 10;
		tabviewRect.size.width += 20;
		tabviewRect.origin.y -= 13;
		tabviewRect.size.height += 20;
    }
    [TABVIEW setFrame: tabviewRect];
	
    vsize.width = charWidth * WIDTH + MARGIN * 2;
	vsize.height = charHeight * HEIGHT;
   // NSLog(@"width=%d,height=%d",[[[_sessionMgr currentSession] SCREEN] width],[[[_sessionMgr currentSession] SCREEN] height]);
    size = [PTYScrollView frameSizeForContentSize:vsize
							hasHorizontalScroller:NO
							  hasVerticalScroller:YES
									   borderType:NSNoBorder];
	
    for (i = 0; i < [_sessionMgr numberOfSessions]; i++)
    {
        [[[_sessionMgr sessionAtIndex: i] SCROLLVIEW] setLineScroll: charHeight];
        [[[_sessionMgr sessionAtIndex: i] SCROLLVIEW] setPageScroll: HEIGHT*charHeight/2];
		if(resizeContentFrames)
		{
			[[[_sessionMgr sessionAtIndex: i] view] setFrameSize: size];
			theTextView = [[[_sessionMgr sessionAtIndex: i] SCROLLVIEW] documentView];
			[theTextView setFrameSize: vsize];
		}
    }
    
    thisWindow = [[[_sessionMgr currentSession] SCROLLVIEW] window];
    winSize = size;
    if([TABVIEW tabViewType] == NSTopTabsBezelBorder)
		winSize.height = size.height + TABVIEW_TOP_OFFSET;
    else if([TABVIEW tabViewType] == NSLeftTabsBezelBorder)
		winSize.width = size.width + TABVIEW_LEFT_RIGHT_OFFSET;
    else if([TABVIEW tabViewType] == NSBottomTabsBezelBorder)
		winSize.height = size.height + TABVIEW_BOTTOM_OFFSET;
    else if([TABVIEW tabViewType] == NSRightTabsBezelBorder)
		winSize.width = size.width + TABVIEW_LEFT_RIGHT_OFFSET;
    else
        winSize.height = size.height + 0;
    if([[thisWindow toolbar] isVisible] == YES)
		winSize.height += TOOLBAR_OFFSET;
	
    // preserve the top left corner of the frame
    oldFrame = [thisWindow frame];
    topLeft.x = oldFrame.origin.x;
    topLeft.y = oldFrame.origin.y + oldFrame.size.height;
    
    [thisWindow setContentSize:winSize];
	
    [thisWindow setFrameTopLeftPoint: topLeft];
	//[self windowDidResize: nil];
}

- (void)setWindowTitle
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal setWindowTitle]",
          __FILE__, __LINE__);
#endif
	
    if([[self currentSession] windowTitle] == nil)
		[[self window] setTitle:[self currentSessionName]];
    else
		[[self window] setTitle:[[self currentSession] windowTitle]];
}

- (void) setWindowTitle: (NSString *)title
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal setWindowTitle:%@]",
          __FILE__, __LINE__, title);
#endif
    [[self window] setTitle:title];
}

// increases or dcreases font size
- (void) changeFontSize: (BOOL) increase
{
	
    float newFontSize;
    
	    
    float asciiFontSize = [[self font] pointSize];
    if(increase == YES)
		newFontSize = [self largerSizeForSize: asciiFontSize];
    else
		newFontSize = [self smallerSizeForSize: asciiFontSize];	
    NSFont *newAsciiFont = [NSFont fontWithName: [[self font] fontName] size: newFontSize];
    
    float nonAsciiFontSize = [[self nafont] pointSize];
    if(increase == YES)
		newFontSize = [self largerSizeForSize: nonAsciiFontSize];
    else
		newFontSize = [self smallerSizeForSize: nonAsciiFontSize];	    
    NSFont *newNonAsciiFont = [NSFont fontWithName: [[self nafont] fontName] size: newFontSize];
    
    if(newAsciiFont != nil && newNonAsciiFont != nil)
    {
		[self setFont: newAsciiFont nafont: newNonAsciiFont];		
		[self resizeWindow: [self width] height: [self height]];
    }
    
	
}

- (float) largerSizeForSize: (float) aSize 
    /*" Given a font size of aSize, return the next larger size.   Uses the 
    same list of font sizes as presented in the font panel. "*/ 
{
    
    if (aSize <= 8.0) return 9.0;
    if (aSize <= 9.0) return 10.0;
    if (aSize <= 10.0) return 11.0;
    if (aSize <= 11.0) return 12.0;
    if (aSize <= 12.0) return 13.0;
    if (aSize <= 13.0) return 14.0;
    if (aSize <= 14.0) return 18.0;
    if (aSize <= 18.0) return 24.0;
    if (aSize <= 24.0) return 36.0;
    if (aSize <= 36.0) return 48.0;
    if (aSize <= 48.0) return 64.0;
    if (aSize <= 64.0) return 72.0;
    if (aSize <= 72.0) return 96.0;
    if (aSize <= 96.0) return 144.0;
	
    // looks odd, but everything reasonable should have been covered above
    return 288.0; 
} 

- (float) smallerSizeForSize: (float) aSize 
    /*" Given a font size of aSize, return the next smaller size.   Uses 
    the same list of font sizes as presented in the font panel. "*/
{
    
    if (aSize >= 288.0) return 144.0;
    if (aSize >= 144.0) return 96.0;
    if (aSize >= 96.0) return 72.0;
    if (aSize >= 72.0) return 64.0;
    if (aSize >= 64.0) return 48.0;
    if (aSize >= 48.0) return 36.0;
    if (aSize >= 36.0) return 24.0;
    if (aSize >= 24.0) return 18.0;
    if (aSize >= 18.0) return 14.0;
    if (aSize >= 14.0) return 13.0;
    if (aSize >= 13.0) return 12.0;
    if (aSize >= 12.0) return 11.0;
    if (aSize >= 11.0) return 10.0;
    if (aSize >= 10.0) return 9.0;
    
    // looks odd, but everything reasonable should have been covered above
    return 8.0; 
} 

- (void) setCharacterSpacingHorizontal: (float) horizontal vertical: (float) vertical
{
	charHorizontalSpacingMultiplier = horizontal;
	charVerticalSpacingMultiplier = vertical;
	[self setCharSizeUsingFont: FONT];
}

- (BOOL) antiAlias
{
	return (antiAlias);
}

- (void) setAntiAlias: (BOOL) bAntiAlias
{
	PTYSession *aSession;
	int i, cnt = [_sessionMgr numberOfSessions];
	
	antiAlias = bAntiAlias;
	
	for(i=0; i<cnt; i++)
	{
		aSession = [_sessionMgr sessionAtIndex: i];
		[[aSession TEXTVIEW] setAntiAlias: antiAlias];
	}
	
	[[[self currentSession] TEXTVIEW] setNeedsDisplay: YES];
	
}

- (void)setFont:(NSFont *)font nafont:(NSFont *)nafont
{
	int i;
	
    [FONT autorelease];
    [font retain];
    FONT=font;
    [NAFONT autorelease];
    [nafont retain];
    NAFONT=nafont;
	[self setCharSizeUsingFont: FONT];
    for(i=0;i<[_sessionMgr numberOfSessions]; i++) 
    {
        PTYSession* session = [_sessionMgr sessionAtIndex:i];
        [[session TEXTVIEW]  setFont:FONT nafont:NAFONT];
    }
}

- (NSFont *) font
{
	return FONT;
}

- (NSFont *) nafont
{
	return NAFONT;
}

- (void)clearBuffer:(id)sender
{
    [[_sessionMgr currentSession] clearBuffer];
}

- (void)clearScrollbackBuffer:(id)sender
{
    [[_sessionMgr currentSession] clearScrollbackBuffer];
}

- (IBAction)logStart:(id)sender
{
    if (![[_sessionMgr currentSession] logging]) [[_sessionMgr currentSession] logStart];
    // send a notification
    [[NSNotificationCenter defaultCenter] postNotificationName: @"iTermSessionDidBecomeActive" object: [_sessionMgr currentSession]];
}

- (IBAction)logStop:(id)sender
{
    if ([[_sessionMgr currentSession] logging]) [[_sessionMgr currentSession] logStop];
    // send a notification
    [[NSNotificationCenter defaultCenter] postNotificationName: @"iTermSessionDidBecomeActive" object: [_sessionMgr currentSession]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    BOOL logging = [[_sessionMgr currentSession] logging];
    BOOL result = YES;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal validateMenuItem:%@]",
          __FILE__, __LINE__, item );
#endif
	
    if ([item action] == @selector(logStart:)) {
        result = logging == YES ? NO:YES;
    }
    else if ([item action] == @selector(logStop:)) {
        result = logging == NO ? NO:YES;
    }
    return result;
}

- (void) sendInputToAllSessions: (NSData *) data
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal sendDataToAllSessions:]",
		  __FILE__, __LINE__);
#endif
	// could be called from a thread
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    NSArray *sessionList = [_sessionMgr sessionList];
    NSEnumerator *sessionEnumerator = [sessionList objectEnumerator];
    PTYSession *aSession;
    
    while ((aSession = [sessionEnumerator nextObject]) != nil)
    {
		PTYScroller *ptys=(PTYScroller *)[[aSession SCROLLVIEW] verticalScroller];
		
		[[aSession SHELL] writeTask:data];

		// Make sure we scroll down to the end
		[[aSession TEXTVIEW] scrollEnd];
		[ptys setUserScroll: NO];		
		
    }    
	
	[pool release];
}

- (BOOL) sendInputToAllSessions
{
    return (sendInputToAllSessions);
}

- (void) setSendInputToAllSessions: (BOOL) flag
{
#if DEBUG_METHOD_TRACE
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
	
    sendInputToAllSessions = flag;
	if(flag)
		NSRunInformationalAlertPanel(NSLocalizedStringFromTableInBundle(@"Warning!",@"iTerm", [NSBundle bundleForClass: [self class]], @"Warning"),
									 NSLocalizedStringFromTableInBundle(@"Keyboard input will be sent to all sessions in this terminal.",@"iTerm", [NSBundle bundleForClass: [self class]], @"Keyboard Input"), 
									 NSLocalizedStringFromTableInBundle(@"OK",@"iTerm", [NSBundle bundleForClass: [self class]], @"Profile"), nil, nil);
	
}

- (IBAction) toggleInputToAllSessions: (id) sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal toggleInputToAllSessions:%@]",
		  __FILE__, __LINE__, sender);
#endif
	[self setSendInputToAllSessions: ![self sendInputToAllSessions]];
    
    // cause reloading of menus
    [[iTermController sharedInstance] setCurrentTerminal: self];
}

- (void) setFontSizeFollowWindowResize: (BOOL) flag
{
    fontSizeFollowWindowResize = flag;
}

- (IBAction) toggleFontSizeFollowWindowResize: (id) sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal toggleFontSizeFollowWindowResize:%@]",
		  __FILE__, __LINE__, sender);
#endif
    fontSizeFollowWindowResize = !fontSizeFollowWindowResize;
    
    // cause reloading of menus
    [[iTermController sharedInstance] setCurrentTerminal: self];
}

- (BOOL) fontSizeFollowWindowResize
{
    return (fontSizeFollowWindowResize);
}


// NSWindow delegate methods
- (void)windowDidDeminiaturize:(NSNotification *)aNotification
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal windowDidDeminiaturize:%@]",
		  __FILE__, __LINE__, aNotification);
#endif
}

- (BOOL)windowShouldClose:(NSNotification *)aNotification
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal windowShouldClose:%@]",
		  __FILE__, __LINE__, aNotification);
#endif
	
    if([[PreferencePanel sharedInstance] promptOnClose])
		return [self showCloseWindow];
    else
		return (YES);
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    int i,sessionCount;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal windowWillClose:%@]",
		  __FILE__, __LINE__, aNotification);
#endif
	EXIT = YES;
    sessionCount = [_sessionMgr numberOfSessions];
    for (i = 0; i < sessionCount; i++)
    {
        if ([[_sessionMgr sessionAtIndex: i] exited]==NO)
            [[_sessionMgr sessionAtIndex: i] terminate];
    }
	
    //[self releaseObjects];
	
    // Release our window postion
    for (i = 0; i < CACHED_WINDOW_POSITIONS; i++)
    {
		if(windowPositions[i] == (unsigned int) self)
		{
			windowPositions[i] = 0;
			break;
		}
    }
	
    [[iTermController sharedInstance] terminalWillClose: self];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal windowDidBecomeKey:%@]",
		  __FILE__, __LINE__, aNotification);
#endif
	
    [self selectSessionAtIndex: [self currentSessionIndex]];
    
    [[iTermController sharedInstance] setCurrentTerminal: self];
	
    // update the cursor
    [[[_sessionMgr currentSession] TEXTVIEW] setNeedsDisplay: YES];
}

- (void) windowDidResignKey: (NSNotification *)aNotification
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal windowDidResignKey:%@]",
		  __FILE__, __LINE__, aNotification);
#endif
	
    [self windowDidResignMain: aNotification];
	
    // update the cursor
    [[[_sessionMgr currentSession] TEXTVIEW] setNeedsDisplay: YES];
	
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal windowDidResignMain:%@]",
		  __FILE__, __LINE__, aNotification);
#endif
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal windowWillResize: proposedFrameSize width = %f; height = %f]",
		  __FILE__, __LINE__, proposedFrameSize.width, proposedFrameSize.height);
#endif

	if (fontSizeFollowWindowResize) {
		//scale = defaultFrame.size.height / [sender frame].size.height;
		float nch = [sender frame].size.height - [[[self currentSession] SCROLLVIEW] frame].size.height;
		float scale = (proposedFrameSize.height - nch) / HEIGHT / charHeight;
		NSFont *font = [[NSFontManager sharedFontManager] convertFont:FONT toSize:(int)(([FONT pointSize] * scale))];
		font = [self _getMaxFont:font height:proposedFrameSize.height - nch lines:HEIGHT];
		proposedFrameSize.height = [font defaultLineHeightForFont] * charVerticalSpacingMultiplier * HEIGHT + nch;
		//NSLog(@"actual height: %f\t scale: %f\t new size:%f\told:%f",proposedFrameSize.height,scale, [font pointSize], [FONT pointSize]);
	}
	
    return (proposedFrameSize);
}

- (void)windowDidResize:(NSNotification *)aNotification
{
    NSRect frame;
    int i, w, h;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal windowDidResize: width = %f, height = %f]",
		  __FILE__, __LINE__, [[self window] frame].size.width, [[self window] frame].size.height);
#endif
		
	
    frame = [[[_sessionMgr currentSession] SCROLLVIEW] documentVisibleRect];
#if 0
    NSLog(@"scrollview content size %.1f, %.1f, %.1f, %.1f",
		  frame.origin.x, frame.origin.y,
		  frame.size.width, frame.size.height);
#endif
	if (fontSizeFollowWindowResize) {
		float scale = (frame.size.height) / HEIGHT / charHeight;
		NSFont *font = [[NSFontManager sharedFontManager] convertFont:FONT toSize:(int)(([FONT pointSize] * scale))];
		font = [self _getMaxFont:font height:frame.size.height lines:HEIGHT];
		
		float height = [font defaultLineHeightForFont] * charVerticalSpacingMultiplier;

		if (height != charHeight) {
			//NSLog(@"Old size: %f\t proposed New size:%f\tWindow Height: %f",[FONT pointSize], [font pointSize],frame.size.height);
			NSFont *nafont = [[NSFontManager sharedFontManager] convertFont:FONT toSize:(int)(([NAFONT pointSize] * scale))];
			nafont = [self _getMaxFont:nafont height:frame.size.height lines:HEIGHT];
			
			[self setFont:font nafont:nafont];
			//[self resizeWindow:WIDTH height:HEIGHT];
			NSString *aTitle = [NSString stringWithFormat:@"%@ (@%.0f)", [[_sessionMgr currentSession] name], [font pointSize]];
			[self setWindowTitle: aTitle];    
			//for(i=0;i<[_sessionMgr numberOfSessions]; i++) {
			//	[[[_sessionMgr sessionAtIndex:i] TEXTVIEW] setFrameSize:frame.size];		
			//}
			[self setWindowSize: YES];

		}
		w = (int)((frame.size.width - MARGIN * 2)/charWidth);
		h = (int)(frame.size.height/charHeight);
		if (w!=WIDTH || h!=HEIGHT) {
			for(i=0;i<[_sessionMgr numberOfSessions]; i++) {
				[[[_sessionMgr sessionAtIndex:i] SCREEN] resizeWidth:w height:h];
				[[[_sessionMgr sessionAtIndex:i] SHELL] setWidth:w  height:h];
			}
		}
	}
	else {	    
		w = (int)((frame.size.width - MARGIN * 2)/charWidth);
		h = (int)(frame.size.height/charHeight);

		for(i=0;i<[_sessionMgr numberOfSessions]; i++) {
			[[[_sessionMgr sessionAtIndex:i] SCREEN] resizeWidth:w height:h];
			[[[_sessionMgr sessionAtIndex:i] SHELL] setWidth:w  height:h];
		}
		
		WIDTH = w;
		HEIGHT = h;
		// Display the new size in the window title.
		NSString *aTitle = [NSString stringWithFormat:@"%@ (%d,%d)", [[_sessionMgr currentSession] name], WIDTH, HEIGHT];
		[self setWindowTitle: aTitle];    
	}	
	// Reset the scrollbar to the bottom
    [[[_sessionMgr currentSession] TEXTVIEW] scrollEnd];
	
	// Post a notification
    [[NSNotificationCenter defaultCenter] postNotificationName: @"iTermWindowDidResize" object: self userInfo: nil];    
	
}

// PTYWindowDelegateProtocol
- (void) windowWillToggleToolbarVisibility: (id) sender
{
}

- (void) windowDidToggleToolbarVisibility: (id) sender
{
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal windowWillUseStandardFrame: defaultFramewidth = %f, height = %f]",
		  __FILE__, __LINE__, defaultFrame.size.width, defaultFrame.size.height);
#endif
	float height, width, scale;
	
	if (fontSizeFollowWindowResize) {
		float nch = [sender frame].size.height - [[[self currentSession] SCROLLVIEW] frame].size.height;
		scale = (defaultFrame.size.height - nch) / HEIGHT / charHeight;
		NSFont *font = [[NSFontManager sharedFontManager] convertFont:FONT toSize:(int)(([FONT pointSize] * scale))];
		font = [self _getMaxFont:font height:defaultFrame.size.height - nch lines:HEIGHT];
		NSMutableDictionary *dic = [NSMutableDictionary dictionary];
		NSSize sz;
		[dic setObject:font forKey:NSFontAttributeName];
		sz = [@"W" sizeWithAttributes:dic];
		
		
		height = [font defaultLineHeightForFont] * charVerticalSpacingMultiplier * HEIGHT + nch;
		width = sz.width * charHorizontalSpacingMultiplier * WIDTH;
		NSLog(@"proposed height: %f\t actual height: %f\t (nch=%f) scale: %f\t new font:%f\told:%f",defaultFrame.size.height,height,nch,scale, [font pointSize], [FONT pointSize]);
		defaultFrame.size.height = height;
		defaultFrame.size.width = width;
	}
	else {
		width = [sender frame].size.width;
		height = defaultFrame.size.height;
	}
	
	return [[PreferencePanel sharedInstance] maxVertically] ? 
		  NSMakeRect([sender frame].origin.x, defaultFrame.origin.y, width, height)
	     :defaultFrame;
}
	
// Close Window
- (BOOL)showCloseWindow
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal showCloseWindow]", __FILE__, __LINE__);
#endif
	
    return (NSRunAlertPanel(NSLocalizedStringFromTableInBundle(@"Close Window?",@"iTerm", [NSBundle bundleForClass: [self class]], @"Close window"),
                            NSLocalizedStringFromTableInBundle(@"All sessions will be closed",@"iTerm", [NSBundle bundleForClass: [self class]], @"Close window"),
							NSLocalizedStringFromTableInBundle(@"OK",@"iTerm", [NSBundle bundleForClass: [self class]], @"OK"),
                            NSLocalizedStringFromTableInBundle(@"Cancel",@"iTerm", [NSBundle bundleForClass: [self class]], @"Cancel")
							,nil)==1);
}

- (IBAction)showConfigWindow:(id)sender;
{
    [ITConfigPanelController show];
}

- (void) resizeWindow:(int) w height:(int)h
{
    int i;
    NSSize vsize;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal resizeWindow:%d,%d]",
          __FILE__, __LINE__, w, h);
#endif
    
    vsize.width = charWidth * w + MARGIN *2;
	vsize.height = charHeight * h;
    
    for(i=0;i<[_sessionMgr numberOfSessions]; i++) {
        [[[_sessionMgr sessionAtIndex:i] SCREEN] resizeWidth:w height:h];
        [[[_sessionMgr sessionAtIndex:i] SHELL] setWidth:w height:h];
        [[[_sessionMgr sessionAtIndex:i] TEXTVIEW] setFrameSize:vsize];
    }
    WIDTH=w;
    HEIGHT=h;
	
    [self setWindowSize: YES];
}

// Contextual menu
- (BOOL) suppressContextualMenu
{
	return (suppressContextualMenu);
}

- (void) setSuppressContextualMenu: (BOOL) aBool
{
	suppressContextualMenu = aBool;
}

- (void) menuForEvent:(NSEvent *)theEvent menu: (NSMenu *) theMenu
{
    unsigned int modflag = 0;
    BOOL newWin;
    int nextIndex;
	NSMenu *abMenu;
    NSMenuItem *aMenuItem;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal menuForEvent]", __FILE__, __LINE__);
#endif
	
    if(theMenu == nil || suppressContextualMenu)
		return;
	
    modflag = [theEvent modifierFlags];
	
    // Bookmarks
    // Figure out whether the command shall be executed in a new window or tab
    if (modflag & NSCommandKeyMask)
    {
		[theMenu insertItemWithTitle: NSLocalizedStringFromTableInBundle(@"New Window",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu") action:nil keyEquivalent:@"" atIndex: 0];
		newWin = YES;
    }
    else
    {
		[theMenu insertItemWithTitle: NSLocalizedStringFromTableInBundle(@"New Tab",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu") action:nil keyEquivalent:@"" atIndex: 0];
		newWin = NO;
    }
    nextIndex = 1;
	
    // Create a menu with a submenu to navigate between tabs if there are more than one
    if([TABVIEW numberOfTabViewItems] > 1)
    {	
		[theMenu insertItemWithTitle: NSLocalizedStringFromTableInBundle(@"Select",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu") action:nil keyEquivalent:@"" atIndex: nextIndex];
		
		NSMenu *tabMenu = [[NSMenu alloc] initWithTitle:@""];
		int i;
		
		for (i = 0; i < [TABVIEW numberOfTabViewItems]; i++)
		{
			aMenuItem = [[NSMenuItem alloc] initWithTitle:[[TABVIEW tabViewItemAtIndex: i] label]
												   action:@selector(selectTab:) keyEquivalent:@""];
			[aMenuItem setRepresentedObject: [[TABVIEW tabViewItemAtIndex: i] identifier]];
			[aMenuItem setTarget: TABVIEW];
			[tabMenu addItem: aMenuItem];
			[aMenuItem release];
		}
		[theMenu setSubmenu: tabMenu forItem: [theMenu itemAtIndex: nextIndex]];
		[tabMenu release];
		nextIndex++;
    }
	
	// Bookmarks
	[theMenu insertItemWithTitle: 
		NSLocalizedStringFromTableInBundle(@"Bookmarks",@"iTerm", [NSBundle bundleForClass: [self class]], @"Bookmarks") 
						  action:@selector(toggleBookmarksView:) keyEquivalent:@"" atIndex: nextIndex++];
    
    // Separator
    [theMenu insertItem:[NSMenuItem separatorItem] atIndex: nextIndex];
	
    // Build the bookmarks menu
    abMenu = [[iTermController sharedInstance] buildAddressBookMenuWithTarget: (newWin?nil:self) withShortcuts: NO];
	
    [theMenu setSubmenu: abMenu forItem: [theMenu itemAtIndex: 0]];
	
    // Separator
    [theMenu addItem:[NSMenuItem separatorItem]];
	
    // Close current session
    aMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Close",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu") action:@selector(closeCurrentSession:) keyEquivalent:@""];
    [aMenuItem setTarget: self];
    [theMenu addItem: aMenuItem];
    [aMenuItem release];
	
    // Configure
    aMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Configure...",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu") action:@selector(showConfigWindow:) keyEquivalent:@""];
    [aMenuItem setTarget: self];
    [theMenu addItem: aMenuItem];
    [aMenuItem release];
}

// NSTabView
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    PTYSession *aSession;
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal tabView: willSelectTabViewItem]", __FILE__, __LINE__);
#endif
    
    aSession = [tabViewItem identifier];
    
    if ([_sessionMgr currentSession]) 
        [[_sessionMgr currentSession] resetStatus];
    
    [_sessionMgr setCurrentSession:aSession];
    
    [self setWindowTitle];
    [[TABVIEW window] makeFirstResponder:[[_sessionMgr currentSession] TEXTVIEW]];
    [[TABVIEW window] setNextResponder:self];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal tabView: didSelectTabViewItem]", __FILE__, __LINE__);
#endif
    
    [[_sessionMgr currentSession] setLabelAttribute];
	[[[_sessionMgr currentSession] SCREEN] setDirty];
	[[[_sessionMgr currentSession] TEXTVIEW] setNeedsDisplay: YES];
	// do this to set up mouse tracking rects again
	[[[_sessionMgr currentSession] TEXTVIEW] becomeFirstResponder];
	
	// Post a notification
    [[NSNotificationCenter defaultCenter] postNotificationName: @"iTermSessionBecameKey" object: self userInfo: nil];    
}

- (void)tabView:(NSTabView *)tabView willRemoveTabViewItem:(NSTabViewItem *)tabViewItem
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal tabView: willRemoveTabViewItem]", __FILE__, __LINE__);
#endif
    PTYSession *aSession = [tabViewItem identifier];
	
    if([_sessionMgr containsSession: aSession] && [aSession isKindOfClass: [PTYSession class]])
		[_sessionMgr removeSession: aSession];
}

- (void)tabView:(NSTabView *)tabView willAddTabViewItem:(NSTabViewItem *)tabViewItem
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal tabView: willAddTabViewItem]", __FILE__, __LINE__);
#endif
	
    [self tabView: tabView willInsertTabViewItem: tabViewItem atIndex: [tabView numberOfTabViewItems]];
}

- (void)tabView:(NSTabView *)tabView willInsertTabViewItem:(NSTabViewItem *)tabViewItem atIndex: (int) index
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal tabView: willInsertTabViewItem: atIndex: %d]", __FILE__, __LINE__, index);
#endif
	
    if(tabView == nil || tabViewItem == nil || index < 0)
		return;
    
    PTYSession *aSession = [tabViewItem identifier];
	
    if(![_sessionMgr containsSession: aSession] && [aSession isKindOfClass: [PTYSession class]])
    {
		[aSession setParent: self];
		
        [_sessionMgr insertSession: aSession atIndex: index];
    }
	
    if([TABVIEW numberOfTabViewItems] == 1)
    {
		[TABVIEW setTabViewType: [[PreferencePanel sharedInstance] tabViewType]];
		[self setWindowSize: NO];
    }    
}

- (void)tabViewWillPerformDragOperation:(NSTabView *)tabView
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal tabViewWillPerformDragOperation]", __FILE__, __LINE__);
#endif
	
    tabViewDragOperationInProgress = YES;
}

- (void)tabViewDidPerformDragOperation:(NSTabView *)tabView
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal tabViewDidPerformDragOperation]", __FILE__, __LINE__);
#endif
	
    tabViewDragOperationInProgress = NO;
    [self tabViewDidChangeNumberOfTabViewItems: tabView];
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal tabViewDidChangeNumberOfTabViewItems]", __FILE__, __LINE__);
#endif
	
    if(tabViewDragOperationInProgress == YES)
		return;
    
    [_sessionMgr setCurrentSessionIndex:[TABVIEW indexOfTabViewItem: [TABVIEW selectedTabViewItem]]];
	
    if ([TABVIEW numberOfTabViewItems] == 1)
    {
		if([[PreferencePanel sharedInstance] hideTab])
		{
            PTYSession *aSession = [[TABVIEW tabViewItemAtIndex: 0] identifier];
			
            [TABVIEW setTabViewType: NSNoTabsBezelBorder];
			[self setWindowSize: NO];
            [[aSession TEXTVIEW] scrollEnd];
            // make sure the display is up-to-date.
            [[aSession TEXTVIEW] setForceUpdate: YES];
            
		}
		else
		{
			[TABVIEW setTabViewType: [[PreferencePanel sharedInstance] tabViewType]];
			[self setWindowSize: NO];
		}
		
    }
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"iTermNumberOfSessionsDidChange" object: self userInfo: nil];		
    
}

- (void)tabViewContextualMenu: (NSEvent *)theEvent menu: (NSMenu *)theMenu
{
    NSMenuItem *aMenuItem;
    NSPoint windowPoint, localPoint;
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal tabViewContextualMenu]", __FILE__, __LINE__);
#endif    
	
    if((theEvent == nil) || (theMenu == nil))
		return;
	
    windowPoint = [[TABVIEW window] convertScreenToBase: [NSEvent mouseLocation]];
    localPoint = [TABVIEW convertPoint: windowPoint fromView: nil];
	
    if([TABVIEW tabViewItemAtPoint:localPoint] == nil)
		return;
	
    [theMenu addItem: [NSMenuItem separatorItem]];
	
    // add tasks
    aMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Close",@"iTerm", [NSBundle bundleForClass: [self class]], @"Close Session") action:@selector(closeTabContextualMenuAction:) keyEquivalent:@""];
    [aMenuItem setRepresentedObject: [[TABVIEW tabViewItemAtPoint:localPoint] identifier]];
    [theMenu addItem: aMenuItem];
    [aMenuItem release];
    if([_sessionMgr numberOfSessions] > 1)
    {
		aMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Move to new window",@"iTerm", [NSBundle bundleForClass: [self class]], @"Move session to new window") action:@selector(moveTabToNewWindowContextualMenuAction:) keyEquivalent:@""];
		[aMenuItem setRepresentedObject: [[TABVIEW tabViewItemAtPoint:localPoint] identifier]];
		[theMenu addItem: aMenuItem];
		[aMenuItem release];
    }
}

// closes a tab
- (void) closeTabContextualMenuAction: (id) sender
{
    [self closeSession: [sender representedObject]];
}

// moves a tab with its session to a new window
- (void) moveTabToNewWindowContextualMenuAction: (id) sender
{
    PseudoTerminal *term;
    PTYSession *aSession;
    PTYTabViewItem *aTabViewItem;
	
    // grab the referenced session
    aSession = [sender representedObject];
    if(aSession == nil)
		return;
	
    // create a new terminal window
    term = [[PseudoTerminal alloc] init];
    if(term == nil)
		return;
	
	if([term windowInited] == NO)
    {
		[term setWidth: WIDTH height: HEIGHT];
		[term setFont: FONT nafont: NAFONT];
		[term initWindow];
    }	
	
    [[iTermController sharedInstance] addInTerminals: term];
	[term release];
	
	
    // If this is the current session, make previous one active.
    if(aSession == [_sessionMgr currentSession])
		[self selectSessionAtIndex: ([_sessionMgr currentSessionIndex] - 1)];
	
    aTabViewItem = [aSession tabViewItem];
	
    // temporarily retain the tabViewItem
    [aTabViewItem retain];
	
    // remove from our window
    [TABVIEW removeTabViewItem: aTabViewItem];
	
    // add the session to the new terminal
    [term insertSession: aSession atIndex: 0];
	
    // release the tabViewItem
    [aTabViewItem release];
}

- (IBAction)closeWindow:(id)sender
{
    [[self window] performClose:sender];
}

- (IBAction) saveDisplayProfile: (id) sender
{
	iTermDisplayProfileMgr *displayProfileMgr;
	NSDictionary *aDict;
	NSString *displayProfile;
	PTYSession *current;
	
	current = [self currentSession];
	displayProfileMgr = [iTermDisplayProfileMgr singleInstance];
	aDict = [current addressBookEntry];
	displayProfile = [aDict objectForKey: KEY_DISPLAY_PROFILE];
	if(displayProfile == nil)
		displayProfile = [displayProfileMgr defaultProfileName];	
	
	[displayProfileMgr setTransparency: [current transparency] forProfile: displayProfile];
	[displayProfileMgr setDisableBold: [current disableBold] forProfile: displayProfile];
	[displayProfileMgr setBackgroundImage: [current backgroundImagePath] forProfile: displayProfile];
	[displayProfileMgr setWindowColumns: [self columns] forProfile: displayProfile];
	[displayProfileMgr setWindowRows: [self rows] forProfile: displayProfile];
	[displayProfileMgr setWindowFont: [self font] forProfile: displayProfile];
	[displayProfileMgr setWindowNAFont: [self nafont] forProfile: displayProfile];
	[displayProfileMgr setWindowHorizontalCharSpacing: charHorizontalSpacingMultiplier forProfile: displayProfile];
	[displayProfileMgr setWindowVerticalCharSpacing: charVerticalSpacingMultiplier forProfile: displayProfile];
	[displayProfileMgr setWindowAntiAlias: [[current TEXTVIEW] antiAlias] forProfile: displayProfile];
	[displayProfileMgr setColor: [current foregroundColor] forType: TYPE_FOREGROUND_COLOR forProfile: displayProfile];
	[displayProfileMgr setColor: [current backgroundColor] forType: TYPE_BACKGROUND_COLOR forProfile: displayProfile];
	[displayProfileMgr setColor: [current boldColor] forType: TYPE_BOLD_COLOR forProfile: displayProfile];
	[displayProfileMgr setColor: [current selectionColor] forType: TYPE_SELECTION_COLOR forProfile: displayProfile];
	[displayProfileMgr setColor: [current selectedTextColor] forType: TYPE_SELECTED_TEXT_COLOR forProfile: displayProfile];
	[displayProfileMgr setColor: [current cursorColor] forType: TYPE_CURSOR_COLOR forProfile: displayProfile];
	[displayProfileMgr setColor: [current cursorTextColor] forType: TYPE_CURSOR_TEXT_COLOR forProfile: displayProfile];
		
	NSRunInformationalAlertPanel([NSString stringWithFormat: NSLocalizedStringFromTableInBundle(@"Display Profile Saved To: %@",@"iTerm", [NSBundle bundleForClass: [self class]], @"Profile"), displayProfile],
								 NSLocalizedStringFromTableInBundle(@"All bookmarks associated with this profile are affected",@"iTerm", [NSBundle bundleForClass: [self class]], @"Profile"), 
								 NSLocalizedStringFromTableInBundle(@"OK",@"iTerm", [NSBundle bundleForClass: [self class]], @"Profile"), nil, nil);
}

- (IBAction) saveTerminalProfile: (id) sender
{
	iTermTerminalProfileMgr *terminalProfileMgr;
	NSDictionary *aDict;
	NSString *terminalProfile;
	PTYSession *current;
	
	current = [self currentSession];
	terminalProfileMgr = [iTermTerminalProfileMgr singleInstance];
	aDict = [current addressBookEntry];
	terminalProfile = [aDict objectForKey: KEY_TERMINAL_PROFILE];
	if(terminalProfile == nil)
		terminalProfile = [terminalProfileMgr defaultProfileName];	

	[terminalProfileMgr setEncoding: [current encoding] forProfile: terminalProfile];
	[terminalProfileMgr setSendIdleChar: [current antiIdle] forProfile: terminalProfile];
	[terminalProfileMgr setIdleChar: [current antiCode] forProfile: terminalProfile];
	
	NSRunInformationalAlertPanel([NSString stringWithFormat: NSLocalizedStringFromTableInBundle(@"Terminal Profile Saved To: %@",@"iTerm", [NSBundle bundleForClass: [self class]], @"Profile"), terminalProfile],
								 NSLocalizedStringFromTableInBundle(@"All bookmarks associated with this profile are affected",@"iTerm", [NSBundle bundleForClass: [self class]], @"Profile"), 
								 NSLocalizedStringFromTableInBundle(@"OK",@"iTerm", [NSBundle bundleForClass: [self class]], @"Profile"), nil, nil);
}


// NSOutlineView delegate methods
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item
{
	return (NO);
}

// NSOutlineView doubleclick action
- (IBAction) doubleClickedOnBookmarksView: (id) sender
{
	int selectedRow = [bookmarksView selectedRow];
	TreeNode *selectedItem;
	
	if(selectedRow < 0)
		return;
	
	selectedItem = [bookmarksView itemAtRow: selectedRow];
	if(selectedItem != nil && [selectedItem isLeaf])
	{
		[[iTermController sharedInstance] launchBookmark: [selectedItem nodeData] inTerminal: self];
	}
	
}

// Bookmarks
- (IBAction) toggleBookmarksView: (id) sender
{
	float aWidth;
	
	// set the width of the bookmarks drawer based on saved value
	aWidth = [[NSUserDefaults standardUserDefaults] floatForKey: @"BookmarksDrawerWidth"];
	if(aWidth > 0 && [[(PTYWindow *)[self window] drawer] state] == NSDrawerClosedState)
		[[(PTYWindow *)[self window] drawer] setContentSize: NSMakeSize(aWidth, 0)];
	
	[[(PTYWindow *)[self window] drawer] toggle: sender];	
	// Post a notification
    [[NSNotificationCenter defaultCenter] postNotificationName: @"iTermWindowBecameKey" object: nil userInfo: nil];    
}

- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize
{
	// save the width to preferences
	[[NSUserDefaults standardUserDefaults] setFloat: contentSize.width forKey: @"BookmarksDrawerWidth"];
	
	return (contentSize);
}



@end

@implementation PseudoTerminal (Private)

- (void) _commonInit
{
	_sessionMgr = [[ITSessionMgr alloc] init];
	charHorizontalSpacingMultiplier = charVerticalSpacingMultiplier = 1.0;
	
    tabViewDragOperationInProgress = NO;
	
	[NSThread detachNewThreadSelector: @selector(_updateDisplayThread:) toTarget: self withObject: nil];
	
}

- (void) _updateDisplayThread: (void *) incoming
{
	NSAutoreleasePool *arPool = [[NSAutoreleasePool alloc] init];
	int i, n, iterationCount;
	NSAutoreleasePool *pool = nil;
	PTYSession *aSession;
	
	iterationCount = 0;
	while (EXIT == NO)
	{
		iterationCount++;
		
		// periodically create and release autorelease pools
		if(pool == nil)
			pool = [[NSAutoreleasePool alloc] init];
		
        if (iterationCount % 5 ==0) {
            n = [_sessionMgr numberOfSessions];
            for (i = 0; i < n; i++)
            {
                aSession = [_sessionMgr sessionAtIndex: i];
                [aSession updateDisplay];
            }
		}
        else {
            if ([[[[self currentSession] TEXTVIEW] window] isKeyWindow] || iterationCount % 3 ==0 ) 
                [[self currentSession] updateDisplay];
        }
		// periodically create and release autorelease pools
		if((iterationCount % 50) == 0)
		{
			[pool release];
			pool = nil;
			iterationCount = 0;
		}
			
		usleep(100000);
	}
	
	if(pool != nil)
	{
		[pool release];
		pool = nil;
	}
	
	[arPool release];
	[NSThread exit];
}

- (NSFont *) _getMaxFont:(NSFont* ) font 
				  height:(float) height
				   lines:(float) lines
{
	float newSize = [font pointSize], newHeight;
	NSFont *newfont=nil;
	
	do {
		newfont = font;
		font = [[NSFontManager sharedFontManager] convertFont:font toSize:newSize];
		newSize++;
		newHeight = [font defaultLineHeightForFont] * charVerticalSpacingMultiplier * lines;
	} while (height >= newHeight);
	
	return newfont;
}

- (void) _reloadAddressBook: (NSNotification *) aNotification
{
	[bookmarksView reloadData];
}

@end


@implementation PseudoTerminal (KeyValueCoding)

// accessors for attributes:
-(int)columns
{
    // NSLog(@"PseudoTerminal: -columns");
    return (WIDTH);
}

-(void)setColumns: (int)columns
{
    // NSLog(@"PseudoTerminal: setColumns: %d", columns);
    if(columns > 0)
    {
		WIDTH = columns;
		if([_sessionMgr numberOfSessions] > 0)
			[self setWindowSize: NO];
    }
}

-(int)rows
{
    // NSLog(@"PseudoTerminal: -rows");
    return (HEIGHT);
}

-(void)setRows: (int)rows
{
    // NSLog(@"PseudoTerminal: setRows: %d", rows);
    if(rows > 0)
    {
		HEIGHT = rows;
		if([_sessionMgr numberOfSessions] > 0)
			[self setWindowSize: NO];
    }
}

// accessors for to-many relationships:
-(NSArray*)sessions
{
    return [_sessionMgr sessionList];
}

-(void)setSessions: (NSArray*)sessions
{
    // no-op
}

// accessors for to-many relationships:
// (See NSScriptKeyValueCoding.h)
-(id)valueInSessionsAtIndex:(unsigned)index
{
    // NSLog(@"PseudoTerminal: -valueInSessionsAtIndex: %d", index);
    return ([_sessionMgr sessionAtIndex: index]);
}

-(id)valueWithName: (NSString *)uniqueName inPropertyWithKey: (NSString*)propertyKey
{
    id result = nil;
    int i;
	
    if([propertyKey isEqualToString: sessionsKey] == YES)
    {
		PTYSession *aSession;
		
		for (i= 0; i < [_sessionMgr numberOfSessions]; i++)
		{
			aSession = [_sessionMgr sessionAtIndex: i];
			if([[aSession name] isEqualToString: uniqueName] == YES)
				return (aSession);
		}
    }
	
    return result;
}

// The 'uniqueID' argument might be an NSString or an NSNumber.
-(id)valueWithID: (NSString *)uniqueID inPropertyWithKey: (NSString*)propertyKey
{
    id result = nil;
    int i;
	
    if([propertyKey isEqualToString: sessionsKey] == YES)
    {
		PTYSession *aSession;
		
		for (i= 0; i < [_sessionMgr numberOfSessions]; i++)
		{
			aSession = [_sessionMgr sessionAtIndex: i];
			if([[aSession tty] isEqualToString: uniqueID] == YES)
				return (aSession);
		}
    }
    
    return result;
}

-(void)replaceInSessions:(PTYSession *)object atIndex:(unsigned)index
{
    // NSLog(@"PseudoTerminal: -replaceInSessions: 0x%x atIndex: %d", object, index);
    [_sessionMgr replaceSessionAtIndex: index withSession: object];
}

-(void)addInSessions:(PTYSession *)object
{
    // NSLog(@"PseudoTerminal: -addInSessions: 0x%x", object);
    [self insertInSessions: object];
}

-(void)insertInSessions:(PTYSession *)object
{
    // NSLog(@"PseudoTerminal: -insertInSessions: 0x%x", object);
    [self insertInSessions: object atIndex:[_sessionMgr numberOfSessions]];
}

-(void)insertInSessions:(PTYSession *)object atIndex:(unsigned)index
{
    // NSLog(@"PseudoTerminal: -insertInSessions: 0x%x atIndex: %d", object, index);
    [self setupSession: object title: nil];
    [self insertSession: object atIndex: index];
}

-(void)removeFromSessionsAtIndex:(unsigned)index
{
    // NSLog(@"PseudoTerminal: -removeFromSessionsAtIndex: %d", index);
    if(index < [_sessionMgr numberOfSessions])
    {
		PTYSession *aSession = [_sessionMgr sessionAtIndex: index];
		[self closeSession: aSession];
    }
}

- (BOOL)windowInited
{
    return (windowInited);
}

- (void) setWindowInited: (BOOL) flag
{
    windowInited = flag;
}

// a class method to provide the keys for KVC:
+(NSArray*)kvcKeys
{
    static NSArray *_kvcKeys = nil;
    if( nil == _kvcKeys ){
		_kvcKeys = [[NSArray alloc] initWithObjects:
			columnsKey, rowsKey, sessionsKey,  nil ];
    }
    return _kvcKeys;
}

@end

#ifndef GNUSTEP
@implementation PseudoTerminal (ScriptingSupport)

// Object specifier
- (NSScriptObjectSpecifier *)objectSpecifier
{
    unsigned index = 0;
    id classDescription = nil;
    
    NSScriptObjectSpecifier *containerRef;
    
    NSArray *terminals = [[iTermController sharedInstance] terminals];
    index = [terminals indexOfObjectIdenticalTo:self];
    if (index != NSNotFound) {
        containerRef     = [NSApp objectSpecifier];
        classDescription = [NSClassDescription classDescriptionForClass:[NSApp class]];
        //create and return the specifier
        return [[[NSIndexSpecifier allocWithZone:[self zone]]
               initWithContainerClassDescription: classDescription
                              containerSpecifier: containerRef
                                             key: @ "terminals"
                                           index: index] autorelease];
    } 
    else
        return nil;
}

// Handlers for supported commands:

-(void)handleSelectScriptCommand: (NSScriptCommand *)command
{
    [[iTermController sharedInstance] setCurrentTerminal: self];
}

-(void)handleLaunchScriptCommand: (NSScriptCommand *)command
{
    // Get the command's arguments:
    NSDictionary *args = [command evaluatedArguments];
    NSString *session = [args objectForKey:@"session"];
    NSDictionary *abEntry;
	NSString *displayProfile;
	iTermDisplayProfileMgr *displayProfileMgr;

	abEntry = [[ITAddressBookMgr sharedInstance] dataForBookmarkWithName: session];
	if(abEntry == nil)
		abEntry = [[ITAddressBookMgr sharedInstance] defaultBookmarkData];
    	
	displayProfileMgr = [iTermDisplayProfileMgr singleInstance];
	displayProfile = [abEntry objectForKey: KEY_DISPLAY_PROFILE];
    // If we have not set up a window, do it now
    if([self windowInited] == NO)
    {
		[self setWidth: [displayProfileMgr windowColumnsForProfile: displayProfile] 
				height: [displayProfileMgr windowRowsForProfile: displayProfile]];
		[self setFont: [displayProfileMgr windowFontForProfile: displayProfile] 
			   nafont: [displayProfileMgr windowNAFontForProfile: displayProfile]];
		[self initWindow];
    }
	
    // launch the session!
    [[iTermController sharedInstance] launchBookmark: abEntry inTerminal: self];
    
    return;
}

@end
#endif (GNUSTEP)
