// -*- mode:objc -*-
// $Id: VT100Screen.m,v 1.231 2006/03/03 19:43:51 ujwal Exp $
//
/*
 **  VT100Screen.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian, Ujwal S. Setlur
 **	     Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: Implements the VT100 screen.
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
#import <iTerm/VT100Screen.h>
#import <iTerm/NSStringITerm.h>
#import <iTerm/PseudoTerminal.h>
#import <iTerm/PTYTextView.h>
#import <iTerm/PTYScrollView.h>
#import <iTerm/charmaps.h>
#import <iTerm/PTYSession.h>
#import <iTerm/PTYTask.h>
#import <iTerm/PreferencePanel.h>
#include <string.h>

/* translates normal char into graphics char */
void translate(screen_char_t *s, int len)
{
    int i;
	
    for(i=0;i<len;i++) s[i].ch = charmap[(int)(s[i].ch)];	
}

/* pad the source string whenever double width character appears */
void padString(NSString *s, screen_char_t *buf, char doubleWidth, int fg, int bg, int *len)
{
    unichar *sc; 
	int l=[s length];
	int i,j;
	
	sc = (unichar *) malloc(l*sizeof(unichar));
	[s getCharacters: sc];
	for(i=j=0;i<l;i++,j++) {
		buf[j].ch = sc[i];
		buf[j].fg_color = fg;
		buf[j].bg_color = bg;
		if (doubleWidth && ISDOUBLEWIDTHCHARACTER(sc[i])) 
		{
			j++;
			buf[j].ch = 0xffff;
			buf[j].fg_color = fg;
			buf[j].bg_color = bg;
		}
	}
	*len=j;
	free(sc);
}

// increments line pointer accounting for buffer wrap-around
static screen_char_t *incrementLinePointer(screen_char_t *buf_start, screen_char_t *current_line, 
								  int max_lines, int line_width, BOOL *wrap)
{
	screen_char_t *next_line;
	
	next_line = current_line + line_width;
	if(next_line >= (buf_start + line_width*max_lines))
	{
		next_line = buf_start;
		if(wrap)
			*wrap = YES;
	}
	else if(wrap)
		*wrap = NO;
	
	return (next_line);
}


@interface VT100Screen (Private)

- (screen_char_t *) _getLineAtIndex: (int) anIndex fromLine: (screen_char_t *) aLine;
- (screen_char_t *) _getDefaultLineWithWidth: (int) width;
- (BOOL) _addLineToScrollback;

@end

@implementation VT100Screen

#define DEFAULT_WIDTH     80
#define DEFAULT_HEIGHT    25
#define DEFAULT_FONTSIZE  14
#define DEFAULT_SCROLLBACK 1000

#define MIN_WIDTH     10
#define MIN_HEIGHT    3

#define TABSIZE     8


- (id)init
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
    if ((self = [super init]) == nil)
	return nil;

    WIDTH = DEFAULT_WIDTH;
    HEIGHT = DEFAULT_HEIGHT;

    CURSOR_X = CURSOR_Y = 0;
    SAVE_CURSOR_X = SAVE_CURSOR_Y = 0;
    SCROLL_TOP = 0;
    SCROLL_BOTTOM = HEIGHT - 1;

    TERMINAL = nil;
    SHELL = nil;
	
	buffer_chars = NULL;
	dirty = NULL;
	first_buffer_line = NULL;
	last_buffer_line = NULL;
	screen_top = NULL;
	scrollback_top = NULL;
	
	temp_buffer=NULL;

    max_scrollback_lines = DEFAULT_SCROLLBACK;
    [self clearTabStop];
    
    // set initial tabs
    int i;
    for(i = TABSIZE; i < TABWINDOW; i += TABSIZE)
        tabStop[i] = YES;

    for(i=0;i<4;i++) saveCharset[i]=charset[i]=0;
	
	screenLock = [[NSLock alloc] init];
     
    return self;
}

- (void)dealloc
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
	
	// free our character buffer
	if(buffer_chars)
		free(buffer_chars);
	// free our "dirty flags" buffer
	if(dirty)
		free(dirty);
	// free our default line
	if(default_line)
		free(default_line);
	
	if (temp_buffer) 
		free(temp_buffer);
	
	[screenLock release];
	
    [printToAnsiString release];
	
    [super dealloc];
}

- (NSString *)description
{
    NSString *basestr;
    //NSString *colstr;
    NSString *result;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen description]", __FILE__, __LINE__);
#endif
    basestr = [NSString stringWithFormat:@"WIDTH %d, HEIGHT %d, CURSOR (%d,%d)",
		   WIDTH, HEIGHT, CURSOR_X, CURSOR_Y];
    result = [NSString stringWithFormat:@"%@\n%@", basestr, @""]; //colstr];

    return result;
}

-(void) initScreenWithWidth:(int)width Height:(int)height
{
	int total_height;
	int i;
	screen_char_t *aDefaultLine;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen initScreenWithWidth:%d Height:%d]", __FILE__, __LINE__, width, height );
#endif
	
	WIDTH=width;
	HEIGHT=height;
	CURSOR_X = CURSOR_Y = 0;
	SAVE_CURSOR_X = SAVE_CURSOR_Y = 0;
	SCROLL_TOP = 0;
	SCROLL_BOTTOM = HEIGHT - 1;	
	blinkShow=YES;
	
	// allocate our buffer to hold both scrollback and screen contents
	total_height = HEIGHT + max_scrollback_lines;
	buffer_chars = (screen_char_t *)malloc(total_height*WIDTH*sizeof(screen_char_t));
	
	// set up our pointers
	first_buffer_line = buffer_chars;
	last_buffer_line = buffer_chars + (total_height - 1)*WIDTH;
	screen_top = first_buffer_line;
	scrollback_top = first_buffer_line;
	
	// set all lines in buffer to default
	default_fg_code = [TERMINAL foregroundColorCode];
	default_bg_code = [TERMINAL backgroundColorCode];
	default_line_width = WIDTH;
	aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
	for(i = 0; i < HEIGHT; i++)
		memcpy([self _getLineAtIndex: i fromLine: first_buffer_line], aDefaultLine, WIDTH*sizeof(screen_char_t));
	
	// set current lines in scrollback
	current_scrollback_lines = 0;
	
	// set up our dirty flags buffer
	dirty=(char*)malloc(HEIGHT*WIDTH*sizeof(char));
	// force a redraw
	memset(dirty,1,HEIGHT*WIDTH*sizeof(char));	
		
}


- (void) acquireLock
{
	[screenLock lock];
}

- (void) releaseLock
{
	[screenLock unlock];
}

// gets line at specified index starting from scrollback_top
- (screen_char_t *) getLineAtIndex: (int) theIndex
{
	
	screen_char_t *theLinePointer;
	
	if(max_scrollback_lines == 0)
		theLinePointer = screen_top;
	else
		theLinePointer = scrollback_top;
	
	return ([self _getLineAtIndex:theIndex fromLine:theLinePointer]);
}

// gets line at specified index starting from screen_top
- (screen_char_t *) getLineAtScreenIndex: (int) theIndex
{
	return ([self _getLineAtIndex:theIndex fromLine:screen_top]);
}

