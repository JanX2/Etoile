// -*- mode:objc -*-
// $Id: PTYTask.m,v 1.34 2006/03/03 22:30:47 ujwal Exp $
//
/*
 **  PTYTask.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian, Ujwal S. Setlur
 **	     Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: Implements the interface to the pty session.
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
#define DEBUG_THREAD          0
#define DEBUG_ALLOC           0
#define DEBUG_METHOD_TRACE    0

#import <stdio.h>
#import <stdlib.h>
#import <unistd.h>

#if defined(__APPLE__) || defined(__NetBSD__) || defined(__OpenBSD__)
#import <util.h>
#elseif defined(__FreeBSD__) || defined (__DragonFly__)
#import <libutil.h>
#endif

// For term commands
#ifndef __APPLE__
#import <termios.h>
#endif

// For forkpty
#ifdef __LINUX__
#import <pty.h>
#endif

#import <sys/ioctl.h>
#import <sys/types.h>
#import <sys/wait.h>
#import <sys/time.h>

#import <iTerm/PTYTask.h>

@implementation PTYTask

#define CTRLKEY(c)   ((c)-'A'+1)

static void setup_tty_param(struct termios *term,
							struct winsize *win,
							int width,
							int height)
{
    memset(term, 0, sizeof(struct termios));
    memset(win, 0, sizeof(struct winsize));
	
    term->c_iflag = ICRNL | IXON | IXANY | IMAXBEL | BRKINT;
    term->c_oflag = OPOST | ONLCR;
    term->c_cflag = CREAD | CS8 | HUPCL;
    term->c_lflag = ICANON | ISIG | IEXTEN | ECHO | ECHOE | ECHOKE | ECHOCTL;
	
    term->c_cc[VEOF]      = CTRLKEY('D');
    term->c_cc[VEOL]      = -1;
    term->c_cc[VEOL2]     = -1;
    term->c_cc[VERASE]    = 0x7f;	// DEL
    term->c_cc[VWERASE]   = CTRLKEY('W');
    term->c_cc[VKILL]     = CTRLKEY('U');
    term->c_cc[VREPRINT]  = CTRLKEY('R');
    term->c_cc[VINTR]     = CTRLKEY('C');
    term->c_cc[VQUIT]     = 0x1c;	// Control+backslash
    term->c_cc[VSUSP]     = CTRLKEY('Z');
#ifndef __linux__
// NOTE: VDSUSP is not POSIX compliant and not supported by Linux
    term->c_cc[VDSUSP]    = CTRLKEY('Y');
#endif
    term->c_cc[VSTART]    = CTRLKEY('Q');
    term->c_cc[VSTOP]     = CTRLKEY('S');
    term->c_cc[VLNEXT]    = -1;
    term->c_cc[VDISCARD]  = -1;
    term->c_cc[VMIN]      = 1;
    term->c_cc[VTIME]     = 0;
#ifndef __linux__
// NOTE: Idem
    term->c_cc[VSTATUS]   = -1;
#endif
	
    term->c_ispeed = B38400;
    term->c_ospeed = B38400;
	
    win->ws_row = height;
    win->ws_col = width;
    win->ws_xpixel = 0;
    win->ws_ypixel = 0;
}

static int writep(int fds, char *buf, size_t len)
{
    int wrtlen = len;
    int result = 0;
    int sts = 0;
    char *tmpPtr = buf;
    int chunk;
    struct timeval tv;
    fd_set wfds,efds;
	
    while (wrtlen > 0) {
		
		FD_ZERO(&wfds);
		FD_ZERO(&efds);
		FD_SET(fds, &wfds);
		FD_SET(fds, &efds);	
		
		tv.tv_sec = 0;
		tv.tv_usec = 100000;
		
		sts = select(fds + 1, NULL, &wfds, &efds, &tv);
		
		if (sts == 0) {
			NSLog(@"Write timeout!");
			break;
		}	
		
		if(wrtlen > 1024)
			chunk = 1024;
		else
			chunk = wrtlen;
		sts = write(fds, tmpPtr, wrtlen);
		if (sts <= 0)
			break;
		
		wrtlen -= sts;
		tmpPtr += sts;
		
    }
    if (sts <= 0)
		result = sts;
    else
		result = len;
	
    return result;
}

+ (void)_processReadThread:(PTYTask *)boss
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL exitf = NO;
    int sts;
	int iterationCount = 0;
	NSAutoreleasePool *arPool = nil;
	NSConnection *clientConnection;
	id rootProxy;
	char readbuf[4096];
	fd_set rfds,efds;
	
#if DEBUG_THREAD
    NSLog(@"%s(%d):+[PTYTask _processReadThread:%@] start",
		  __FILE__, __LINE__, [boss description]);
#endif
	
	// establish a connection to the PTYTask instance
	clientConnection = [NSConnection connectionWithReceivePort:boss->sendPort sendPort:boss->recvPort];
	rootProxy = [clientConnection rootProxy];
    
    /*
	 data receive loop
	 */
	iterationCount = 0; 
    while (exitf == NO) 
	{
		
		// periodically refresh our autorelease pool
		iterationCount++;
		if(arPool == nil)
			arPool = [[NSAutoreleasePool alloc] init];
		
		FD_ZERO(&rfds);
		FD_ZERO(&efds);
		FD_SET(boss->FILDES, &rfds);
		FD_SET(boss->FILDES, &efds);
		
		sts = select(boss->FILDES + 1, &rfds, NULL, &efds, NULL);
		
		if (sts < 0) {
			break;
		}
		else if (FD_ISSET(boss->FILDES, &efds)) {
			sts = read(boss->FILDES, readbuf, 1);
#if 0 // debug
			fprintf(stderr, "read except:%d byte ", sts);
			if (readbuf[0] & TIOCPKT_FLUSHREAD)
				fprintf(stderr, "TIOCPKT_FLUSHREAD ");
			if (readbuf[0] & TIOCPKT_FLUSHWRITE)
				fprintf(stderr, "TIOCPKT_FLUSHWRITE ");
			if (readbuf[0] & TIOCPKT_STOP)
				fprintf(stderr, "TIOCPKT_STOP ");
			if (readbuf[0] & TIOCPKT_START)
				fprintf(stderr, "TIOCPKT_START ");
			if (readbuf[0] & TIOCPKT_DOSTOP)
				fprintf(stderr, "TIOCPKT_DOSTOP ");
			if (readbuf[0] & TIOCPKT_NOSTOP)
				fprintf(stderr, "TIOCPKT_NOSTOP ");
			fprintf(stderr, "\n");
#endif
			if (sts == 0) {
				// session close
				exitf = YES;
			}
		}
		else if (FD_ISSET(boss->FILDES, &rfds)) {
			sts = read(boss->FILDES, readbuf, sizeof(readbuf));
			
            if (sts == 0) 
			{
				exitf = YES;
            }
			
            if (sts > 1) {
				// use boss instead of rootProxy for performance
                [boss setHasOutput: YES];
				[boss readTask:readbuf+1 length:sts-1];
            }
            else
                [boss setHasOutput: NO];
			
		}
		
		// periodically refresh our autorelease pool
		if((iterationCount % 10) == 0)
		{
			[arPool release];
			arPool = nil;
			iterationCount = 0;
		}
		
    }
	
	// use the rootProxy through the clientConnection to close session
	// not using the clientConnection causes tab redraw problems
	if(sts >= 0)
		[rootProxy brokenPipe];
			
	if(arPool != nil)
	{
		[arPool release];
		arPool = nil;
	}
	
