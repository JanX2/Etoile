/*
 **  PTYSession.h
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian, Ujwal S. Setlur
 **
 **  Project: iTerm
 **
 **  Description: Implements the model class for a terminal session.
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <sys/time.h>

@class PTYTask;
@class PTYTextView;
@class PTYScrollView;
@class VT100Screen;
@class VT100Terminal;
@class PreferencePanel;
@class PseudoTerminal;
@class iTermController;
@class PTYTabViewItem;


@interface PTYSession : NSResponder
{        
    // Owning tab view item
    PTYTabViewItem *tabViewItem;

    // tty device
    NSString *tty;
    
    // tab label attributes
    NSDictionary *normalStateAttribute;
    NSDictionary *chosenStateAttribute;
    NSDictionary *idleStateAttribute;
    NSDictionary *newOutputStateAttribute;
    NSDictionary *deadStateAttribute;
    
    PseudoTerminal *parent;  // parent controller
    NSString *name;
    NSString *windowTitle;
	
	// semaphore to coordinate data read from task
#if defined(__APPLE__)
	MPSemaphoreID	dataSemaphore;
#else
    pthread_mutex_t dataSemaphore; // sem_t on Linux
#endif

    // anti-idle
    char ai_code;

    PTYTask *SHELL;
    VT100Terminal *TERMINAL;
    NSString *TERM_VALUE;
    VT100Screen   *SCREEN;
    BOOL EXIT;
    NSView *view;
    PTYScrollView *SCROLLVIEW;
    PTYTextView *TEXTVIEW;
    
    struct timeval lastInput, lastOutput, lastBlink;
   
    BOOL REFRESHED;
    BOOL antiIdle;
    BOOL waiting;
    BOOL autoClose;
    BOOL doubleWidth;
	BOOL xtermMouseReporting;
    NSString *backgroundImagePath;
    //NSFont *configFont;
    NSDictionary *addressBookEntry;
}

// init/dealloc
- (id) init;
- (void) dealloc;

// Session specific methods
- (void)initScreen: (NSRect) aRect width:(int)width height:(int) height;
- (void)startProgram:(NSString *)program
	   arguments:(NSArray *)prog_argv
	 environment:(NSDictionary *)prog_env;
- (void) terminate;
- (BOOL) isActiveSession;

// Preferences
- (void) setPreferencesFromAddressBookEntry: (NSDictionary *) aePrefs;

// PTYTask
- (void)writeTask:(NSData *)data;
- (void)readTask:(char *)buf length:(int)length;
- (void)brokenPipe;

// PTYTextView
- (BOOL) hasKeyMappingForEvent: (NSEvent *) event;
- (void)keyDown:(NSEvent *)event;
- (BOOL)willHandleEvent: (NSEvent *) theEvent;
- (void)handleEvent: (NSEvent *) theEvent;
- (void)insertText:(NSString *)string;
- (void)insertNewline:(id)sender;
- (void)insertTab:(id)sender;
- (void)moveUp:(id)sender;
- (void)moveDown:(id)sender;
- (void)moveLeft:(id)sender;
- (void)moveRight:(id)sender;
- (void)pageUp:(id)sender;
- (void)pageDown:(id)sender;
- (void)paste:(id)sender;
- (void)pasteString: (NSString *) aString;
- (void)deleteBackward:(id)sender;
- (void)deleteForward:(id)sender;
- (void)textViewDidChangeSelection: (NSNotification *) aNotification;
- (void)textViewResized: (NSNotification *) aNotification;
- (void)tabViewWillRedraw: (NSNotification *) aNotification;


// misc
- (void) handleOptionClick: (NSEvent *) theEvent;
- (void) doIdleTasks;


// Contextual menu
- (void) menuForEvent:(NSEvent *)theEvent menu: (NSMenu *) theMenu;


// get/set methods
- (PseudoTerminal *) parent;
- (void) setParent: (PseudoTerminal *) theParent;
- (PTYTabViewItem *) tabViewItem;
- (void) setTabViewItem: (PTYTabViewItem *) theTabViewItem;
- (NSString *) name;
- (void) setName: (NSString *) theName;
- (NSString *) uniqueID;
- (void) setUniqueID: (NSString *)uniqueID;
- (NSString *) windowTitle;
- (void) setWindowTitle: (NSString *) theTitle;
- (PTYTask *) SHELL;
- (void) setSHELL: (PTYTask *) theSHELL;
- (VT100Terminal *) TERMINAL;
- (void) setTERMINAL: (VT100Terminal *) theTERMINAL;
- (NSString *) TERM_VALUE;
- (void) setTERM_VALUE: (NSString *) theTERM_VALUE;
- (VT100Screen *) SCREEN;
- (void) setSCREEN: (VT100Screen *) theSCREEN;
- (NSImage *) image;
- (NSView *) view;
- (PTYTextView *) TEXTVIEW;
- (void) setTEXTVIEW: (PTYTextView *) theTEXTVIEW;
- (PTYScrollView *) SCROLLVIEW;
- (void) setSCROLLVIEW: (PTYScrollView *) theSCROLLVIEW;
- (NSStringEncoding) encoding;
- (void)setEncoding:(NSStringEncoding)encoding;
- (BOOL) antiIdle;
- (int) antiCode;
- (void) setAntiIdle:(BOOL)set;
- (void) setAntiCode:(int)code;
- (BOOL) autoClose;
- (void) setAutoClose:(BOOL)set;
- (BOOL) doubleWidth;
- (void) setDoubleWidth:(BOOL)set;
- (BOOL) xtermMouseReporting;
- (void) setXtermMouseReporting:(BOOL)set;
- (NSDictionary *) addressBookEntry;
- (void) setAddressBookEntry:(NSDictionary*) entry;
- (int) number;
- (NSString *) tty;
- (NSString *) contents;


- (void)clearBuffer;
- (void)clearScrollbackBuffer;
- (BOOL)logging;
- (void)logStart;
- (void)logStop;
- (NSString *) backgroundImagePath;
- (void) setBackgroundImagePath: (NSString *) imageFilePath;
- (NSColor *) foregroundColor;
- (void)setForegroundColor:(NSColor*) color;
- (NSColor *) backgroundColor;
- (void)setBackgroundColor:(NSColor*) color;
- (NSColor *) selectionColor;
- (void) setSelectionColor: (NSColor *) color;
- (NSColor *) boldColor;
- (void)setBoldColor:(NSColor*) color;
- (NSColor *) cursorColor;
- (void)setCursorColor:(NSColor*) color;
- (NSColor *) selectedTextColor;
- (void) setSelectedTextColor: (NSColor *) aColor;
- (NSColor *) cursorTextColor;
- (void) setCursorTextColor: (NSColor *) aColor;
- (float) transparency;
- (void)setTransparency:(float)transparency;
- (BOOL) useTransparency;
- (void) setUseTransparency: (BOOL) flag;
- (BOOL) disableBold;
- (void) setDisableBold: (BOOL) boldFlag;
- (BOOL) disableBold;
- (void) setDisableBold: (BOOL) boldFlag;
- (void) setColorTable:(int) index highLight:(BOOL)hili color:(NSColor *) c;
- (int) optionKey;

// Session status

- (void)resetStatus;
- (BOOL)exited;
- (void)setLabelAttribute;
- (void)setBell;
- (void)setBell: (BOOL) flag;

- (void) updateDisplay;

@end
        
#ifndef GNUSTEP
@interface PTYSession (ScriptingSupport)

// Object specifier
- (NSScriptObjectSpecifier *)objectSpecifier;
-(void)handleExecScriptCommand: (NSScriptCommand *)aCommand;
-(void)handleTerminateScriptCommand: (NSScriptCommand *)command;
-(void)handleSelectScriptCommand: (NSScriptCommand *)command;
-(void)handleWriteScriptCommand: (NSScriptCommand *)command;

@end
#endif (GNUSTEP)

@interface PTYSession (Private)

@end