// returns NSString representation of line
- (NSString *) getLineString: (screen_char_t *) theLine
{
	unichar *char_buf;
	NSString *theString;
	int i;
	
#if DEBUG_METHOD_TRACE
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif	
	
	char_buf = malloc(WIDTH*sizeof(unichar));
	
	for(i = 0; i < WIDTH; i++)
		char_buf[i] = theLine[i].ch;
	
	theString = [NSString stringWithCharacters: char_buf length: WIDTH];
	
	return (theString);
}


- (void)setWidth:(int)width height:(int)height
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setWidth:%d height:%d]",
          __FILE__, __LINE__, width, height);
#endif

    if (width >= MIN_WIDTH && height >= MIN_HEIGHT) {
        WIDTH = width;
        HEIGHT = height;
        CURSOR_X = CURSOR_Y = 0;
        SAVE_CURSOR_X = SAVE_CURSOR_Y = 0;
        SCROLL_TOP = 0;
        SCROLL_BOTTOM = HEIGHT - 1;
    }
}


- (void)resizeWidth:(int)width height:(int)height
{
    int i, sw, total_height, start_line;
	screen_char_t *screen_lines_top, *bl, *scroll_lines_top, *aLine, *targetLine;
	BOOL wrap = NO;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s:%d :%d]", __PRETTY_FUNCTION__, width, height);
#endif
	
	if(WIDTH == 0 || HEIGHT == 0)
		return;
		
	if (width==WIDTH && height==HEIGHT) return;
	
	// get lock
	[self acquireLock];
					
	// create a new buffer
	total_height = max_scrollback_lines + height;
	bl = (screen_char_t*)malloc(total_height*width*sizeof(screen_char_t));
	// set to default line
	aLine = [self _getDefaultLineWithWidth: width];
	for(i = 0; i < total_height; i++)
		memcpy(bl+width*i, aLine, width*sizeof(screen_char_t));
	
	// set up the width we need to copy
	sw = width<WIDTH?width:WIDTH;
	
	// copy over the old scrollback contents
	for(i = 0; i < current_scrollback_lines; i++) 
	{
		aLine = [self getLineAtIndex: i];
		memcpy(bl+width*i, aLine, sw*sizeof(screen_char_t));
	}
	scroll_lines_top = bl;
		
	// copy the screen content
	screen_lines_top = bl + current_scrollback_lines*width;
	if (HEIGHT <= height) //new screen is taller, so copy everything over
	{ 
		for(i = 0; i < HEIGHT; i++) 
		{
			aLine = [self getLineAtScreenIndex: i];
			memcpy(screen_lines_top+width*i, aLine, sw*sizeof(screen_char_t));
		}
	}
	else //new screen is shorter, so only copy the bottom part; put rest in scrollback area if we have one
	{ 
		targetLine = screen_lines_top;
		if(max_scrollback_lines == 0)
			start_line = HEIGHT-height; // we have no scrollback are, copy only bottom part
		else
			start_line = 0; // we have a scrollback area, copy top part into that
		wrap = NO;
		for(i = start_line; i < HEIGHT; i++)
		{
			aLine = [self getLineAtScreenIndex: i];
			if(i == start_line)
				targetLine = screen_lines_top;
			else
				targetLine = incrementLinePointer(bl, targetLine, total_height, width, &wrap);
			memcpy(targetLine, aLine, sw*sizeof(screen_char_t));
			
			// adjust screen_lines_top if needed
			if(i == (HEIGHT - height))
				screen_lines_top = targetLine;
			
			
			// increment our scrollback count if we are processing the top part
			if(i < (HEIGHT - height))
			{
				[self _addLineToScrollback];
				// adjust scroll_lines_top if needed (when scrollback area is full)
				if(targetLine == scroll_lines_top)
					scroll_lines_top = incrementLinePointer(bl, scroll_lines_top, total_height, width, &wrap);
			}
		}
		
		// adjust Y coordinate of cursor
		CURSOR_Y -= HEIGHT-height;
		if (CURSOR_Y < 0) 
			CURSOR_Y=0;
		SAVE_CURSOR_Y -= HEIGHT-height;
		if (SAVE_CURSOR_Y < 0) 
			SAVE_CURSOR_Y=0;
	}
	
	// reassign our pointers
	if(buffer_chars)
		free(buffer_chars);
	buffer_chars = bl;
	first_buffer_line = bl;
	last_buffer_line = bl + (total_height - 1)*width;
	screen_top = screen_lines_top;
	scrollback_top = scroll_lines_top;
	
	
	// new height and width
	WIDTH = width;
	HEIGHT = height;
	
	// reset terminal scroll top and bottom
	SCROLL_TOP = 0;
	SCROLL_BOTTOM = HEIGHT - 1;
	
	// adjust X coordinate of cursor
	if (CURSOR_X >= width) 
		CURSOR_X = width-1;
	if (SAVE_CURSOR_X >= width) 
		SAVE_CURSOR_X = width-1;
	
	// if we did the resize in SAVE_BUFFER mode, too bad, get rid of it
	if (temp_buffer) 
	{
		free(temp_buffer);
		temp_buffer=NULL;
	}
	
	// force a redraw
	if(dirty)
		free(dirty);
	dirty=(char*)malloc(height*width*sizeof(char));
	memset(dirty, 1, width*height*sizeof(char));
	[display setForceUpdate: YES];	
	
	// release lock
	[self releaseLock];
	
}

- (int)width
{
    return WIDTH;
}

- (int)height
{
    return HEIGHT;
}

- (unsigned int)scrollbackLines
{
    return max_scrollback_lines;
}

// sets scrollback lines.
- (void)setScrollback:(unsigned int)lines;
{
	// if we already have a buffer, don't allow this
	if(buffer_chars != NULL)
		return;
	
    max_scrollback_lines = lines;
}

- (PTYSession *) session
{
    return (SESSION);
}

- (void)setSession:(PTYSession *)session
{
#if DEBUG_METHOD_TRACE
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif	
    SESSION=session;
}

- (void)setTerminal:(VT100Terminal *)terminal
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setTerminal:%@]",
	  __FILE__, __LINE__, terminal);
#endif
    TERMINAL = terminal;
    
}

- (VT100Terminal *)terminal
{
    return TERMINAL;
}

- (void)setShellTask:(PTYTask *)shell
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setShellTask:%@]",
	  __FILE__, __LINE__, shell);
#endif
    SHELL = shell;
}

- (PTYTask *)shellTask
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen shellTask]", __FILE__, __LINE__);
#endif
    return SHELL;
}

- (PTYTextView *) display
{
    return (display);
}

- (void) setDisplay: (PTYTextView *) aDisplay
{
    display = aDisplay;
}

- (BOOL) blinkingCursor
{
    return (blinkingCursor);
}

- (void) setBlinkingCursor: (BOOL) flag
{
    blinkingCursor = flag;
}