#if DEBUG_THREAD
    NSLog(@"%s(%d):+[PTYTask _processReadThread:] finish",
		  __FILE__, __LINE__);
#endif
	
    [pool release];

#ifdef __APPLE__	
    MPSignalSemaphore(boss->threadEndSemaphore);
#else
    pthread_mutex_lock(boss->threadEndSemaphore);
#endif
	
	[NSThread exit];
}

- (id)init
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
    if ([super init] == nil)
		return nil;
	
    PID = (pid_t)-1;
    STATUS = 0;
    DELEGATEOBJECT = nil;
    FILDES = -1;
    TTY = nil;
    LOG_PATH = nil;
    LOG_HANDLE = nil;
    hasOutput = NO;
    
    // allocate a semaphore to coordinate with thread
#ifdef __APPLE__
    MPCreateBinarySemaphore(&threadEndSemaphore);
#else
    pthread_mutex_init(&threadEndSemaphore, NULL);
#endif
	
    return self;
}

- (void)dealloc
{
#if DEBUG_ALLOC
    NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
#endif
    if (PID > 0)
		kill(PID, SIGKILL);
    if (FILDES >= 0)
		close(FILDES);
	
#if defined(__APPLE__)
    MPWaitOnSemaphore(threadEndSemaphore, kDurationForever);
    MPDeleteSemaphore(threadEndSemaphore);
#else
    pthread_mutex_lock(&threadEndSemaphore);
    pthread_mutex_destroy(&threadEndSemaphore);
    // FIXME: I should check this last line is right.
#endif

	
    [TTY release];
    [PATH release];
	
	[recvPort release];
	[sendPort release];
	[serverConnection release];
	
    
    [super dealloc];
}

