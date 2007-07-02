/*
   Copyright (c) 2007 <zetawoof gmail>
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#import "TTY.h"
#import <sys/select.h>
#import <termios.h> // for termio
#import <unistd.h>
#import <sys/ioctl.h> // for ioctl
#ifdef LINUX
#import <pty.h>
#endif
#ifdef DARWIN
#import <util.h> // forkpty
#endif
#ifdef FREEBSD
#include <sys/types.h>
#include <sys/ioctl.h> 
#include <termios.h>
#include <libutil.h>
#endif
#import "GNUstep.h"

#define CTRLKEY(x) (x - 64)

@implementation TTY

- (id)initWithColumns: (int) cols rows: (int) rows;
{
	struct termios termio;
	
	bzero(&termio, sizeof(termio));
	
	termio.c_iflag = ICRNL | IXON | IXANY | IMAXBEL | BRKINT;
	termio.c_oflag = OPOST | ONLCR;
	termio.c_cflag = CREAD | CS8 | HUPCL;
	termio.c_lflag = ICANON | ISIG | IEXTEN | ECHO | ECHOE | ECHOKE | ECHOCTL;
	
	termio.c_cc[VEOF]      = CTRLKEY('D');
	termio.c_cc[VEOL]      = -1;
	termio.c_cc[VEOL2]     = -1;
	termio.c_cc[VERASE]    = 0x7f;	// DEL
	termio.c_cc[VWERASE]   = CTRLKEY('W');
	termio.c_cc[VKILL]     = CTRLKEY('U');
	termio.c_cc[VREPRINT]  = CTRLKEY('R');
	termio.c_cc[VINTR]     = CTRLKEY('C');
	termio.c_cc[VQUIT]     = 0x1c;	// Control+backslash
	termio.c_cc[VSUSP]     = CTRLKEY('Z');
#ifndef LINUX
	termio.c_cc[VDSUSP]    = CTRLKEY('Y');
#endif
	termio.c_cc[VSTART]    = CTRLKEY('Q');
	termio.c_cc[VSTOP]     = CTRLKEY('S');
	termio.c_cc[VLNEXT]    = -1;
	termio.c_cc[VDISCARD]  = -1;
	termio.c_cc[VMIN]      = 1;
	termio.c_cc[VTIME]     = 0;
#ifndef LINUX
	termio.c_cc[VSTATUS]   = -1;
#endif
	
	termio.c_ispeed = B115200;
	termio.c_ospeed = B115200;
	
	char tty[512];
	int term_fd;
	struct winsize ws;
	ws.ws_col = cols;
	ws.ws_row = rows;
	pid_t p = forkpty(&term_fd, tty, &termio, &ws);
	if (p < 0) 
	{
		NSLog(@"Failure in forkpty");
		return self;
	} 
	else if (p == 0) 
	{
		setsid();
		char *shell = getenv("SHELL");
		if(!shell) shell = "/bin/sh";
		setenv("TERM", "vt100", 1);
//		setenv("TERM", "xterm-color", 1);
		execl(shell, "-", NULL);
		NSLog(@"exec failure!");
		exit(255);
	}

	term = [[NSFileHandle alloc] initWithFileDescriptor: term_fd
										 closeOnDealloc: YES];

	[[NSNotificationCenter defaultCenter] 
					addObserver:self
					selector:@selector(gotData:)
					name:NSFileHandleDataAvailableNotification
					object:term];
	[term waitForDataInBackgroundAndNotify];

	delegate = nil;
	alive = YES;
	
	return self;
}

- (void) processData: (id) sender
{
	[delegate performSelector: @selector(tty:gotInput:)
	               withObject: self withObject: appendingData];
//	NSLog(@"Fire data %d", [appendingData length]);
	/* Clean up */
	DESTROY(appendingData);
	DESTROY(processTimer);
}

- (void) gotData: (NSNotification *) notification
{
//	NSLog(@"got data");
	NSData *d = nil;
NS_DURING
	d = [term availableData];
NS_HANDLER
	/* If we are notified but got exception here, the connection is dead. */
	alive = NO;
	NSLog(@"Not alive");
	return;
NS_ENDHANDLER
	if ([d length] == 0) 
	{
		[delegate performSelector: @selector(tty:closed:)
		               withObject: self withObject: self];
		alive = NO;
		NSLog(@"Not alive");
		return;
	}
	/* We cache data here in case the buffer for term is full */
	if (appendingData == nil)
	{
		appendingData = [[NSMutableData alloc] init];
	}
	[appendingData appendData: d];

#if 1
	if ([appendingData length] > 512)
	{
		/* If the data is big, we process immediately.
		   This will cause redraw every 512 bytes. */
		[delegate performSelector: @selector(tty:gotInput:)
		               withObject: self withObject: appendingData];
		DESTROY(appendingData);
	}
	else if (processTimer == nil)
	{
		/* Sleep a short time so data can accumulate.
		   It helps a lot in speed. */
		ASSIGN(processTimer, [NSTimer scheduledTimerWithTimeInterval: 0.05
		                                 target: self
		                               selector: @selector(processData:)
		                               userInfo: nil
		                                repeats: NO]);
		// NOTE: I think there is a racing issue between timer
		// and -waitForDataInBackgroundAndNotify.
	}
#else
	[delegate performSelector: @selector(tty:gotInput:)
	               withObject: self withObject: appendingData];
	DESTROY(appendingData);
#endif
NS_DURING
	[term waitForDataInBackgroundAndNotify];
NS_HANDLER
	NSLog(@"waitForDataInBackgroundAndNotify exception");
NS_ENDHANDLER
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate: (id) d
{
	ASSIGN(delegate, d);
}

- (void) writeData: (NSData *) data
{
	if (!alive) 
		return;
	[term writeData:data];
}

- (void) writeString: (NSString *) text
{
	if (!alive) 
		return;
	[self writeData: [NSData dataWithBytesNoCopy:(char *) [text cString]
										 length:[text cStringLength]
								 freeWhenDone:NO]];
}

- (void) windowSizedWithRows: (int) rows cols: (int) cols
{
	struct winsize ws;
	if (!alive) 
		return;
	ws.ws_col = cols;
	ws.ws_row = rows;
	ws.ws_xpixel = ws.ws_ypixel = 0;
	ioctl([term fileDescriptor], TIOCSWINSZ, &ws);
}

- (void)dealloc
{
	DESTROY(term);
	DESTROY(delegate);
	DESTROY(appendingData);
	[super dealloc];
}

@end
