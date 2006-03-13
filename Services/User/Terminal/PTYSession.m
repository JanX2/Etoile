/*
 **  PTYSession.m
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

#import <iTerm/iTerm.h>
#import <iTerm/PTYSession.h>
#import <iTerm/PTYTask.h>
#import <iTerm/PTYTextView.h>
#import <iTerm/PTYScrollView.h>;
#import <iTerm/VT100Screen.h>
#import <iTerm/VT100Terminal.h>
#import <iTerm/PreferencePanel.h>
#import <iTerm/PseudoTerminal.h>
#import <iTerm/iTermController.h>
#import <iTerm/NSStringITerm.h>
#import <iTerm/PTYTabViewItem.h>
#import <iTerm/iTermKeyBindingMgr.h>
#import <iTerm/ITAddressBookMgr.h>
#import <iTerm/iTermTerminalProfileMgr.h>
#import <iTerm/iTermDisplayProfileMgr.h>

#include <unistd.h>
#include <sys/wait.h>
#include <sys/time.h>

#define DEBUG_ALLOC           0
#define DEBUG_METHOD_TRACE    0
#define DEBUG_KEYDOWNDUMP     0

@implementation PTYSession

static NSString *TERM_ENVNAME = @"TERM";
static NSString *PWD_ENVNAME = @"PWD";
static NSString *PWD_ENVVALUE = @"~";

// init/dealloc
- (id) init
{
    if((self = [super init]) == nil)
        return (nil);
	
    gettimeofday(&lastInput, NULL);
    lastOutput = lastBlink = lastInput;
    waiting=antiIdle=EXIT=NO;
    
    if (normalStateAttribute == nil) 
    {
        normalStateAttribute=[[NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor blackColor],NSForegroundColorAttributeName,nil] retain];
        chosenStateAttribute=[[NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor blackColor],NSForegroundColorAttributeName,nil] retain];
        idleStateAttribute=[[NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor redColor],NSForegroundColorAttributeName,nil] retain];
        newOutputStateAttribute=[[NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor purpleColor],NSForegroundColorAttributeName,nil] retain];
        deadStateAttribute=[[NSDictionary dictionaryWithObjectsAndKeys:
            [NSColor grayColor],NSForegroundColorAttributeName,nil] retain];
    }
    addressBookEntry=nil;
	
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif    
	
	// allocate a semaphore to coordinate data processing
#ifndef GNUSTEP 
	MPCreateBinarySemaphore(&dataSemaphore);
#else
    pthread_mutex_init(&dataSemaphore, NULL);
#endif
	
    // Allocate screen, shell, and terminal objects
    SHELL = [[PTYTask alloc] init];
    TERMINAL = [[VT100Terminal alloc] init:parent];
    SCREEN = [[VT100Screen alloc] init];
    NSParameterAssert(SHELL != nil && TERMINAL != nil && SCREEN != nil);	
	
    return (self);
}

- (void) dealloc
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
	
    [TERM_VALUE release];
    [view release];
    [name release];
    [windowTitle release];
    [addressBookEntry release];
    [backgroundImagePath release];
	
    [normalStateAttribute release];
    normalStateAttribute = nil;
    [chosenStateAttribute release];
    chosenStateAttribute = nil;
    [idleStateAttribute release];
    idleStateAttribute = nil;
    [newOutputStateAttribute release];
    newOutputStateAttribute = nil;
	
    [SHELL release];
    SHELL = nil;
	
    [SCREEN release];
    SCREEN = nil;
    [TERMINAL release];
    TERMINAL = nil;    
    
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
    [super dealloc];    
}

// Session specific methods
- (void)initScreen: (NSRect) aRect width:(int)width height:(int) height
{
    NSSize aSize;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession initScreen]",
          __FILE__, __LINE__);
#endif
	
	
    [SCREEN setSession:self];
		
    // Allocate a scrollview
    SCROLLVIEW = [[PTYScrollView alloc] initWithFrame: NSMakeRect(0, 0, aRect.size.width, aRect.size.height)];
    [SCROLLVIEW setHasVerticalScroller:YES];
    NSParameterAssert(SCROLLVIEW != nil);
    [SCROLLVIEW setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	
		
    // assign the main view
    view = SCROLLVIEW;
    
    // Allocate a text view
    aSize = [PTYScrollView contentSizeForFrameSize: [SCROLLVIEW frame].size hasHorizontalScroller: NO hasVerticalScroller: YES borderType: [SCROLLVIEW borderType]];
    TEXTVIEW = [[PTYTextView alloc] initWithFrame: NSMakeRect(0, 0, aSize.width, aSize.height)];
	[TEXTVIEW setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
	
    // assign terminal and task objects
    [SCREEN setShellTask:SHELL];
    [SCREEN setTerminal:TERMINAL];
    [TERMINAL setScreen: SCREEN];
    [SHELL setDelegate:self];
	
    // initialize the screen
    [SCREEN initScreenWithWidth:width Height:height];
	[self setName:@"Shell"];

	
    [TEXTVIEW setDataSource: SCREEN];
    [TEXTVIEW setDelegate: self];
    [SCROLLVIEW setDocumentView:TEXTVIEW];
    [TEXTVIEW release];
    [SCROLLVIEW setDocumentCursor: [NSCursor arrowCursor]];

    ai_code=0;
    antiIdle = NO;
    REFRESHED = NO;
	
	// register for some notifications	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tabViewWillRedraw:)
                                                 name:@"iTermTabViewWillRedraw"
                                               object:nil];
		
    [tabViewItem setLabelAttributes: chosenStateAttribute];
}

- (BOOL) isActiveSession
{
    return ([[[self tabViewItem] tabView] selectedTabViewItem] == [self tabViewItem]);
}

- (void)startProgram:(NSString *)program
		   arguments:(NSArray *)prog_argv
		 environment:(NSDictionary *)prog_env
{
    NSString *path = program;
    NSMutableArray *argv = [NSMutableArray arrayWithArray:prog_argv];
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:prog_env];
	
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession startProgram:%@ arguments:%@ environment:%@]",
		  __FILE__, __LINE__, program, prog_argv, prog_env );
#endif
    if ([env objectForKey:TERM_ENVNAME] == nil)
        [env setObject:TERM_VALUE forKey:TERM_ENVNAME];
	
    if ([env objectForKey:PWD_ENVNAME] == nil)
        [env setObject:[PWD_ENVVALUE stringByExpandingTildeInPath] forKey:PWD_ENVNAME];
	
    [SHELL launchWithPath:path
				arguments:argv
			  environment:env
					width:[SCREEN width]
				   height:[SCREEN height]];
	
	// launch a thread to process the data read from the SHELL process
	[NSThread detachNewThreadSelector: @selector(_processReadDataThread:) toTarget: self withObject: nil];
	
}


- (void) terminate
{
			
	// deregister from the notification center
	[[NSNotificationCenter defaultCenter] removeObserver:self];    
    
    EXIT = YES;
	[SHELL stop];
	
	// release the data processing semaphore
#if defined(__APPLE__) 
	MPDeleteSemaphore(dataSemaphore);
#else
    pthread_mutex_destroy(dataSemaphore);
#endif
    if(tabViewItem)
    {
        [tabViewItem release];
        tabViewItem = nil;
    }
    [addressBookEntry release];
    addressBookEntry = nil;
	
    [SHELL setDelegate:nil];
    [SCREEN setShellTask:nil];
    [SCREEN setSession: nil];
    [SCREEN setTerminal: nil];
    [TERMINAL setScreen: nil];
    [TEXTVIEW setDataSource: nil];
	[TEXTVIEW setDelegate: nil];
    [TEXTVIEW removeFromSuperview];
    [self setTabViewItem: nil];    
    
        
    parent = nil;
	
}

- (void)writeTask:(NSData *)data
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	PTYScroller *ptys=(PTYScroller *)[SCROLLVIEW verticalScroller];

    // check if we want to send this input to all the sessions
    if([parent sendInputToAllSessions] == NO)
    {
		[SHELL writeTask: data];
		// Make sure we scroll down to the end
		[TEXTVIEW scrollEnd];
		[ptys setUserScroll: NO];		
    }
    else
    {
		// send to all sessions
		[parent sendInputToAllSessions: data];
    }
		
	[pool release];
}

- (void)readTask:(char *)buf length:(int)length
{
	
	if (buf == NULL)
        return;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession readTask:%@]", __FILE__, __LINE__, [[[NSString alloc] initWithBytes: buf length:length encoding: nil] autorelease] );
#endif
	
    [TERMINAL putStreamData:buf length:length];	
	
	// signal the data processing thread
#ifdef __APPLE__   
	MPSignalSemaphore(dataSemaphore);
#else
    pthread_mutex_lock(dataSemaphore);
#endif
}

- (void)brokenPipe
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession brokenPipe]", __FILE__, __LINE__);
#endif
    if (EXIT) return;
    
    EXIT = YES;
	
	if (autoClose)
        [parent closeSession:self];
    else 
    {
        [self setName:[NSString stringWithFormat:@"[%@]",[self name]]];
        [tabViewItem setLabelAttributes: deadStateAttribute];
    }				
    	
}

- (BOOL) hasKeyMappingForEvent: (NSEvent *) event
{
    unsigned int modflag;
    unsigned short keycode;
    NSString *keystr;
    NSString *unmodkeystr;
    unichar unicode, unmodunicode;
	int keyBindingAction;
	NSString *keyBindingText;
        
    modflag = [event modifierFlags];
    keycode = [event keyCode];
    keystr  = [event characters];
    unmodkeystr = [event charactersIgnoringModifiers];
    unicode = [keystr length]>0?[keystr characterAtIndex:0]:0;
	unmodunicode = [unmodkeystr length]>0?[unmodkeystr characterAtIndex:0]:0;
    
	//NSLog(@"event:%@ (%x+%x)[%@][%@]:%x(%c) <%d>", event,modflag,keycode,keystr,unmodkeystr,unicode,unicode,(modflag & NSNumericPadKeyMask));
	
	// Check if we have a custom key mapping for this event
	keyBindingAction = [[iTermKeyBindingMgr singleInstance] actionForKeyCode: unmodunicode 
																   modifiers: modflag 
																		text: &keyBindingText 
																	 profile: [[self addressBookEntry] objectForKey: KEY_KEYBOARD_PROFILE]];
	
	return (keyBindingAction >= 0);
}

// PTYTextView
- (void)keyDown:(NSEvent *)event
{
    unsigned char *send_str = NULL;
    unsigned char *dataPtr = NULL;
    int dataLength = 0;
    size_t send_strlen = 0;
    int send_pchr = -1;
	int keyBindingAction;
	NSString *keyBindingText;
    
    unsigned int modflag;
    unsigned short keycode;
    NSString *keystr;
    NSString *unmodkeystr;
    unichar unicode, unmodunicode;
    
#if DEBUG_METHOD_TRACE || DEBUG_KEYDOWNDUMP
    NSLog(@"%s(%d):-[PseudoTerminal keyDown:%@]",
		  __FILE__, __LINE__, event);
#endif
    
    modflag = [event modifierFlags];
    keycode = [event keyCode];
    keystr  = [event characters];
    unmodkeystr = [event charactersIgnoringModifiers];
    unicode = [keystr length]>0?[keystr characterAtIndex:0]:0;
	unmodunicode = [unmodkeystr length]>0?[unmodkeystr characterAtIndex:0]:0;
	
    gettimeofday(&lastInput, NULL);
    
    //NSLog(@"event:%@ (%x+%x)[%@][%@]:%x(%c) <%d>", event,modflag,keycode,keystr,unmodkeystr,unicode,unicode,(modflag & NSNumericPadKeyMask));
    
    // Clear the bell
    [self setBell: NO];
	
	// Check if we have a custom key mapping for this event
	keyBindingAction = [[iTermKeyBindingMgr singleInstance] actionForKeyCode: unmodunicode 
																   modifiers: modflag 
																		 text: &keyBindingText 
																	 profile: [[self addressBookEntry] objectForKey: KEY_KEYBOARD_PROFILE]];
	if(keyBindingAction >= 0)
	{
		NSString *aString;
		unsigned char hexCode;
		int hexCodeTmp;
		
		switch (keyBindingAction)
		{
			case KEY_ACTION_NEXT_SESSION:
				[parent nextSession: nil];
				break;
			case KEY_ACTION_NEXT_WINDOW:
				[[iTermController sharedInstance] nextTerminal: nil];
				break;
			case KEY_ACTION_PREVIOUS_SESSION:
				[parent previousSession: nil];
				break;
			case KEY_ACTION_PREVIOUS_WINDOW:
				[[iTermController sharedInstance] previousTerminal: nil];
				break;	
			case KEY_ACTION_SCROLL_END:
				[TEXTVIEW scrollEnd];
				break;
			case KEY_ACTION_SCROLL_HOME:
				[TEXTVIEW scrollHome];
				break;
			case KEY_ACTION_SCROLL_LINE_DOWN:
				[TEXTVIEW scrollLineDown: self];
				[(PTYScrollView *)[TEXTVIEW enclosingScrollView] detectUserScroll]; 
				break;
			case KEY_ACTION_SCROLL_LINE_UP:
				[TEXTVIEW scrollLineUp: self];
				[(PTYScrollView *)[TEXTVIEW enclosingScrollView] detectUserScroll]; 
				break;	
			case KEY_ACTION_SCROLL_PAGE_DOWN:
				[TEXTVIEW scrollPageDown: self];
				[(PTYScrollView *)[TEXTVIEW enclosingScrollView] detectUserScroll]; 
				break;
			case KEY_ACTION_SCROLL_PAGE_UP:
				[TEXTVIEW scrollPageUp: self];
				[(PTYScrollView *)[TEXTVIEW enclosingScrollView] detectUserScroll]; 
				break;	
			case KEY_ACTION_ESCAPE_SEQUENCE:
				if([keyBindingText length] > 0)
				{
					aString = [NSString stringWithFormat:@"\e%@", keyBindingText];
					[self writeTask: [aString dataUsingEncoding: NSUTF8StringEncoding]];
				}
				break;
			case KEY_ACTION_HEX_CODE:
				if([keyBindingText length] > 0 && sscanf([keyBindingText UTF8String], "%x", &hexCodeTmp) == 1)
				{
					hexCode = (unsigned char) hexCodeTmp;
					[self writeTask:[NSData dataWithBytes:&hexCode length: sizeof(hexCode)]];
				}
				break;
			case KEY_ACTION_IGNORE:
				break;
			default:
				NSLog(@"Unknown key action %d", keyBindingAction);
				break;
		}
	}
    // else do standard handling of event
    else 
    {
		if (modflag & NSFunctionKeyMask)
        {
			NSData *data = nil;
			
			switch(unicode) 
            {
                case NSUpArrowFunctionKey: data = [TERMINAL keyArrowUp:modflag]; break;
				case NSDownArrowFunctionKey: data = [TERMINAL keyArrowDown:modflag]; break;
				case NSLeftArrowFunctionKey: data = [TERMINAL keyArrowLeft:modflag]; break;
				case NSRightArrowFunctionKey: data = [TERMINAL keyArrowRight:modflag]; break;
					
				case NSInsertFunctionKey:
					// case NSHelpFunctionKey:
					data = [TERMINAL keyInsert]; break;
				case NSDeleteFunctionKey:
					data = [TERMINAL keyDelete]; break;
				case NSHomeFunctionKey: data = [TERMINAL keyHome]; break;
				case NSEndFunctionKey: data = [TERMINAL keyEnd]; break;
				case NSPageUpFunctionKey: data = [TERMINAL keyPageUp]; break;
				case NSPageDownFunctionKey: data = [TERMINAL keyPageDown]; break;
					
				case NSPrintScreenFunctionKey:
					break;
				case NSScrollLockFunctionKey:
				case NSPauseFunctionKey:
					break;
				case NSClearLineFunctionKey:
					if([TERMINAL keypadMode])
						data = [TERMINAL keyPFn: 1];
					break;
			}
			
            if (NSF1FunctionKey<=unicode&&unicode<=NSF35FunctionKey)
                data = [TERMINAL keyFunction:unicode-NSF1FunctionKey+1];
			
			if (data != nil) {
				send_str = (unsigned char *)[data bytes];
				send_strlen = [data length];
			}
		}
		else if ((modflag & NSAlternateKeyMask) && 
				 ([self optionKey] != OPT_NORMAL))
		{
			NSData *keydat = ((modflag & NSControlKeyMask) && unicode>0)?
			[keystr dataUsingEncoding:NSUTF8StringEncoding]:
			[unmodkeystr dataUsingEncoding:NSUTF8StringEncoding];
			// META combination
			if (keydat != nil) {
				send_str = (unsigned char *)[keydat bytes];
				send_strlen = [keydat length];
			}
            if ([self optionKey] == OPT_ESC) {
				send_pchr = '\e';
            }
			else if ([self optionKey] == OPT_META && send_str != NULL) 
            {
				int i;
				for (i = 0; i < send_strlen; ++i)
					send_str[i] |= 0x80;
			}
		}
		else 
		{
			int max = [keystr length];
			NSData *data=nil;
			
			if (max!=1||[keystr characterAtIndex:0] > 0x7f)
				data = [keystr dataUsingEncoding:[TERMINAL encoding]];
			else
				data = [keystr dataUsingEncoding:NSUTF8StringEncoding];
			
			// Check if we are in keypad mode
			if((modflag & NSNumericPadKeyMask) && [TERMINAL keypadMode])
			{
				switch (unicode)
				{
					case '=':
						data = [TERMINAL keyPFn: 2];;
						break;
					case '/':
						data = [TERMINAL keyPFn: 3];
						break;
					case '*':
						data = [TERMINAL keyPFn: 4];
						break;
					default:
						data = [TERMINAL keypadData: unicode keystr: keystr];
						break;
				}
			}
			
			
			if (data != nil ) {
				send_str = (unsigned char *)[data bytes];
				send_strlen = [data length];
			}
			
			// NSLog(@"modflag = 0x%x; send_strlen = %d; send_str[0] = '%c (0x%x)'", modflag, send_strlen, send_str[0]);
			if ((modflag & NSNumericPadKeyMask &&
				 send_strlen == 1 &&
				 send_str[0] == 0x03) || keycode==52)
			{
				send_str = (unsigned char*)"\015";  // NumericPad or Laptop Enter -> 0x0d
				send_strlen = 1;
			}
			if (modflag & NSControlKeyMask &&
				send_strlen == 1 &&
				send_str[0] == '|')
			{
				send_str = (unsigned char*)"\034"; // control-backslash
				send_strlen = 1;
			}
			
			if ((modflag & NSControlKeyMask) && 
				(modflag & NSShiftKeyMask) &&
				send_strlen == 1 &&
				send_str[0] == '/')
			{
				send_str = (unsigned char*)"\177"; // control-?
				send_strlen = 1;
			}						
			else if (modflag & NSControlKeyMask &&
					 send_strlen == 1 &&
					 send_str[0] == '/')
			{
				send_str = (unsigned char*)"\037"; // control-/
				send_strlen = 1;
			}
			
		}
				
		if (EXIT == NO ) 
        {
			if (send_pchr >= 0) {
				char c = send_pchr;
				dataPtr = (unsigned char*)&c;
				dataLength = 1;
				[self writeTask:[NSData dataWithBytes:dataPtr length:dataLength]];
			}

			if (send_str != NULL) {
				dataPtr = send_str;
				dataLength = send_strlen;
				[self writeTask:[NSData dataWithBytes:dataPtr length:dataLength]];
			}
						
		}
    }
	
	// let the update thred update display if a key is being held down
	if([TEXTVIEW keyIsARepeat] == NO)
		[self updateDisplay];
}


- (BOOL)willHandleEvent: (NSEvent *) theEvent
{
    // Handle the option-click event
    return (([theEvent type] == NSLeftMouseDown) &&
			([theEvent modifierFlags] & NSAlternateKeyMask));       
}

- (void)handleEvent: (NSEvent *) theEvent
{
    // We handle option-click to position the cursor...
    if(([theEvent type] == NSLeftMouseDown) &&
       ([theEvent modifierFlags] & NSAlternateKeyMask))
		[self handleOptionClick: theEvent];
}

- (void) handleOptionClick: (NSEvent *) theEvent
{
    // Here we will attempt to position the cursor to the mouse-click
	
    NSPoint locationInWindow, locationInTextView, locationInScrollView;
    int x, y;
	float w=[parent charWidth], h=[parent charHeight];
	
    locationInWindow = [theEvent locationInWindow];
    locationInTextView = [TEXTVIEW convertPoint: locationInWindow fromView: nil];
    locationInScrollView = [SCROLLVIEW convertPoint: locationInWindow fromView: nil];
	
	x = locationInTextView.x/w;
    y = locationInScrollView.y/h + 1;
	
    // NSLog(@"loc_x = %f; loc_y = %f", locationInTextView.x, locationInScrollView.y);
    // NSLog(@"font width = %f, font height = %f", fontSize.width, fontSize.height);
    // NSLog(@"x = %d; y = %d", x, y);
	
	
    if(x == [SCREEN cursorX] && y == [SCREEN cursorY])
		return;
	
    NSData *data;
    int i;
    // now move the cursor up or down
    for(i = 0; i < abs(y - [SCREEN cursorY]); i++)
    {
		if(y < [SCREEN cursorY])
            data = [TERMINAL keyArrowUp:0];
		else
            data = [TERMINAL keyArrowDown:0];
		[self writeTask:[NSData dataWithBytes:[data bytes] length:[data length]]];
    }
    // now move the cursor left or right    
    for(i = 0; i < abs(x - [SCREEN cursorX]); i++)
    {
		if(x < [SCREEN cursorX])
			data = [TERMINAL keyArrowLeft:0];
		else
			data = [TERMINAL keyArrowRight:0];
		[self writeTask:[NSData dataWithBytes:[data bytes] length:[data length]]];
    }
    
    // trigger an update of the display.
    [SCREEN updateScreen];
}

// do any idle tasks here
- (void) doIdleTasks
{
}

- (void)insertText:(NSString *)string
{
    NSData *data;
    NSMutableString *mstring;
    int i, max;
	
	//    NSLog(@"insertText: %@",string);
    mstring = [NSMutableString stringWithString:string];
    max = [string length];
    for(i=0; i<max; i++) {
        if ([mstring characterAtIndex:i] == 0xa5) {
            [mstring replaceCharactersInRange:NSMakeRange(i, 1) withString:@"\\"];
        }
    }
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession insertText:%@]",
		  __FILE__, __LINE__, mstring);
#endif
	
    //if([TERMINAL encoding] != NSUTF8StringEncoding) {
    //    data = [mstring dataUsingEncoding:[TERMINAL encoding]
    //                allowLossyConversion:YES];
    //} else {
    //    char *fs_str = (char *)[mstring fileSystemRepresentation];
    //    data = [NSData dataWithBytes:fs_str length:strlen(fs_str)];
    //}
    
    data = [mstring dataUsingEncoding:[TERMINAL encoding]
				 allowLossyConversion:YES];

    if (data != nil) 
		[self writeTask:data];

	// let the update thred update display if a key is being held down
	if([TEXTVIEW keyIsARepeat] == NO)
		[self updateDisplay];
}

- (void)insertNewline:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession insertNewline:%@]",
		  __FILE__, __LINE__, sender);
#endif
    [self insertText:@"\n"];
}

- (void)insertTab:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession insertTab:%@]",
		  __FILE__, __LINE__, sender);
#endif
    [self insertText:@"\t"];
}

- (void)moveUp:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession moveUp:%@]",
		  __FILE__, __LINE__, sender);
#endif
    [self writeTask:[TERMINAL keyArrowUp:0]];
}

- (void)moveDown:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession moveDown:%@]",
		  __FILE__, __LINE__, sender);
#endif
    [self writeTask:[TERMINAL keyArrowDown:0]];
}

- (void)moveLeft:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession moveLeft:%@]",
		  __FILE__, __LINE__, sender);
#endif
    [self writeTask:[TERMINAL keyArrowLeft:0]];
}

- (void)moveRight:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession moveRight:%@]",
		  __FILE__, __LINE__, sender);
#endif
    [self writeTask:[TERMINAL keyArrowRight:0]];
}

- (void)pageUp:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession pageUp:%@]",
		  __FILE__, __LINE__, sender);
#endif
    [self writeTask:[TERMINAL keyPageUp]];
}

- (void)pageDown:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession pageDown:%@]",
		  __FILE__, __LINE__, sender);
#endif
    [self writeTask:[TERMINAL keyPageDown]];
}

- (void)paste:(id)sender
{
    NSPasteboard *board;
    NSString *str;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession paste:...]", __FILE__, __LINE__);
#endif
	
    board = [NSPasteboard generalPasteboard];
    NSParameterAssert(board != nil );
    str = [board stringForType:NSStringPboardType];
    [self pasteString: str];
}

- (void) pasteString: (NSString *) aString
{
	
    if ([aString length] > 0)
    {
        NSData *strdata = [[aString stringReplaceSubstringFrom:@"\n" to:@"\r"]
                                    dataUsingEncoding:[TERMINAL encoding]
								 allowLossyConversion:YES];
		
		// Do this in a new thread since we do not want to block the read code.
		[NSThread detachNewThreadSelector:@selector(writeTask:) toTarget:self withObject:strdata];
		
    }
    else
		NSBeep();
	
}

- (void)deleteBackward:(id)sender
{
    unsigned char p = 0x08;	// Ctrl+H
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession deleteBackward:%@]",
		  __FILE__, __LINE__, sender);
#endif
	
    [self writeTask:[NSData dataWithBytes:&p length:1]];
}

- (void)deleteForward:(id)sender
{
    unsigned char p = 0x7F;	// DEL
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession deleteForward:%@]",
		  __FILE__, __LINE__, sender);
#endif
    [self writeTask:[NSData dataWithBytes:&p length:1]];
}

- (void) textViewDidChangeSelection: (NSNotification *) aNotification
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession textViewDidChangeSelection]",
		  __FILE__, __LINE__);
#endif
	
    if([[PreferencePanel sharedInstance] copySelection])
		[TEXTVIEW copy: self];
}

- (void) textViewResized: (NSNotification *) aNotification;
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s: textView = 0x%x", __PRETTY_FUNCTION__, TEXTVIEW);
#endif
	int w, h;
		
	w = (int)(([[SCROLLVIEW contentView] frame].size.width - MARGIN * 2)/[parent charWidth]);
	h = (int)([[SCROLLVIEW contentView] frame].size.height/[parent charHeight]);
	//NSLog(@"%s: w = %d; h = %d; old w = %d; old h = %d", __PRETTY_FUNCTION__, w, h, [SCREEN width], [SCREEN height]);
	
	[SCREEN resizeWidth:w height:h];
	[SHELL setWidth:w  height:h];
	
}

- (void) setLabelAttribute
{
    struct timeval now;
    
    gettimeofday(&now, NULL);
    if ([self exited])
        [tabViewItem setLabelAttributes: deadStateAttribute];
    else if([[tabViewItem tabView] selectedTabViewItem] != tabViewItem) 
    {
        if (now.tv_sec*10+now.tv_sec/100000 >= lastOutput.tv_sec*10+lastOutput.tv_sec/100000+10 && !waiting) {
            waiting=YES;
            if (REFRESHED)
			{
				[tabViewItem setLabelAttributes: idleStateAttribute];
			}
            else
                [tabViewItem setLabelAttributes: normalStateAttribute];
        }
        else if (waiting && now.tv_sec <= lastOutput.tv_sec) {
            waiting=NO;
            [tabViewItem setLabelAttributes: newOutputStateAttribute];
        }
    }
    else {
        [tabViewItem setLabelAttributes: chosenStateAttribute];
    }
    [self setBell:NO];
}

- (void) setBell
{
    [self setBell:YES];
}

- (void) setBell: (BOOL) flag
{
    [tabViewItem setBell:flag];
}

- (void) setPreferencesFromAddressBookEntry: (NSDictionary *) aePrefs
{
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession setPreferencesFromAddressBookEntry:");
#endif
    
    NSColor *colorTable[2][8];
    int i;
    NSString *imageFilePath;
	NSString *displayProfile, *terminalProfile;
	NSDictionary *aDict;
	iTermTerminalProfileMgr *terminalProfileMgr;
	iTermDisplayProfileMgr *displayProfileMgr;
	ITAddressBookMgr *bookmarkManager;
	
	// get our shared managers
	terminalProfileMgr = [iTermTerminalProfileMgr singleInstance];
	displayProfileMgr = [iTermDisplayProfileMgr singleInstance];
	bookmarkManager = [ITAddressBookMgr sharedInstance];
	
	aDict = aePrefs;
	if(aDict == nil)
		aDict = [bookmarkManager defaultBookmarkData];
	
	// grab the profiles
	displayProfile = [aDict objectForKey: KEY_DISPLAY_PROFILE];
	if(displayProfile == nil || [[displayProfileMgr profiles] objectForKey: displayProfile] == nil)
		displayProfile = [displayProfileMgr defaultProfileName];
	terminalProfile = [aDict objectForKey: KEY_TERMINAL_PROFILE];
	if(terminalProfile == nil || [[terminalProfileMgr profiles] objectForKey: terminalProfile] == nil)
		terminalProfile = [terminalProfileMgr defaultProfileName];	
	
	
    // colors
    [self setForegroundColor: [displayProfileMgr color: TYPE_FOREGROUND_COLOR forProfile: displayProfile]];
    [self setBackgroundColor: [displayProfileMgr color: TYPE_BACKGROUND_COLOR forProfile: displayProfile]];
	[self setSelectionColor: [displayProfileMgr color: TYPE_SELECTION_COLOR forProfile: displayProfile]];
	[self setSelectedTextColor: [displayProfileMgr color: TYPE_SELECTED_TEXT_COLOR forProfile: displayProfile]];	
	[self setBoldColor: [displayProfileMgr color: TYPE_BOLD_COLOR forProfile: displayProfile]];
	[self setCursorColor: [displayProfileMgr color: TYPE_CURSOR_COLOR forProfile: displayProfile]];	
	[self setCursorTextColor: [displayProfileMgr color: TYPE_CURSOR_TEXT_COLOR forProfile: displayProfile]];	
	for(i = TYPE_ANSI_0_COLOR; i < TYPE_ANSI_8_COLOR; i++)
	{
		colorTable[0][i] = [displayProfileMgr color: i forProfile: displayProfile];
		colorTable[1][i] = [displayProfileMgr color: (i + TYPE_ANSI_8_COLOR)  forProfile: displayProfile];
	}	
    for(i=0;i<8;i++) {
        [self setColorTable:i highLight:NO color:colorTable[0][i]];
        [self setColorTable:i highLight:YES color:colorTable[1][i]];
    }
		
    // background image
    imageFilePath = [displayProfileMgr backgroundImageForProfile: displayProfile];
    if([imageFilePath length] > 0)
		[self setBackgroundImagePath: imageFilePath];
	
    // transparency
    [self setTransparency: [displayProfileMgr transparencyForProfile: displayProfile]];  
	
	// bold
	[self setDisableBold: [displayProfileMgr disableBoldForProfile: displayProfile]];
	
    // set up the rest of the preferences
    [SCREEN setPlayBellFlag: ![terminalProfileMgr silenceBellForProfile: terminalProfile]];
	[SCREEN setShowBellFlag: [terminalProfileMgr showBellForProfile: terminalProfile]];
	[SCREEN setBlinkingCursor: [terminalProfileMgr blinkCursorForProfile: terminalProfile]];
	[TEXTVIEW setBlinkingCursor: [terminalProfileMgr blinkCursorForProfile: terminalProfile]];
    [self setEncoding: [terminalProfileMgr encodingForProfile: terminalProfile]];
    [self setTERM_VALUE: [terminalProfileMgr typeForProfile: terminalProfile]];
    [self setAntiCode: [terminalProfileMgr idleCharForProfile: terminalProfile]];
    [self setAntiIdle: [terminalProfileMgr sendIdleCharForProfile: terminalProfile]];
    [self setAutoClose: [terminalProfileMgr closeOnSessionEndForProfile: terminalProfile]];
    [self setDoubleWidth:[terminalProfileMgr doubleWidthForProfile: terminalProfile]];
	[self setXtermMouseReporting:[terminalProfileMgr xtermMouseReportingForProfile: terminalProfile]];
    
}

// Contextual menu
- (void) menuForEvent:(NSEvent *)theEvent menu: (NSMenu *) theMenu
{
    NSMenuItem *aMenuItem;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession menuForEvent]", __FILE__, __LINE__);
#endif
	
    // Clear buffer
    aMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Clear Buffer",@"iTerm", [NSBundle bundleForClass: [self class]], @"Context menu") action:@selector(clearBuffer:) keyEquivalent:@""];
    [aMenuItem setTarget: [self parent]];
    [theMenu addItem: aMenuItem];
    [aMenuItem release];
    
    // Ask the parent if it has anything to add
    if ([[self parent] respondsToSelector:@selector(menuForEvent: menu:)])
		[[self parent] menuForEvent:theEvent menu: theMenu];    
}

- (PseudoTerminal *) parent
{
    return (parent);
}

- (void) setParent: (PseudoTerminal *) theParent
{
    parent = theParent; // don't retain parent. parent retains self.
}

- (PTYTabViewItem *) tabViewItem
{
    return (tabViewItem);
}

- (void) setTabViewItem: (PTYTabViewItem *) theTabViewItem
{
    [tabViewItem release];
    tabViewItem = [theTabViewItem retain];
}

- (void) tabViewWillRedraw: (NSNotification *) aNotification
{
	if([aNotification object] == [[self tabViewItem] tabView])
		[TEXTVIEW setForceUpdate: YES];
}

- (NSString *) uniqueID
{
    return ([self tty]);
}

- (void) setUniqueID: (NSString *)uniqueID
{
    NSLog(@"Not allowed to set unique ID");
}

- (NSString *) name
{
    return (name);
}

- (void) setName: (NSString *) theName
{
    NSMutableString *aMutableString;
	
    if([name isEqualToString: theName])
		return;
    
    if(name)
    {
		// clear the window title if it is not different
		if([self windowTitle] == nil || [name isEqualToString: [self windowTitle]])
			[self setWindowTitle: nil];
        [name release];
        name = nil;
    }
    if(theName)
    {
        name = [theName retain];
		// sync the window title if it is not set to something else
		if([self windowTitle] == nil)
			[self setWindowTitle: theName];
    }
    if([theName length] > 20)
    {
        aMutableString = [[NSMutableString alloc] initWithString: [theName substringWithRange: NSMakeRange(0, 17)]];
        [aMutableString appendString: @"..."];
        [tabViewItem setLabel: aMutableString];
        [self setBell: NO];
        [aMutableString release];
    }
    else {
        [tabViewItem setLabel: theName];
        [self setBell: NO];
    }
	
    // get the session submenu to be rebuilt
    if([[iTermController sharedInstance] currentTerminal] == [self parent])
    {
		[[NSNotificationCenter defaultCenter] postNotificationName: @"iTermNameOfSessionDidChange" object: self userInfo: nil];
    }
}

- (NSString *) windowTitle
{
    return (windowTitle);
}

- (void) setWindowTitle: (NSString *) theTitle
{
    [windowTitle autorelease];
    windowTitle = nil;
    
    if(theTitle != nil)
    {
		windowTitle = [theTitle retain];
		if([[self parent] currentSession] == self)
			[[[self parent] window] setTitle: windowTitle];
    }
}

- (PTYTask *) SHELL
{
    return (SHELL);
}

- (void) setSHELL: (PTYTask *) theSHELL
{
    [SHELL autorelease];
    SHELL = [theSHELL retain];
}

- (VT100Terminal *) TERMINAL
{
    return (TERMINAL);
}

- (void) setTERMINAL: (VT100Terminal *) theTERMINAL
{
    [TERMINAL autorelease];
    TERMINAL = [theTERMINAL retain];
}

- (NSString *) TERM_VALUE
{
    return (TERM_VALUE);
}

- (void) setTERM_VALUE: (NSString *) theTERM_VALUE
{
    [TERM_VALUE autorelease];
    TERM_VALUE = [theTERM_VALUE retain];
}

- (VT100Screen *) SCREEN
{
    return (SCREEN);
}

- (void) setSCREEN: (VT100Screen *) theSCREEN
{
    [SCREEN autorelease];
    SCREEN = [theSCREEN retain];
}

- (NSImage *) image
{
    return ([SCROLLVIEW backgroundImage]);
}

- (NSView *) view
{
    return (view);
}

- (PTYTextView *) TEXTVIEW
{
    return (TEXTVIEW);
}

- (void) setTEXTVIEW: (PTYTextView *) theTEXTVIEW
{
    [TEXTVIEW autorelease];
    TEXTVIEW = [theTEXTVIEW retain];
}

- (PTYScrollView *) SCROLLVIEW
{
    return (SCROLLVIEW);
}

- (void) setSCROLLVIEW: (PTYScrollView *) theSCROLLVIEW
{
    [SCROLLVIEW autorelease];
    SCROLLVIEW = [theSCROLLVIEW retain];
}

- (NSStringEncoding) encoding
{
	return [TERMINAL encoding];
}

- (void)setEncoding:(NSStringEncoding)encoding
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PseudoTerminal setEncoding:%d]",
          __FILE__, __LINE__, encoding);
#endif
    [TERMINAL setEncoding:encoding];
}

- (NSString *) tty
{
    return ([SHELL tty]);
}

- (int) number
{
    return ([[tabViewItem tabView] indexOfTabViewItem: tabViewItem]);
}

- (NSString *) contents
{
	return ([TEXTVIEW content]);
}

- (NSString *) backgroundImagePath
{
    return (backgroundImagePath);
}

- (void) setBackgroundImagePath: (NSString *) imageFilePath
{
    [backgroundImagePath release];
    if([imageFilePath length] > 0 && [imageFilePath isAbsolutePath] == NO)
    {
		NSBundle *myBundle = [NSBundle bundleForClass: [self class]];
		backgroundImagePath = [myBundle pathForResource: imageFilePath ofType: @""];
		[backgroundImagePath retain];
    }
    else
    {
		[imageFilePath retain];
		backgroundImagePath = imageFilePath;
    }
    if([backgroundImagePath length] > 0)
    {
		NSImage *anImage = [[NSImage alloc] initWithContentsOfFile: backgroundImagePath];
		if(anImage != nil)
		{
			[SCROLLVIEW setDrawsBackground: NO];
			[SCROLLVIEW setBackgroundImage: anImage];
			[anImage release];
		}
		else
		{
			[backgroundImagePath release];
			backgroundImagePath = nil;
			[SCROLLVIEW setDrawsBackground: YES];
		}
    }
    else
    {
		[SCROLLVIEW setBackgroundImage: nil];
		[SCROLLVIEW setDrawsBackground: NO];
		[backgroundImagePath release];
		backgroundImagePath = nil;
    }
	
	[TEXTVIEW setForceUpdate: YES];
	[TEXTVIEW setNeedsDisplay: YES];
}


- (NSColor *) foregroundColor
{
    return ([TEXTVIEW defaultFGColor]);
}

- (void)setForegroundColor:(NSColor*) color
{
    if(color == nil)
        return;
    
    if(([TEXTVIEW defaultFGColor] != color) || 
	   ([[TEXTVIEW defaultFGColor] alphaComponent] != [color alphaComponent]))
    {
        // Change the fg color for future stuff
        [TEXTVIEW setFGColor: color];
    }
}

- (NSColor *) backgroundColor
{
    return ([TEXTVIEW defaultBGColor]);
}

- (void)setBackgroundColor:(NSColor*) color
{
    if(color == nil)
        return;
	
    if(([TEXTVIEW defaultBGColor] != color) || 
	   ([[TEXTVIEW defaultBGColor] alphaComponent] != [color alphaComponent]))
    {
        // Change the bg color for future stuff
        [TEXTVIEW setBGColor: color];
    }
    
    [[self SCROLLVIEW] setBackgroundColor: color];
}

- (NSColor *) boldColor
{
    return ([TEXTVIEW defaultBoldColor]);
}

- (void)setBoldColor:(NSColor*) color
{
    [[self TEXTVIEW] setBoldColor: color];
}

- (NSColor *) cursorColor
{
    return ([TEXTVIEW defaultCursorColor]);
}

- (void)setCursorColor:(NSColor*) color
{
    [[self TEXTVIEW] setCursorColor: color];
}

- (NSColor *) selectionColor
{
    return ([TEXTVIEW selectionColor]);
}

- (void) setSelectionColor: (NSColor *) color
{
    [TEXTVIEW setSelectionColor: color];
}

- (NSColor *) selectedTextColor
{
	return ([TEXTVIEW selectedTextColor]);
}

- (void) setSelectedTextColor: (NSColor *) aColor
{
	[TEXTVIEW setSelectedTextColor: aColor];
}

- (NSColor *) cursorTextColor
{
	return ([TEXTVIEW cursorTextColor]);
}

- (void) setCursorTextColor: (NSColor *) aColor
{
	[TEXTVIEW setCursorTextColor: aColor];
}

// Changes transparency

- (float) transparency
{
    return ([TEXTVIEW transparency]);
}

- (void)setTransparency:(float)transparency
{
	
    // set transparency of background image
    [SCROLLVIEW setTransparency: transparency];
	[TEXTVIEW setTransparency: transparency];
	
}

- (BOOL) useTransparency
{
  return [TEXTVIEW useTransparency];
}

- (void) setUseTransparency: (BOOL) flag
{
  [TEXTVIEW setUseTransparency: flag];
}

- (void) setColorTable:(int) index highLight:(BOOL)hili color:(NSColor *) c
{
    [TEXTVIEW setColorTable:index highLight:hili color:c];
}

- (BOOL) antiIdle
{
    return antiIdle;
}

- (int) antiCode
{
    return ai_code;
}

- (void) setAntiIdle:(BOOL)set
{
    antiIdle=set;
}

- (void) setAntiCode:(int)code
{
    ai_code=code;
}

- (BOOL) autoClose
{
    return autoClose;
}

- (void) setAutoClose:(BOOL)set
{
    autoClose=set;
}

- (BOOL) disableBold
{
	return ([TEXTVIEW disableBold]);
}

- (void) setDisableBold: (BOOL) boldFlag
{
	[TEXTVIEW setDisableBold: boldFlag];
}


- (BOOL) doubleWidth
{
    return doubleWidth;
}

- (void) setDoubleWidth:(BOOL)set
{
    doubleWidth=set;
}

- (BOOL) xtermMouseReporting
{
	return xtermMouseReporting;
}

- (void) setXtermMouseReporting:(BOOL)set
{
	xtermMouseReporting = set;
}


- (BOOL) logging
{
    return ([SHELL logging]);
}

- (void)logStart
{
    NSSavePanel *panel;
    int sts;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession logStart:%@]",
          __FILE__, __LINE__);
#endif
    panel = [NSSavePanel savePanel];
    sts = [panel runModalForDirectory:NSHomeDirectory() file:@""];
    if (sts == NSOKButton) {
        BOOL logsts = [SHELL loggingStartWithPath:[panel filename]];
        if (logsts == NO)
            NSBeep();
    }
}

- (void)logStop
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession logStop:%@]",
          __FILE__, __LINE__);
#endif
    [SHELL loggingStop];
}

- (void)clearBuffer
{
    //char formFeed = 0x0c; // ^L
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYSession clearBuffer:...]", __FILE__, __LINE__);
#endif
    //[TERMINAL cleanStream];
	
    [SCREEN clearBuffer];
    // tell the shell to clear the screen
    //[self writeTask:[NSData dataWithBytes:&formFeed length:1]];
}

- (void)clearScrollbackBuffer
{
    [SCREEN clearScrollbackBuffer];
}

- (BOOL)refreshed
{
    return REFRESHED;
}

- (void) resetStatus;
{
    waiting = REFRESHED = NO;
}

- (BOOL)exited
{
    return EXIT;
}

- (int) optionKey
{
	NSString *kbProfile;
	
	// Grab our keyboard profile
	kbProfile = [[self addressBookEntry] objectForKey: @"Keyboard Profile"];
	
	return ([[iTermKeyBindingMgr singleInstance] optionKeyForProfile: kbProfile]);
}

- (void) setAddressBookEntry:(NSDictionary*) entry
{
    [addressBookEntry release];
    addressBookEntry = [entry retain];
}

- (NSDictionary *)addressBookEntry
{
    return addressBookEntry;
}


- (void) updateDisplay
{
    struct timeval now;
    static struct timeval lastUpdate={0,0};
    
    gettimeofday(&now, NULL);
    
	if (antiIdle && now.tv_sec >= lastInput.tv_sec + 60) {
        [self writeTask:[NSData dataWithBytes:&ai_code length:1]];
        lastInput = now;
    }
	if([[tabViewItem tabView] selectedTabViewItem] != tabViewItem) 
		[self setLabelAttribute];
	
	if ([[TEXTVIEW window] isKeyWindow] && now.tv_sec*10+now.tv_sec/100000 >= lastBlink.tv_sec*10+lastBlink.tv_sec/100000+5) {
		lastBlink = now;
        [TEXTVIEW refresh];
        lastUpdate = now;
	}
	else if (lastOutput.tv_sec > lastUpdate.tv_sec || (lastOutput.tv_sec == lastUpdate.tv_sec &&lastOutput.tv_usec > lastUpdate.tv_usec) ) {
        [TEXTVIEW refresh];
        lastUpdate = lastOutput;
    }
	
}


@end

#ifndef GNUSTEP
@implementation PTYSession (ScriptingSupport)

// Object specifier
- (NSScriptObjectSpecifier *)objectSpecifier
{
    unsigned index = 0;
    id classDescription = nil;
	
    NSScriptObjectSpecifier *containerRef = nil;
	
    NSArray *recipients = [[self parent] sessions];
    index = [recipients indexOfObjectIdenticalTo:self];
    if (index != NSNotFound)
    {
		containerRef     = [[self parent] objectSpecifier];
		classDescription = [containerRef keyClassDescription];
		//create and return the specifier
		return [[[NSIndexSpecifier allocWithZone:[self zone]]
               initWithContainerClassDescription: classDescription
                              containerSpecifier: containerRef
                                             key: @ "sessions"
                                           index: index] autorelease];
    } else {
		// NSLog(@"recipient not found!");
        return nil;
    }
	
}

// Handlers for supported commands:
-(void)handleExecScriptCommand: (NSScriptCommand *)aCommand
{
    // if we are already doing something, get out.
    if([SHELL pid] > 0)
    {
		NSBeep();
		return;
    }
    
    // Get the command's arguments:
    NSDictionary *args = [aCommand evaluatedArguments];
    NSString *command = [args objectForKey:@"command"];
	
    NSString *cmd;
    NSArray *arg;
	
    [iTermController breakDown:command cmdPath:&cmd cmdArgs:&arg];
	
    [self startProgram:cmd arguments:arg environment:[NSDictionary dictionary]];
    
    return;
}

-(void)handleSelectScriptCommand: (NSScriptCommand *)command
{
    [parent setCurrentSession: self];
}

-(void)handleWriteScriptCommand: (NSScriptCommand *)command
{
    // Get the command's arguments:
    NSDictionary *args = [command evaluatedArguments];
    // optional argument follows (might be nil):
    NSString *contentsOfFile = [args objectForKey:@"contentsOfFile"];
    // optional argument follows (might be nil):
    NSString *text = [args objectForKey:@"text"];
    NSData *data = nil;
    NSString *aString = nil;
	
    if(text != nil)
    {
		aString = [NSString stringWithFormat:@"%@\n", text];
		data = [aString dataUsingEncoding: [TERMINAL encoding]];
    }
	
    if(contentsOfFile != nil)
    {
		aString = [NSString stringWithContentsOfFile: contentsOfFile];
		data = [aString dataUsingEncoding: [TERMINAL encoding]];
    }
	
    if(data != nil && [SHELL pid] > 0)
    {
		int i = 0;
		// wait here until we have had some output
		while([SHELL firstOutput] == NO && i < 1000000)
		{
			usleep(50000);
			i += 50000;
		}
		
		// do this in a new thread so that we don't get stuck.
		[NSThread detachNewThreadSelector:@selector(writeTask:) toTarget:SHELL withObject:data];
    }
}

-(void)handleTerminateScriptCommand: (NSScriptCommand *)command
{
    [[self parent] closeSession: self];
}

@end
#endif (GNUSTEP)

@implementation PTYSession (Private)

// thread to process data read from the task being run
-(void)_processReadDataThread: (void *) arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSAutoreleasePool *arPool = nil;
	int iterationCount = 0;
	VT100TCC token;
	
	while(EXIT == NO)
	{
		
		// wait for data
#if defined(__APPLE__)
		MPWaitOnSemaphore(dataSemaphore, kDurationForever);
#else
        pthread_mutex_lock(&dataSemaphore);
#endif
		
		// inner while loop to process all the tokens we can get
		while(EXIT == NO)
		{
			// grab next token
			token = [TERMINAL getNextToken];
			
			// if we reached end of stream, get out
			if(token.type == VT100CC_NULL)
				break;
			
			// ok, we have a token to be processed
			if (TERMINAL && token.type != VT100_WAIT)
			{	
				
				// refresh our autrelease pool
				if(arPool == nil)
					arPool = [[NSAutoreleasePool alloc] init];
				
				// process token
				if (token.type != VT100_SKIP)
				{
					[SCREEN putToken:token];
					
					if (REFRESHED==NO)
					{
						REFRESHED=YES;
						if([[tabViewItem tabView] selectedTabViewItem] != tabViewItem)
							[tabViewItem setLabelAttributes: newOutputStateAttribute];
					}
					
					gettimeofday(&lastOutput, NULL);
				}
				
				if (token.type == VT100_NOTSUPPORT) {
					NSLog(@"%s(%d):not support token", __FILE__ , __LINE__);
				}
				
				// periodically refresh autoreleasepool
				iterationCount++;
				if(iterationCount % 100 == 0)
				{
					[arPool release];
					arPool = nil;
					iterationCount = 0;
				}
			} // end token processing
			
		} // end inner while loop
		
		
	} // end outer while loop
				
	if(arPool != nil)
	{
		[arPool release];
		arPool = nil;
	}
	
	[pool release];
	
	[NSThread exit];
	
}


@end
