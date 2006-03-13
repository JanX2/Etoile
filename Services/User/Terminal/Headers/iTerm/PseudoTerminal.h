// -*- mode:objc -*-
// $Id: PseudoTerminal.h,v 1.29 2006/02/02 00:11:46 yfabian Exp $
/*
 **  PseudoTerminal.h
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

#import <Cocoa/Cocoa.h>
#import <iTerm/PTYTabView.h>
#import <iTerm/PTYWindow.h>

@class ITSessionMgr, PTYSession, iTermController, PTToolbarController;

@interface PseudoTerminal : NSWindowController <PTYTabViewDelegateProtocol, PTYWindowDelegateProtocol>
{
	IBOutlet NSOutlineView *bookmarksView;
    /// tab view
    PTYTabView *TABVIEW;
    PTToolbarController* _toolbarController;

    ITSessionMgr* _sessionMgr;
    
    /////////////////////////////////////////////////////////////////////////
    int WIDTH,HEIGHT;
	int charWidth;
	int charHeight;
	float charHorizontalSpacingMultiplier, charVerticalSpacingMultiplier;
    NSFont *FONT, *NAFONT;
	BOOL antiAlias;
    //float alpha;
    BOOL tabViewDragOperationInProgress;
    BOOL windowInited;
	BOOL sendInputToAllSessions;
	BOOL fontSizeFollowWindowResize;
	BOOL suppressContextualMenu;
	
	BOOL EXIT;
}

+ (NSSize) viewSizeForColumns: (int) columns andRows: (int) rows withFont: (NSFont *) aFont;

- (id)init;
- (id) initWithWindowNibName: (NSString *) windowNibName;
- (PTYTabView*) initViewWithFrame: (NSRect) frame;
- (void)dealloc;
- (void)releaseObjects;

- (void)initWindow;
- (void)setupSession: (PTYSession *) aSession title: (NSString *)title;
- (void) insertSession: (PTYSession *) aSession atIndex: (int) index;
- (void) switchSession: (id) sender;
- (void) selectSessionAtIndex: (int) sessionIndex;
- (void) closeSession: (PTYSession*) aSession;
- (IBAction) closeCurrentSession: (id) sender;
- (IBAction) previousSession:(id)sender;
- (IBAction) nextSession:(id)sender;
- (PTYSession *) currentSession;
- (void) setCurrentSession: (PTYSession *) aSession;
- (int) currentSessionIndex;
- (NSString *) currentSessionName;
- (void) setCurrentSessionName: (NSString *) theSessionName;

- (void)startProgram:(NSString *)program;
- (void)startProgram:(NSString *)program
           arguments:(NSArray *)prog_argv;
- (void)startProgram:(NSString *)program
                  arguments:(NSArray *)prog_argv
                environment:(NSDictionary *)prog_env;
- (void)setWindowSize: (BOOL) resizeContentFrames;
- (void)setWindowTitle;
- (void)setWindowTitle: (NSString *)title;
- (void)setFont:(NSFont *)font nafont:(NSFont *)nafont;
- (void) setCharacterSpacingHorizontal: (float) horizontal vertical: (float) vertical;
- (void) changeFontSize: (BOOL) increase;
- (float) largerSizeForSize: (float) aSize;
- (float) smallerSizeForSize: (float) aSize;
- (NSFont *) font;
- (NSFont *) nafont;
- (BOOL) antiAlias;
- (void) setAntiAlias: (BOOL) bAntiAlias;
- (int)width;
- (int)height;
- (void)setWidth:(int)width height:(int)height;
- (void)setCharSizeUsingFont: (NSFont *)font;
- (int)charWidth;
- (int)charHeight;
- (float) charSpacingVertical;
- (float) charSpacingHorizontal;

- (ITSessionMgr*)sessionMgr;

// controls which sessions see key events
- (BOOL) sendInputToAllSessions;
- (void) setSendInputToAllSessions: (BOOL) flag;
- (IBAction) toggleInputToAllSessions: (id) sender;
- (void) sendInputToAllSessions: (NSData *) data;

// controls resize behavior
- (BOOL) fontSizeFollowWindowResize;
- (void) setFontSizeFollowWindowResize: (BOOL) flag;
- (IBAction) toggleFontSizeFollowWindowResize: (id) sender;

// iTermController
- (void)clearBuffer:(id)sender;
- (void)clearScrollbackBuffer:(id)sender;
- (IBAction)logStart:(id)sender;
- (IBAction)logStop:(id)sender;
- (BOOL)validateMenuItem:(NSMenuItem *)item;

// NSWindow
- (void)windowDidDeminiaturize:(NSNotification *)aNotification;
- (BOOL)windowShouldClose:(NSNotification *)aNotification;
- (void)windowWillClose:(NSNotification *)aNotification;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidResignMain:(NSNotification *)aNotification;
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize;
- (void)windowDidResize:(NSNotification *)aNotification;
- (void) resizeWindow:(int) w height:(int)h;
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame;

// Contextual menu
- (void) menuForEvent:(NSEvent *)theEvent menu: (NSMenu *) theMenu;
- (BOOL) suppressContextualMenu;
- (void) setSuppressContextualMenu: (BOOL) aBool;

// Close Window
- (BOOL)showCloseWindow;

// NSTabView
- (void) closeTabContextualMenuAction: (id) sender;
- (void) moveTabToNewWindowContextualMenuAction: (id) sender;

// Profiles
- (IBAction) saveDisplayProfile: (id) sender;
- (IBAction) saveTerminalProfile: (id) sender;

// Bookmarks
- (IBAction) toggleBookmarksView: (id) sender;

@end

@interface PseudoTerminal (KeyValueCoding)

// accessors for attributes:
-(int)columns;
-(void)setColumns: (int)columns;
-(int)rows;
-(void)setRows: (int)rows;

// accessors for to-many relationships:
-(NSArray*)sessions;
-(void)setSessions: (NSArray*)sessions;

// accessors for to-many relationships:
// (See NSScriptKeyValueCoding.h)
-(id)valueInSessionsAtIndex:(unsigned)index;
-(id)valueWithName: (NSString *)uniqueName inPropertyWithKey: (NSString*)propertyKey;
-(id)valueWithID: (NSString *)uniqueID inPropertyWithKey: (NSString*)propertyKey;
-(void)replaceInSessions:(PTYSession *)object atIndex:(unsigned)index;
-(void)addInSessions:(PTYSession *)object;
-(void)insertInSessions:(PTYSession *)object;
-(void)insertInSessions:(PTYSession *)object atIndex:(unsigned)index;
-(void)removeFromSessionsAtIndex:(unsigned)index;

- (BOOL)windowInited;
- (void) setWindowInited: (BOOL) flag;

// a class method to provide the keys for KVC:
+(NSArray*)kvcKeys;

@end

@interface PseudoTerminal (Private)

- (void) _commonInit;
- (void) _updateDisplayThread: (void *) incoming;

- (NSFont *) _getMaxFont:(NSFont* ) font 
				  height:(float) height
				   lines:(float) lines;

@end

#ifndef GNUSTEP
@interface PseudoTerminal (ScriptingSupport)

// Object specifier
- (NSScriptObjectSpecifier *)objectSpecifier;

-(void)handleSelectScriptCommand: (NSScriptCommand *)command;

-(void)handleLaunchScriptCommand: (NSScriptCommand *)command;

@end
#endif (GNUSTEP)