- (void)launchWithPath:(NSString *)progpath
			 arguments:(NSArray *)args
		   environment:(NSDictionary *)env
				 width:(int)width
				height:(int)height
{
    struct termios term;
    struct winsize win;
    char ttyname[PATH_MAX];
    int sts;
    int one = 1;
	
    PATH = [progpath copy];
	
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[launchWithPath:%@ arguments:%@ environment:%@ width:%d height:%d", __FILE__, __LINE__, progpath, args, env, width, height);
#endif    
    setup_tty_param(&term, &win, width, height);
    // LINUX: pid_t forkpty(int *amaster, char *name, struct termios *termp, struct winsize *winp); 
    PID = forkpty(&FILDES, ttyname, &term, &win);
    if (PID == (pid_t)0) {
		const char *path = [[progpath stringByStandardizingPath] cString];
		int max = args == nil ? 0: [args count];
		const char *argv[max + 2];
		
		argv[0] = path;
		if (args != nil) {
            int i;
			for (i = 0; i < max; ++i)
				argv[i + 1] = [[args objectAtIndex:i] cString];
		}
		argv[max + 1] = NULL;
		
		// set the PATH to something sensible since the inherited path seems to have the user's home directory.
		setenv("PATH", "/usr/bin:/bin:/usr/sbin:/sbin", 1);
		
		if (env != nil ) {
			NSArray *keys = [env allKeys];
			int i, max = [keys count];
			for (i = 0; i < max; ++i) {
				NSString *key, *value;
				key = [keys objectAtIndex:i];
				value = [env objectForKey:key];
				if (key != nil && value != nil) 
					setenv([key cString], [value cString], 1);
			}
		}
        chdir([[[env objectForKey:@"PWD"] stringByExpandingTildeInPath] cString]);
		sts = execvp(path, (char * const *) argv);
		
		/*
		 exec error
		 */
		fprintf(stdout, "## exec failed ##\n");
		fprintf(stdout, "%s %s\n", path, strerror(errno));
		
		sleep(1);
		_exit(-1);
    }
    else if (PID < (pid_t)0) {
		NSLog(@"%@ %s", progpath, strerror(errno));
    }
	
    sts = ioctl(FILDES, TIOCPKT, &one);
    NSParameterAssert(sts >= 0);
	
    TTY = [[NSString stringWithCString:ttyname] retain];
    NSParameterAssert(TTY != nil);
	
	// establish a NSConnection for the read thread to use to talk back to us.
	recvPort = [NSPort port];
	[recvPort retain];
	sendPort = [NSPort port];
	[sendPort retain];
	serverConnection = [[NSConnection alloc] initWithReceivePort: recvPort sendPort: sendPort];
	[serverConnection setRootObject: self];
	
    [NSThread detachNewThreadSelector:@selector(_processReadThread:)
            	             toTarget: [PTYTask class]
						   withObject:self];
}

- (BOOL) hasOutput
{
    return (hasOutput);
}

- (void) setHasOutput: (BOOL) flag
{
    hasOutput = flag;
    if([self firstOutput] == NO)
		[self setFirstOutput: flag];
}

- (BOOL) firstOutput
{
    return (firstOutput);
}

- (void) setFirstOutput: (BOOL) flag
{
    firstOutput = flag;
}


- (void)setDelegate:(id)object
{
    DELEGATEOBJECT = object;
}

- (id)delegate
{
    return DELEGATEOBJECT;
}

- (void) doIdleTasks
{
    if ([DELEGATEOBJECT respondsToSelector:@selector(doIdleTasks)]) {
		[DELEGATEOBJECT doIdleTasks];
    }
}


- (void)readTask:(char *)buf length:(int)length
{
	NSData *data;
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTask readTask:%@]", __FILE__, __LINE__, data);
#endif
	if([self logging])
	{
		data = [[NSData alloc] initWithBytes: buf length: length];
		[LOG_HANDLE writeData:data];
		[data release];
	}
	
	// forward the data to our delegate
	[DELEGATEOBJECT readTask:buf length:length];
}