- (void)putToken:(VT100TCC)token
{
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen putToken:%d]",__FILE__, __LINE__, token);
#endif
    int i,j,k;
	screen_char_t *aLine;
    
    [self acquireLock];
    
    switch (token.type) {
    // our special code
    case VT100_STRING:
		// check if we are in print mode
		if([self printToAnsi] == YES)
			[self printStringToAnsi: token.u.string];
		// else display string on screen
		else
			[self setString:token.u.string];
        break;
    case VT100_UNKNOWNCHAR: break;
    case VT100_NOTSUPPORT: break;

    //  VT100 CC
    case VT100CC_ENQ: break;
    case VT100CC_BEL: [self activateBell]; break;
    case VT100CC_BS:  [self backSpace]; break;
    case VT100CC_HT:  [self setTab]; break;
    case VT100CC_LF:
    case VT100CC_VT:
    case VT100CC_FF:
		if([self printToAnsi] == YES)
			[self printStringToAnsi: @"\n"];
		else
			[self setNewLine]; 
		break;
    case VT100CC_CR:  CURSOR_X = 0; break;
    case VT100CC_SO:  break;
    case VT100CC_SI:  break;
    case VT100CC_DC1: break;
    case VT100CC_DC3: break;
    case VT100CC_CAN:
    case VT100CC_SUB: break;
    case VT100CC_DEL: [self deleteCharacters:1];break;

    // VT100 CSI
    case VT100CSI_CPR: break;
    case VT100CSI_CUB: [self cursorLeft:token.u.csi.p[0]]; break;
    case VT100CSI_CUD: [self cursorDown:token.u.csi.p[0]]; break;
    case VT100CSI_CUF: [self cursorRight:token.u.csi.p[0]]; break;
    case VT100CSI_CUP: [self cursorToX:token.u.csi.p[1]
                                     Y:token.u.csi.p[0]];
        break;
    case VT100CSI_CUU: [self cursorUp:token.u.csi.p[0]]; break;
    case VT100CSI_DA:   [self deviceAttribute:token]; break;
    case VT100CSI_DECALN:
		for (i = 0; i < HEIGHT; i++) 
		{
			aLine = [self getLineAtScreenIndex: i];
			for(j = 0; j < WIDTH; j++)
			{
				aLine[j].ch ='E';
				aLine[j].fg_color = [TERMINAL foregroundColorCode];
				aLine[j].bg_color = [TERMINAL backgroundColorCode];
			}
		}
		memset(dirty,1,HEIGHT*WIDTH);
		break;
    case VT100CSI_DECDHL: break;
    case VT100CSI_DECDWL: break;
    case VT100CSI_DECID: break;
    case VT100CSI_DECKPAM: break;
    case VT100CSI_DECKPNM: break;
    case VT100CSI_DECLL: break;
    case VT100CSI_DECRC: [self restoreCursorPosition]; break;
    case VT100CSI_DECREPTPARM: break;
    case VT100CSI_DECREQTPARM: break;
    case VT100CSI_DECSC: [self saveCursorPosition]; break;
    case VT100CSI_DECSTBM: [self setTopBottom:token]; break;
    case VT100CSI_DECSWL: break;
    case VT100CSI_DECTST: break;
    case VT100CSI_DSR:  [self deviceReport:token]; break;
    case VT100CSI_ED:   [self eraseInDisplay:token]; break;
    case VT100CSI_EL:   [self eraseInLine:token]; break;
    case VT100CSI_HTS: tabStop[CURSOR_X]=YES; break;
    case VT100CSI_HVP: [self cursorToX:token.u.csi.p[1]
                                     Y:token.u.csi.p[0]];
        break;
    case VT100CSI_NEL:
        CURSOR_X=0;
    case VT100CSI_IND:
		if(CURSOR_Y == SCROLL_BOTTOM)
		{
			[self scrollUp];
		}
		else
		{
			CURSOR_Y++;
			if (CURSOR_Y>=HEIGHT) {
				CURSOR_Y=HEIGHT-1;
			}
		}
        break;
    case VT100CSI_RI:
		if(CURSOR_Y == SCROLL_TOP)
		{
			[self scrollDown];
		}
		else
		{
			CURSOR_Y--;
			if (CURSOR_Y<0) {
				CURSOR_Y=0;
			}	    
		}
		break;
    case VT100CSI_RIS: break;
    case VT100CSI_RM: break;
    case VT100CSI_SCS0: charset[0]=(token.u.code=='0'); break;
    case VT100CSI_SCS1: charset[1]=(token.u.code=='0'); break;
    case VT100CSI_SCS2: charset[2]=(token.u.code=='0'); break;
    case VT100CSI_SCS3: charset[3]=(token.u.code=='0'); break;
    case VT100CSI_SGR:  [self selectGraphicRendition:token]; break;
    case VT100CSI_SM: break;
    case VT100CSI_TBC:
        switch (token.u.csi.p[0]) {
            case 3: [self clearTabStop]; break;
            case 0: tabStop[CURSOR_X]=NO;
        }
        break;

    case VT100CSI_DECSET:
    case VT100CSI_DECRST:
        if (token.u.csi.p[0]==3 && [TERMINAL allowColumnMode] == YES) {
			// set the column
			[self releaseLock];
            [[SESSION parent] resizeWindow:([TERMINAL columnMode]?132:80)
                                    height:HEIGHT];
            [[SESSION TEXTVIEW] scrollEnd];
			return;
        }
        
        break;

    // ANSI CSI
    case ANSICSI_CHA:
        [self cursorToX: token.u.csi.p[0]];
	break;
    case ANSICSI_VPA:
        [self cursorToX: CURSOR_X+1 Y: token.u.csi.p[0]];
        break;
    case ANSICSI_VPR:
        [self cursorToX: CURSOR_X+1 Y: token.u.csi.p[0]+CURSOR_Y+1];
        break;
    case ANSICSI_ECH:
		i=WIDTH*CURSOR_Y+CURSOR_X;
		j=token.u.csi.p[0];
		if (j + CURSOR_X > WIDTH) 
			j = WIDTH - CURSOR_X;
		aLine = [self getLineAtScreenIndex: CURSOR_Y];
		for(k = 0; k < j; k++)
		{
			aLine[CURSOR_X+k].ch = 0;
			aLine[CURSOR_X+k].fg_color = [TERMINAL foregroundColorCode];
			aLine[CURSOR_X+k].bg_color = [TERMINAL backgroundColorCode];
		}
		memset(dirty+i,1,j);
		break;
        
    case STRICT_ANSI_MODE:
		[TERMINAL setStrictAnsiMode: ![TERMINAL strictAnsiMode]];
		break;

    case ANSICSI_PRINT:
		if(token.u.csi.p[0] == 4)
		{
			// print our stuff!!
			if([printToAnsiString length] > 0)
				[[SESSION TEXTVIEW] printContent: printToAnsiString];
			[printToAnsiString release];
			printToAnsiString = nil;
			[self setPrintToAnsi: NO];
		}
		else if (token.u.csi.p[0] == 5)
		{
			// allocate a string for the stuff to be printed
			if (printToAnsiString != nil)
				[printToAnsiString release];
			printToAnsiString = [[NSMutableString alloc] init];
			[self setPrintToAnsi: YES];
		}
		break;
	
    // XTERM extensions
    case XTERMCC_WIN_TITLE:
    case XTERMCC_WINICON_TITLE:
    case XTERMCC_ICON_TITLE:
        //[SESSION setName:token.u.string];
        if (token.type==XTERMCC_WIN_TITLE||token.type==XTERMCC_WINICON_TITLE) 
        {
	    //NSLog(@"setting window title to %@", token.u.string);
	    [SESSION setWindowTitle: token.u.string];
        }
        if (token.type==XTERMCC_ICON_TITLE||token.type==XTERMCC_WINICON_TITLE)
	{
	    //NSLog(@"setting session title to %@", token.u.string);
	    [SESSION setName:token.u.string];
	}
        break;
    case XTERMCC_INSBLNK: [self insertBlank:token.u.csi.p[0]]; break;
    case XTERMCC_INSLN: [self insertLines:token.u.csi.p[0]]; break;
    case XTERMCC_DELCH: [self deleteCharacters:token.u.csi.p[0]]; break;
    case XTERMCC_DELLN: [self deleteLines:token.u.csi.p[0]]; break;
        

    default:
		NSLog(@"%s(%d): bug?? token.type = %d", 
			__FILE__, __LINE__, token.type);
	break;
    }
