/*
	ETXineWrapper.m
	
	Copyright (C) 2008 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  May 2008
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "ETXineWrapper.h"
#include <xine.h>

static ETXineWrapper *sharedInstance = nil;

static void async_eventlistener(void *user_data, const xine_event_t *event)
{
	printf("[xine event id: %d]\n", event->type);

	if (event->type == XINE_EVENT_UI_PLAYBACK_FINISHED)
	{
		GSRegisterCurrentThread();
		
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		[[NSNotificationCenter defaultCenter]
		    performSelectorOnMainThread: @selector(postNotification:)
		    withObject: [NSNotification notificationWithName:@"xineFinished" object:nil]
		    waitUntilDone: YES];
		[pool release];

		GSUnregisterCurrentThread();
	}
}

@implementation ETXineWrapper

// TODO: finish implementing sending the notifications

- (void) xineFinished: (id)arg
{
	NSURL *next = [delegate musicBackendNextURL: self];
	if (next)
	{	
		NSLog(@"Attempting gapless switch to %@", next);
		[self setURL: next];
	}
	else
	{
		[self stop: nil];
	}
	
	[[NSNotificationCenter defaultCenter]
	  postNotificationName: ETURLFinishedNotification
	  object:self];
}

- (id) init
{
	if (sharedInstance != nil)
		return sharedInstance;

	self = [super init];
	sharedInstance = self;
	url = nil;
	positionUpdater = nil;
	state = STOPPED;
	seekOnResume = NO;
	seekOnResumeTo = 0;

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                      selector:@selector(xineFinished:)
	                                      name:@"xineFinished"
	                                      object:nil];

	xine = xine_new();
	xine_init(xine);
	audioport = xine_open_audio_driver(xine, "auto", NULL);
	if (audioport == NULL)
	{
		NSLog(@"xine-lib error: couldn't open audio driver.");
		return nil;
	}
	stream = xine_stream_new(xine, audioport, NULL);

	eventqueue = xine_event_new_queue(stream);
	xine_event_create_listener_thread(eventqueue, async_eventlistener, NULL);

	return self;
}

- (void) dealloc
{
	xine_dispose(stream);
	xine_close_audio_driver(xine, audioport);
	xine_exit(xine);
	[url release];
	[super dealloc];
}

- (id) delegate
{
	return delegate;
}

- (void) setDelegate: (id)newDelegate
{
	delegate = newDelegate; // no retain, it's a weak reference
}

- (void) setURL: (NSURL *)newURL
{
	NSLog(@"setURL: %@", newURL);

	ASSIGN(url, newURL);

	xine_close(stream);

	if (state == PLAYING)
	{
		state = STOPPED;
		[self play: nil]; // resume playback
	}
	else if (state == PAUSED)
	{
		state = STOPPED;
	}
	
	[[NSNotificationCenter defaultCenter]
		  postNotificationName: ETPlaybackStatusNotification
		  object:self];
}

- (NSURL *) url
{
	return url;
}

- (NSString *) title
{
	return @"";
}

- (void) play: (id)sender
{
	BOOL success = NO;
	if (state == STOPPED)
	{
		char *mrl = [[url relativeString] UTF8String];
		if (mrl != NULL)
		{
			xine_open(stream, mrl);
			success = xine_play(stream, 0, 0);
		}
	}
	else if (state == PAUSED)
	{
		if (seekOnResume)
			success = xine_play(stream, 0, seekOnResumeTo);
		else
		{
			xine_set_param(stream, XINE_PARAM_SPEED, XINE_SPEED_NORMAL);
			state = PLAYING;
			success = YES;
		}
	}

	if (success)
	{ 
		state = PLAYING;
		[self startPositionUpdater];
		[[NSNotificationCenter defaultCenter]
		  postNotificationName: ETPlaybackStatusNotification
		  object:self];
		NSLog(@"Play succedded.");
	}
	else
		NSLog(@"Play failed.");

	seekOnResume = NO;
	seekOnResumeTo = 0;
}

- (BOOL) playing
{
	return (state == PLAYING);
}

- (void) pause: (id)sender
{
	if (state != PAUSED)
	{
		xine_set_param(stream, XINE_PARAM_SPEED, XINE_SPEED_PAUSE);
		state = PAUSED;

		[[NSNotificationCenter defaultCenter]
	    	postNotificationName: ETPlaybackStatusNotification
		    object:self];
	}
}

- (BOOL) paused
{
	return (state == PAUSED);
}

- (void) stop: (id)sender
{
	xine_close(stream);
	if (state != STOPPED)
	{
		state = STOPPED;
		[[NSNotificationCenter defaultCenter]
		    postNotificationName: ETPlaybackStatusNotification
		    object:self];
	}
}

- (BOOL) stopped
{
	return (state == STOPPED);
}

- (double) length
{
	// TODO: this doesn't work if the stream isn't playing
	
	int pos_stream, pos_time, length_time;
	if (!xine_get_pos_length(stream, &pos_stream, &pos_time, &length_time))
	{
		NSLog(@"retrieving length failed.");
		return -1.0f;
	}
	return ((double) length_time / 1000.0f);

}

- (double) position
{
	int pos_stream, pos_time, length_time;
	if (!xine_get_pos_length(stream, &pos_stream, &pos_time, &length_time))
	{
		NSLog(@"retrieving position failed.");
		return -1.0f;
	}
	return ((double) pos_time / 1000.0f);
}

- (void) setPosition: (double)newpos
{
	if (state == PLAYING)
	{
		/*
		 * Trick mode is broken. It's supposed to return 0 if not
		 * avaiable, but it exits your program with an error message.
		 *
		 * int ret = xine_trick_mode(stream, XINE_TRICK_MODE_SEEK_TO_POSITION, 
		 *                           (int) (newpos * 1000));
		 */

		if (!xine_play(stream, 0,  (int) (newpos * 1000)))
			NSLog(@"setPosition failed.");
	} 
	else
	{
		seekOnResume = YES;
		seekOnResumeTo = (int) (newpos * 1000);
	}
}

- (void) setVolumeInPercentage: (unsigned int)volume
{
	xine_set_param(stream, XINE_PARAM_AUDIO_VOLUME, volume);
}

- (unsigned int) volumeInPercentage
{
	return xine_get_param(stream, XINE_PARAM_AUDIO_VOLUME);
}

// private

- (void) startPositionUpdater
{
	[self stopPositionUpdater];
	positionUpdater = [NSTimer scheduledTimerWithTimeInterval:0.25
	                           target: self
	                           selector: @selector(positionUpdate:)
	                           userInfo: nil
	                           repeats: YES];
}

- (void) stopPositionUpdater
{
	if ([positionUpdater isValid])
		[positionUpdater invalidate];

	positionUpdater = nil;
}

- (void) positionUpdate: (NSTimer *)timer
{
	if (state != PLAYING)
		[self stopPositionUpdater];

	[[NSNotificationCenter defaultCenter]
	    postNotificationName: ETPositionChangedNotification
        object:self];
}

@end