- (void)writeTask:(NSData *)data
{
    const void *datap = [data bytes];
    size_t len = [data length];
    int sts;
    
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYTask writeTask:%@]", __FILE__, __LINE__, data);
#endif
	
    sts = writep(FILDES, (char *)datap, len);
    if (sts < 0 ) {
		NSLog(@"%s(%d): writep() %s", __FILE__, __LINE__, strerror(errno));
    }
}

- (void)brokenPipe
{
    if ([DELEGATEOBJECT respondsToSelector:@selector(brokenPipe)]) {
        [DELEGATEOBJECT brokenPipe];
    }
}

- (void)sendSignal:(int)signo
{
    if (PID >= 0)
		kill(PID, signo);
}

- (void)setWidth:(int)width height:(int)height
{
    struct winsize winsize;
	
    if(FILDES == -1)
		return;
	
    ioctl(FILDES, TIOCGWINSZ, &winsize);
    winsize.ws_col = width;
    winsize.ws_row = height;
    ioctl(FILDES, TIOCSWINSZ, &winsize);
}

- (pid_t)pid
{
    return PID;
}

- (int)wait
{
    if (PID >= 0) 
		waitpid(PID, &STATUS, 0);
	
    return STATUS;
}

- (BOOL)exist
{
    BOOL result;
	
    if (WIFEXITED(STATUS))
		result = YES;
    else
		result = NO;
	
    return result;
}

- (void)stop
{
    [self sendSignal:SIGKILL];
	usleep(10000);
	if(FILDES >= 0)
		close(FILDES);
	FILDES = -1;
    [self wait];
	[serverConnection invalidate];
}

- (int)status
{
    return STATUS;
}

- (NSString *)tty
{
    return TTY;
}

- (NSString *)path
{
    return PATH;
}

- (BOOL)loggingStartWithPath:(NSString *)path
{
    [LOG_PATH autorelease];
    LOG_PATH = [[path stringByStandardizingPath ] copy];
	
    [LOG_HANDLE autorelease];
    LOG_HANDLE = [NSFileHandle fileHandleForWritingAtPath:LOG_PATH];
    if (LOG_HANDLE == nil) {
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm createFileAtPath:LOG_PATH
					contents:nil
				  attributes:nil];
		LOG_HANDLE = [NSFileHandle fileHandleForWritingAtPath:LOG_PATH];
    }
    [LOG_HANDLE retain];
    [LOG_HANDLE seekToEndOfFile];
	
    return LOG_HANDLE == nil ? NO:YES;
}

- (void)loggingStop
{
    [LOG_HANDLE closeFile];
	
    [LOG_PATH autorelease];
    [LOG_HANDLE autorelease];
    LOG_PATH = nil;
    LOG_HANDLE = nil;
}

- (BOOL)logging
{
    return LOG_HANDLE == nil ? NO : YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"PTYTask(pid %d, fildes %d)", PID, FILDES];
}

@end