//    NSLog(@"Done");
    [self releaseLock];
}

- (void)clearBuffer
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen clearBuffer]",  __FILE__, __LINE__ );
#endif
    
	[self clearScreen];
	[self clearScrollbackBuffer];
	
}

- (void)clearScrollbackBuffer
{
	int i;
	screen_char_t *aLine, *aDefaultLine;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen clearScrollbackBuffer]",  __FILE__, __LINE__ );
#endif
	
	[self acquireLock];

	if (max_scrollback_lines) 
	{
		aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
		for(i = 0; i < current_scrollback_lines; i++)
		{
			aLine = [self getLineAtIndex:i];
			memcpy(aLine, aDefaultLine, WIDTH*sizeof(screen_char_t));
		}
		
		current_scrollback_lines = 0;
		scrollback_top = screen_top;
		
	}
	
	[self releaseLock];
	
	[self updateScreen];
}

- (void) saveBuffer
{	
	int size=WIDTH*(HEIGHT+max_scrollback_lines);
	
#if DEBUG_METHOD_TRACE
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif	
	
	[self acquireLock];
	
	if (temp_buffer) 
		free(temp_buffer);
	
	temp_buffer=(screen_char_t *)malloc(size*(sizeof(screen_char_t)));
	memcpy(temp_buffer, first_buffer_line, size*sizeof(screen_char_t));
	saved_screen_top = screen_top;
	saved_scrollback_top = scrollback_top;
	saved_scrollback_lines = current_scrollback_lines;
		
	[self releaseLock];
}

- (void) restoreBuffer
{	
	int size=WIDTH*(HEIGHT+max_scrollback_lines);
	
#if DEBUG_METHOD_TRACE
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif	
	
	if (!temp_buffer) 
		return;
	
	memcpy(first_buffer_line, temp_buffer, size*sizeof(screen_char_t));
	screen_top = saved_screen_top;
	scrollback_top = saved_scrollback_top;
	current_scrollback_lines = saved_scrollback_lines;
	
		
	memset(dirty, 1, WIDTH*HEIGHT);
	
	free(temp_buffer);
	temp_buffer = NULL;
	
}

- (BOOL) printToAnsi
{
	return (printToAnsi);
}

- (void) setPrintToAnsi: (BOOL) aFlag
{
	printToAnsi = aFlag;
}

- (void) printStringToAnsi: (NSString *) aString
{
	if([aString length] > 0)
		[printToAnsiString appendString: aString];
}

- (void)setString:(NSString *)string
{
    int idx, screenIdx;
    int j, len, newx;
	screen_char_t *buffer;
	screen_char_t *aLine;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setString:%@ at %d]",
          __FILE__, __LINE__, string, CURSOR_X);
#endif

	if ([string length] < 1 || !string) 
	{
		NSLog(@"%s: invalid string '%@'", __PRETTY_FUNCTION__, string);
		return;		
	}
	
	buffer = (screen_char_t *) malloc( 2 * [string length] * sizeof(screen_char_t) );
	if (!buffer)
	{
		NSLog(@"%s: Out of memory", __PRETTY_FUNCTION__);
		return;		
	}
	
	padString(string,buffer,[SESSION doubleWidth], [TERMINAL foregroundColorCode], [TERMINAL backgroundColorCode], &len);
	
	// check for graphical characters
	if (charset[[TERMINAL charset]]) 
		translate(buffer,len);
	//    NSLog(@"%d(%d):%@",[TERMINAL charset],charset[[TERMINAL charset]],string);
	//NSLog(@"string:%s",s);
	
    if (len < 1) 
		return;

    for(idx = 0; idx < len;) 
	{
        if (CURSOR_X >= WIDTH) 
		{
            if ([TERMINAL wraparoundMode]) 
			{
                CURSOR_X=0;    
				[self setNewLine];
            }
            else 
			{
                CURSOR_X=WIDTH-1;
                idx=len-1;
            }
        }
		if(WIDTH - CURSOR_X <= len - idx) 
			newx = WIDTH;
		else 
			newx = CURSOR_X + len - idx;
		j = newx - CURSOR_X;

		if (j <= 0) {
			//NSLog(@"setASCIIString: output length=0?(%d+%d)%d+%d",CURSOR_X,j,idx2,len);
			break;
		}
		
		screenIdx = CURSOR_Y * WIDTH;
		aLine = [self getLineAtScreenIndex: CURSOR_Y];
		
        if ([TERMINAL insertMode]) 
		{
			if (CURSOR_X + j < WIDTH) 
			{
				memmove(aLine+CURSOR_X+j,aLine+CURSOR_X,(WIDTH-CURSOR_X-j)*sizeof(screen_char_t));
				memset(dirty+screenIdx+CURSOR_X,1,WIDTH-CURSOR_X);
			}
		}
		
		// insert as many characters as we can
		memcpy(aLine + CURSOR_X, buffer + idx, j * sizeof(screen_char_t));
		memset(dirty+screenIdx+CURSOR_X,1,j);
		
		CURSOR_X = newx;
		idx += j;
    }
	
	free(buffer);
	
#if DEBUG_METHOD_TRACE
    NSLog(@"setString done at %d", CURSOR_X);
#endif
}
        
- (void)setStringToX:(int)x
				   Y:(int)y
			  string:(NSString *)string 
{
    int sx, sy;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setStringToX:%d Y:%d string:%@]",
          __FILE__, __LINE__, x, y, string);
#endif

    sx = CURSOR_X;
    sy = CURSOR_Y;
    CURSOR_X = x;
    CURSOR_Y = y;
    [self setString:string]; 
    CURSOR_X = sx;
    CURSOR_Y = sy;
}

- (void)setNewLine
{
	screen_char_t *aLine;
	BOOL wrap = NO;
	int total_height;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setNewLine](%d,%d)-[%d,%d]", __FILE__, __LINE__, CURSOR_X, CURSOR_Y, SCROLL_TOP, SCROLL_BOTTOM);
#endif
	
    if (CURSOR_Y  < SCROLL_BOTTOM || (CURSOR_Y < (HEIGHT - 1) && CURSOR_Y > SCROLL_BOTTOM)) 
	{
		CURSOR_Y++;	
    }
    else if (SCROLL_TOP == 0 && SCROLL_BOTTOM == HEIGHT - 1) 
	{
		total_height = max_scrollback_lines + HEIGHT;
        
		// check how much of the screen we need to redraw
		if(current_scrollback_lines == max_scrollback_lines)
		{
			// we can't shove top line into scroll buffer, entire screen needs to be redrawn
			memset(dirty, 1, HEIGHT*WIDTH*sizeof(char));
		}
		else
		{
			// top line can move into scroll area; we need to draw only bottom line
			dirty[WIDTH*(CURSOR_Y-1)*sizeof(char)+CURSOR_X-1]=1;
			memmove(dirty, dirty+WIDTH*sizeof(char), WIDTH*(HEIGHT-1)*sizeof(char));
			memset(dirty+WIDTH*(HEIGHT-1)*sizeof(char),1,WIDTH*sizeof(char));			
		}
		
		// try to add top line to scroll area
		if(max_scrollback_lines > 0)
			[self _addLineToScrollback];
		
		// Increment screen_top pointer
		screen_top = incrementLinePointer(first_buffer_line, screen_top, total_height, WIDTH, &wrap);
		
		// set last screen line default
		aLine = [self getLineAtScreenIndex: (HEIGHT - 1)];
		memcpy(aLine, [self _getDefaultLineWithWidth: WIDTH], WIDTH*sizeof(screen_char_t));
		
    }
    else 
	{
        [self scrollUp];
    }
	
	
}

- (void)deleteCharacters:(int) n
{
	screen_char_t *aLine;
	int i;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen deleteCharacter]: %d", __FILE__, __LINE__, n);
#endif

    if (CURSOR_X >= 0 && CURSOR_X < WIDTH &&
        CURSOR_Y >= 0 && CURSOR_Y < HEIGHT)
    {
		int idx;
		
		idx=CURSOR_Y*WIDTH;		
		if (n+CURSOR_X>WIDTH) n=WIDTH-CURSOR_X;
		
		// get the appropriate screen line
		aLine = [self getLineAtScreenIndex: CURSOR_Y];
		
		if (n<WIDTH) 
		{
			memmove(aLine + CURSOR_X, aLine + CURSOR_X + n, (WIDTH-CURSOR_X-n)*sizeof(screen_char_t));
		}
		for(i = 0; i < n; i++)
		{
			aLine[WIDTH-n+i].ch = 0;
			aLine[WIDTH-n+i].fg_color = [TERMINAL foregroundColorCode];
			aLine[WIDTH-n+i].bg_color = [TERMINAL backgroundColorCode];
		}
		memset(dirty+idx+CURSOR_X,1,WIDTH-CURSOR_X);
    }
}

- (void)backSpace
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen backSpace]", __FILE__, __LINE__);
#endif
    if (CURSOR_X > 0) 
        CURSOR_X--;
}

- (void)setTab
{

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setTab]", __FILE__, __LINE__);
#endif

    CURSOR_X++; // ensure we go to the next tab in case we are already on one
    for(;!tabStop[CURSOR_X]&&CURSOR_X<WIDTH; CURSOR_X++);
}

- (void)clearScreen
{
	screen_char_t *aLine, *aDefaultLine;
	int i;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen clearScreen]; CURSOR_Y = %d", __FILE__, __LINE__, CURSOR_Y);
#endif
		
	if(CURSOR_Y < 0)
		return;
	
	[self acquireLock];
	
	// make the current line the first line and clear everything else
	aLine = [self getLineAtScreenIndex:CURSOR_Y];
	memcpy(screen_top, aLine, WIDTH*sizeof(screen_char_t));
	CURSOR_Y = 0;
	aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
	for (i = 1; i < HEIGHT; i++)
	{
		aLine = [self getLineAtScreenIndex:i];
		memcpy(aLine, aDefaultLine, WIDTH*sizeof(screen_char_t));
	}
	
	// all the screen is dirty
	memset(dirty, 1, WIDTH*HEIGHT);
	
	[self releaseLock];

}

- (void)eraseInDisplay:(VT100TCC)token
{
    int x1, y1, x2, y2;	
	int i, total_height;
	screen_char_t *aScreenChar;
	//BOOL wrap;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen eraseInDisplay:(param=%d); X = %d; Y = %d]",
          __FILE__, __LINE__, token.u.csi.p[0], CURSOR_X, CURSOR_Y);
#endif
    switch (token.u.csi.p[0]) {
    case 1:
        x1 = 0;
        y1 = 0;
        x2 = CURSOR_X+1;
        y2 = CURSOR_Y;
        break;

    case 2:
        x1 = 0;
        y1 = 0;
        x2 = 0;
        y2 = HEIGHT;
	
        break;

    case 0:
    default:
        x1 = CURSOR_X;
        y1 = CURSOR_Y;
        x2 = 0;
        y2 = HEIGHT;
        break;
    }
	

	int idx1, idx2;
	
	idx1=y1*WIDTH+x1;
	idx2=y2*WIDTH+x2;
	
	total_height = max_scrollback_lines + HEIGHT;
	
	// clear the contents between idx1 and idx2
	for(i = idx1, aScreenChar = screen_top + idx1; i < idx2; i++, aScreenChar++)
	{
		if(aScreenChar >= (first_buffer_line + total_height*WIDTH))
			aScreenChar = first_buffer_line; // wrap around to top of buffer
		aScreenChar->ch = 0;
		aScreenChar->fg_color = [TERMINAL foregroundColorCode];
		aScreenChar->bg_color = [TERMINAL backgroundColorCode];
	}
	
	memset(dirty+idx1,1,(idx2-idx1)*sizeof(char));
}

- (void)eraseInLine:(VT100TCC)token
{
	screen_char_t *aLine;
	int i;
	int idx, x1 ,x2;
	int fgCode, bgCode;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen eraseInLine:(param=%d); X = %d; Y = %d]",
          __FILE__, __LINE__, token.u.csi.p[0], CURSOR_X, CURSOR_Y);
#endif

	
	x1 = x2 = 0;
    switch (token.u.csi.p[0]) {
    case 1:
		x1=0;
		x2=CURSOR_X+1;
        break;
    case 2:
		x1 = 0;
		x2 = WIDTH;
		break;
    case 0:
		x1=CURSOR_X;
		x2=WIDTH;
		break;
	}
	idx=CURSOR_Y*WIDTH+x1;
	aLine = [self getLineAtScreenIndex: CURSOR_Y];
	
	// I'm commenting out the following code. I'm not sure about OpenVMS, but this code produces wrong result
	// when I use vttest program for testing the color features. --fabian
	
	// if we erasing entire lines, set to default foreground and background colors. Some systems (like OpenVMS)
	// do not send explicit video information
	//if(x1 == 0 && x2 == WIDTH)
	//{
	//	fgCode = DEFAULT_FG_COLOR_CODE;
	//	bgCode = DEFAULT_BG_COLOR_CODE;
	//}
	//else
	//{
		fgCode = [TERMINAL foregroundColorCode];
		bgCode = [TERMINAL backgroundColorCode];
	//}
		
	
	for(i = x1; i < x2; i++)
	{
		aLine[i].ch = 0;
		aLine[i].fg_color = fgCode;
		aLine[i].bg_color = bgCode;
	}
	memset(dirty+idx,1,(x2-x1)*sizeof(char));
}

- (void)selectGraphicRendition:(VT100TCC)token
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen selectGraphicRendition:...]",
	  __FILE__, __LINE__);
#endif
		
}

- (void)cursorLeft:(int)n
{
    int x = CURSOR_X - (n>0?n:1);

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorLeft:%d]", 
	  __FILE__, __LINE__, n);
#endif
    if (x < 0)
		x = 0;
    if (x >= 0 && x < WIDTH)
		CURSOR_X = x;
}

- (void)cursorRight:(int)n
{
    int x = CURSOR_X + (n>0?n:1);
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorRight:%d]", 
		  __FILE__, __LINE__, n);
#endif
    if (x >= WIDTH)
		x =  WIDTH - 1;
    if (x >= 0 && x < WIDTH)
		CURSOR_X = x;
}

- (void)cursorUp:(int)n
{
    int y = CURSOR_Y - (n>0?n:1);
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorUp:%d]", 
		  __FILE__, __LINE__, n);
#endif
    if(CURSOR_Y >= SCROLL_TOP)
		CURSOR_Y=y<SCROLL_TOP?SCROLL_TOP:y;
    else
		CURSOR_Y = y;
}

- (void)cursorDown:(int)n
{
    int y = CURSOR_Y + (n>0?n:1);
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorDown:%d, Y = %d; SCROLL_BOTTOM = %d]", 
		  __FILE__, __LINE__, n, CURSOR_Y, SCROLL_BOTTOM);
#endif
    if(CURSOR_Y <= SCROLL_BOTTOM)
		CURSOR_Y=y>SCROLL_BOTTOM?SCROLL_BOTTOM:y;
    else
		CURSOR_Y = y;
}

- (void) cursorToX: (int) x
{
    int x_pos;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorToX:%d]",
		  __FILE__, __LINE__, x);
#endif
    x_pos = (x-1);
	
    if(x_pos < 0)
		x_pos = 0;
    else if(x_pos >= WIDTH)
		x_pos = WIDTH - 1;
	
    CURSOR_X = x_pos;
	
}

- (void)cursorToX:(int)x Y:(int)y
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen cursorToX:%d Y:%d]", 
		  __FILE__, __LINE__, x, y);
#endif
    int x_pos, y_pos;
	
	
    x_pos = x - 1;
    y_pos = y - 1;
	
    if ([TERMINAL originMode]) y_pos += SCROLL_TOP;
	
    if(x_pos < 0)
		x_pos = 0;
    else if(x_pos >= WIDTH)
		x_pos = WIDTH - 1;
    if(y_pos < 0)
		y_pos = 0;
    else if(y_pos >= HEIGHT)
		y_pos = HEIGHT - 1;
	
    CURSOR_X = x_pos;
    CURSOR_Y = y_pos;
	
    
	//    NSParameterAssert(CURSOR_X >= 0 && CURSOR_X < WIDTH);
	
}

- (void)saveCursorPosition
{
    int i;
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen saveCursorPosition]", 
		  __FILE__, __LINE__);
#endif
	
    if(CURSOR_X < 0)
		CURSOR_X = 0;
    if(CURSOR_X >= WIDTH)
		CURSOR_X = WIDTH-1;
    if(CURSOR_Y < 0)
		CURSOR_Y = 0;
    if(CURSOR_Y >= HEIGHT)
		CURSOR_Y = HEIGHT;
	
    SAVE_CURSOR_X = CURSOR_X;
    SAVE_CURSOR_Y = CURSOR_Y;
	
    for(i=0;i<4;i++) saveCharset[i]=charset[i];
	
}

- (void)restoreCursorPosition
{
    int i;
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen restoreCursorPosition]", 
		  __FILE__, __LINE__);
#endif
    CURSOR_X = SAVE_CURSOR_X;
    CURSOR_Y = SAVE_CURSOR_Y;
	
    for(i=0;i<4;i++) charset[i]=saveCharset[i];
    
    NSParameterAssert(CURSOR_X >= 0 && CURSOR_X < WIDTH);
    NSParameterAssert(CURSOR_Y >= 0 && CURSOR_Y < HEIGHT);
}

- (void)setTopBottom:(VT100TCC)token
{
    int top, bottom;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen setTopBottom:(%d,%d)]", 
	  __FILE__, __LINE__, token.u.csi.p[0], token.u.csi.p[1]);
#endif

    top = token.u.csi.p[0] == 0 ? 0 : token.u.csi.p[0] - 1;
    bottom = token.u.csi.p[1] == 0 ? HEIGHT - 1 : token.u.csi.p[1] - 1;
    if (top >= 0 && top < HEIGHT &&
        bottom >= 0 && bottom < HEIGHT &&
        bottom >= top)
    {
        SCROLL_TOP = top;
        SCROLL_BOTTOM = bottom;

		if ([TERMINAL originMode]) {
			CURSOR_X = 0;
			CURSOR_Y = SCROLL_TOP;
		}
		else {
			CURSOR_X = 0;
			CURSOR_Y = 0;
		}
    }
}

- (void)scrollUp
{
	int total_height;
	int i;
	screen_char_t *sourceLine, *targetLine;
	BOOL wrap;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen scrollUp]", __FILE__, __LINE__);
#endif

    NSParameterAssert(SCROLL_TOP >= 0 && SCROLL_TOP < HEIGHT);
    NSParameterAssert(SCROLL_BOTTOM >= 0 && SCROLL_BOTTOM < HEIGHT);
    NSParameterAssert(SCROLL_TOP <= SCROLL_BOTTOM );
	
	total_height = max_scrollback_lines + HEIGHT;


    if (SCROLL_BOTTOM >= HEIGHT-1 || SCROLL_TOP == 0) 
	{
		// move top line of current screen area into scrollback area by incrementing screen_top pointer
		screen_top = incrementLinePointer(first_buffer_line, screen_top, total_height, WIDTH, &wrap);
		// move the line to buffer
		if(max_scrollback_lines > 0)
			[self _addLineToScrollback];
		
		// we have make room for the new line at SCROLL_BOTTOM; move all lines from SCROLL_BOTTOM and below down one line
		for(i = HEIGHT - 2; i >= SCROLL_BOTTOM ; i--)
		{
			sourceLine = [self getLineAtScreenIndex:i];
			targetLine = [self getLineAtScreenIndex:i+1];
			memmove(targetLine, sourceLine, WIDTH*sizeof(screen_char_t));
		}
		
		// we force a refresh at the bottom and the old cursor location
        dirty[WIDTH*(CURSOR_Y-1)*sizeof(char)+CURSOR_X-1]=1;
        memmove(dirty, dirty+WIDTH*sizeof(char), WIDTH*(HEIGHT-1)*sizeof(char));
        memset(dirty+WIDTH*(HEIGHT-1)*sizeof(char),1,WIDTH*sizeof(char));
        
	}
	else if (SCROLL_TOP<SCROLL_BOTTOM) 
	{
		// SCROLL_TOP is not top of screen; move all lines between SCROLL_TOP and SCROLL_BOTTOM one line up
		// check if the screen area is wrapped
		sourceLine = [self getLineAtScreenIndex: SCROLL_TOP];
		targetLine = [self getLineAtScreenIndex: SCROLL_BOTTOM];
		if(sourceLine < targetLine)
		{
			// screen area is not wrapped; direct memmove
			memmove(screen_top+SCROLL_TOP*WIDTH, screen_top+(SCROLL_TOP+1)*WIDTH, (SCROLL_BOTTOM-SCROLL_TOP)*WIDTH*sizeof(screen_char_t));
		}
		else
		{
			// screen area is wrapped; copy line by line
			for(i = SCROLL_TOP; i < SCROLL_BOTTOM; i++)
			{
				sourceLine = [self getLineAtScreenIndex:i+1];
				targetLine = [self getLineAtScreenIndex: i];
				memmove(targetLine, sourceLine, WIDTH*sizeof(screen_char_t));
			}
		}
	}
	// new line at SCROLL_BOTTOM with default settings
	targetLine = [self getLineAtScreenIndex:SCROLL_BOTTOM];
	memcpy(targetLine, [self _getDefaultLineWithWidth: WIDTH], WIDTH*sizeof(screen_char_t));

	// everything between SCROLL_TOP and SCROLL_BOTTOM is dirty
	memset(dirty+SCROLL_TOP*WIDTH,1,(SCROLL_BOTTOM-SCROLL_TOP+1)*WIDTH*sizeof(char));
}

- (void)scrollDown
{
	int i;
	screen_char_t *sourceLine, *targetLine;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen scrollDown]", __FILE__, __LINE__);
#endif
	
    NSParameterAssert(SCROLL_TOP >= 0 && SCROLL_TOP < HEIGHT);
    NSParameterAssert(SCROLL_BOTTOM >= 0 && SCROLL_BOTTOM < HEIGHT);
    NSParameterAssert(SCROLL_TOP <= SCROLL_BOTTOM );
	
	if (SCROLL_TOP<SCROLL_BOTTOM) 
	{
		// move all lines between SCROLL_TOP and SCROLL_BOTTOM one line down
		// check if screen is wrapped
		sourceLine = [self getLineAtScreenIndex:SCROLL_TOP];
		targetLine = [self getLineAtScreenIndex:SCROLL_BOTTOM];
		if(sourceLine < targetLine)
		{
			// screen area is not wrapped; direct memmove
			memmove(screen_top+(SCROLL_TOP+1)*WIDTH, screen_top+SCROLL_TOP*WIDTH, (SCROLL_BOTTOM-SCROLL_TOP)*WIDTH*sizeof(screen_char_t));
		}
		else
		{
			// screen area is wrapped; move line by line
			for(i = SCROLL_BOTTOM - 1; i >= SCROLL_TOP; i--)
			{
				sourceLine = [self getLineAtScreenIndex:i];
				targetLine = [self getLineAtScreenIndex:i+1];
				memmove(targetLine, sourceLine, WIDTH*sizeof(screen_char_t));
			}
		}
	}
	// new line at SCROLL_TOP with default settings
	targetLine = [self getLineAtScreenIndex:SCROLL_TOP];
	memcpy(targetLine, [self _getDefaultLineWithWidth: WIDTH], WIDTH*sizeof(screen_char_t));
	
	// everything between SCROLL_TOP and SCROLL_BOTTOM is dirty
	memset(dirty+SCROLL_TOP*WIDTH,1,(SCROLL_BOTTOM-SCROLL_TOP+1)*WIDTH*sizeof(char));
}

- (void) insertBlank: (int)n
{
	screen_char_t *aLine;
	int i;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen insertBlank; %d]", __FILE__, __LINE__, n);
#endif

 
//    NSLog(@"insertBlank[%d@(%d,%d)]",n,CURSOR_X,CURSOR_Y);

	int screenIdx=CURSOR_Y*WIDTH+CURSOR_X;
	
	// get the appropriate line
	aLine = [self getLineAtScreenIndex:CURSOR_Y];
	
	memmove(aLine + CURSOR_X + n,aLine + CURSOR_X,(WIDTH-CURSOR_X-n)*sizeof(screen_char_t));
	
	for(i = 0; i < n; i++)
	{
		aLine[CURSOR_X+i].ch = 0;
		aLine[CURSOR_X+i].fg_color = [TERMINAL foregroundColorCode];
		aLine[CURSOR_X+i].bg_color = [TERMINAL backgroundColorCode];
	}
	
	// everything from CURSOR_X to end of line is dirty
	memset(dirty+screenIdx,1,WIDTH-CURSOR_X);
	
}

- (void) insertLines: (int)n
{
	int i, num_lines_moved;
	screen_char_t *sourceLine, *targetLine, *aDefaultLine;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen insertLines; %d]", __FILE__, __LINE__, n);
#endif
    
    
//    NSLog(@"insertLines %d[%d,%d]",n, CURSOR_X,CURSOR_Y);
	if (n+CURSOR_Y<=SCROLL_BOTTOM) 
	{
		
		// number of lines we can move down by n before we hit SCROLL_BOTTOM
		num_lines_moved = SCROLL_BOTTOM - (CURSOR_Y + n);
		// start from lower end
		for(i = num_lines_moved ; i >= 0; i--)
		{
			sourceLine = [self getLineAtScreenIndex: CURSOR_Y + i];
			targetLine = [self getLineAtScreenIndex:CURSOR_Y + i + n];
			memcpy(targetLine, sourceLine, WIDTH*sizeof(screen_char_t));
		}
		
	}
	if (n+CURSOR_Y>SCROLL_BOTTOM) 
		n=SCROLL_BOTTOM-CURSOR_Y+1;
	
	// clear the n lines
	aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
	for(i = 0; i < n; i++)
	{
		sourceLine = [self getLineAtScreenIndex:CURSOR_Y+i];
		memcpy(sourceLine, aDefaultLine, WIDTH*sizeof(screen_char_t));
	}
	
	// everything between CURSOR_Y and SCROLL_BOTTOM is dirty
	memset(dirty+CURSOR_Y*WIDTH,1,(SCROLL_BOTTOM-CURSOR_Y+1)*WIDTH);
}

- (void) deleteLines: (int)n
{
	int i, num_lines_moved;
	screen_char_t *sourceLine, *targetLine, *aDefaultLine;

#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen deleteLines; %d]", __FILE__, __LINE__, n);
#endif
    
	//    NSLog(@"insertLines %d[%d,%d]",n, CURSOR_X,CURSOR_Y);
	if (n+CURSOR_Y<=SCROLL_BOTTOM) 
	{		
		// number of lines we can move down by n before we hit SCROLL_BOTTOM
		num_lines_moved = SCROLL_BOTTOM - (CURSOR_Y + n);
		
		for (i = 0; i <= num_lines_moved; i++)
		{
			sourceLine = [self getLineAtScreenIndex:CURSOR_Y + i + n];
			targetLine = [self getLineAtScreenIndex: CURSOR_Y + i];
			memcpy(targetLine, sourceLine, WIDTH*sizeof(screen_char_t));
		}
		
	}
	if (n+CURSOR_Y>SCROLL_BOTTOM) 
		n=SCROLL_BOTTOM-CURSOR_Y+1;
	// clear the n lines
	aDefaultLine = [self _getDefaultLineWithWidth: WIDTH];
	for(i = 0; i < n; i++)
	{
		sourceLine = [self getLineAtScreenIndex:SCROLL_BOTTOM-n+1+i];
		memcpy(sourceLine, aDefaultLine, WIDTH*sizeof(screen_char_t));
	}
	
	// everything between CURSOR_Y and SCROLL_BOTTOM is dirty
	memset(dirty+CURSOR_Y*WIDTH,1,(SCROLL_BOTTOM-CURSOR_Y+1)*WIDTH);
	
}

- (void)setPlayBellFlag:(BOOL)flag
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):+[VT100Screen setPlayBellFlag:%s]",
		  __FILE__, __LINE__, flag == YES ? "YES" : "NO");
#endif
    PLAYBELL = flag;
}

- (void)setShowBellFlag:(BOOL)flag
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):+[VT100Screen setShowBellFlag:%s]",
		  __FILE__, __LINE__, flag == YES ? "YES" : "NO");
#endif
    SHOWBELL = flag;
}

- (void)activateBell
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen playBell]",  __FILE__, __LINE__);
#endif
    if (PLAYBELL) {
		NSBeep();
    }
	if (SHOWBELL)
	{
		[SESSION setBell];
	}
}

- (void)deviceReport:(VT100TCC)token
{
    NSData *report = nil;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen deviceReport:%d]", 
		  __FILE__, __LINE__, token.u.csi.p[0]);
#endif
    if (SHELL == nil)
		return;
	
    switch (token.u.csi.p[0]) {
		case 3: // response from VT100 -- Malfunction -- retry
			break;
			
		case 5: // Command from host -- Please report status
			report = [TERMINAL reportStatus];
			break;
			
		case 6: // Command from host -- Please report active position
        {
			int x, y;
			
			if ([TERMINAL originMode]) {
				x = CURSOR_X + 1;
				y = CURSOR_Y - SCROLL_TOP + 1;
			}
			else {
				x = CURSOR_X + 1;
				y = CURSOR_Y + 1;
			}
			report = [TERMINAL reportActivePositionWithX:x Y:y];
		}
			break;
			
		case 0: // Response from VT100 -- Ready, No malfuctions detected
		default:
			break;
    }
	
    if (report != nil) {
		[SHELL writeTask:report];
    }
}

- (void)deviceAttribute:(VT100TCC)token
{
    NSData *report = nil;
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[VT100Screen deviceAttribute:%d, modifier = '%c']", 
		  __FILE__, __LINE__, token.u.csi.p[0], token.u.csi.modifier);
#endif
    if (SHELL == nil)
		return;
	
	if(token.u.csi.modifier == '>')
		report = [TERMINAL reportSecondaryDeviceAttribute];
	else
		report = [TERMINAL reportDeviceAttribute];
	
    if (report != nil) {
		[SHELL writeTask:report];
    }
}

- (void)blink
{
	
    if (memchr(dirty, 1, WIDTH*HEIGHT)) {
        [self updateScreen];
    }     
	
}

- (int) cursorX
{
    return CURSOR_X+1;
}

- (int) cursorY
{
    return CURSOR_Y+1;
}

- (void) clearTabStop
{
    int i;
    for(i=0;i<300;i++) tabStop[i]=NO;
}

- (int) numberOfLines
{
	int num_lines_in_scrollback;
	
	num_lines_in_scrollback = (current_scrollback_lines > max_scrollback_lines)?max_scrollback_lines:current_scrollback_lines;
	
    return (num_lines_in_scrollback+HEIGHT);
}


- (void) updateScreen
{
    [display refresh];
}

- (char	*)dirty			
{
	return dirty; 
}


- (void)resetDirty
{
	memset(dirty,0,WIDTH*HEIGHT*sizeof(char));
}

- (void)setDirty
{
	memset(dirty,1,WIDTH*HEIGHT*sizeof(char));
	[display setForceUpdate: YES];
}

@end

@implementation VT100Screen (Private)

// gets line offset by specified index from specified line poiner; accounts for buffer wrap
- (screen_char_t *) _getLineAtIndex: (int) anIndex fromLine: (screen_char_t *) aLine
{
	screen_char_t *the_line = NULL;	
	int pre_wrap, post_wrap;
		
	if(anIndex < 0)
		return (NULL);
	
	// get the line offset from the specified line
	the_line = aLine + anIndex*WIDTH;
	
	// check if we have gone beyond our buffer; if so, we need to wrap around to the top of buffer
	if(the_line > last_buffer_line)
	{
		pre_wrap = (last_buffer_line - aLine)/WIDTH + 1; // accounting for lines at bottom
		post_wrap = anIndex - pre_wrap; // accounting for lines at top
		the_line = first_buffer_line + post_wrap*WIDTH;
	}
	
	return (the_line);
}

// returns a line set to default character and attributes
// released when session is closed
- (screen_char_t *) _getDefaultLineWithWidth: (int) width
{
	int i;
		
	// check if we have to generate a new line
	if(default_line && default_fg_code == [TERMINAL foregroundColorCode] && 
	   default_bg_code == [TERMINAL backgroundColorCode] && default_line_width == width)
		return (default_line);
	
	if(default_line)
		free(default_line);
	
	default_line = (screen_char_t *)malloc(width*sizeof(screen_char_t));
	
	for(i = 0; i < width; i++)
	{
		default_line[i].ch = 0;
		default_line[i].fg_color = [TERMINAL foregroundColorCode];
		default_line[i].bg_color = [TERMINAL backgroundColorCode];
	}
	
	default_fg_code = [TERMINAL foregroundColorCode];
	default_bg_code = [TERMINAL backgroundColorCode];
	default_line_width = width;
	
	return (default_line);
	
}


// adds a line to scrollback area. Returns YES if oldest line is lost, NO otherwise
- (BOOL) _addLineToScrollback
{
	BOOL lost_oldest_line = NO;
	BOOL wrap;
	
#if DEBUG_METHOD_TRACE
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif	
	
	if(max_scrollback_lines && ++current_scrollback_lines > max_scrollback_lines)
	{
		// scrollback area is full; lose oldest line
		scrollback_top = incrementLinePointer(first_buffer_line, scrollback_top, max_scrollback_lines+HEIGHT, WIDTH, &wrap);
		current_scrollback_lines = max_scrollback_lines;
		lost_oldest_line = YES;
	}
	
	return (lost_oldest_line);
}

@end

