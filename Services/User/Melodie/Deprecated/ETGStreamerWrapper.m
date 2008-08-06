/*
	ETGStreamerWrapper.m
	
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

#import "ETGStreamerWrapper.h"
#import <EtoileFoundation/Macros.h>
#include <gst/gst.h>

static ETGStreamerWrapper *sharedInstance = nil;

/*
 * This gets called by gstreamer, from whichever gstreamer thread produces a
 * message (so this function shouldn't block or take long, although testing
 * indicates that nothing disasterous would happen if it did.)
 */
static GstBusSyncReply sync_handler(GstBus *bus, GstMessage *msg, void *data)
{ 
	BOOL didRegister = GSRegisterCurrentThread();
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	switch (GST_MESSAGE_TYPE(msg))
	{
		case GST_MESSAGE_EOS:
		{
			[nc performSelectorOnMainThread: @selector(postNotification:)
		    	withObject: [NSNotification notificationWithName:@"gstFinished"
			                                object:nil]
			    waitUntilDone: NO];
			break;
		}
		default:
			break;	
	}

	[pool release];
	if (didRegister)
		GSUnregisterCurrentThread();

	return GST_BUS_PASS; 
}

@implementation ETGStreamerWrapper

- (void) gstFinished: (id)arg
{
	NSLog(@"Playback stopped!");
	
	NSURL *next = [delegate musicBackendNextURL: self];
	if (next)
	{	
		NSLog(@"Attempting switch to %@", next);
		[self setURL: next];
	}
	else
	{
		NSLog(@"Playback finished.");
		[self stop];
	}
	
	[[NSNotificationCenter defaultCenter]
	  postNotificationName: ETURLFinishedNotification
	  object:self];
}

- (id) init
{
	if (sharedInstance != nil)
		return sharedInstance;

	if (!gst_init_check(NULL, NULL, NULL))
		return nil;

	SUPERINIT		
	sharedInstance = self;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                      selector:@selector(gstFinished:)
	                                      name:@"gstFinished"
	                                      object:nil];
	
	play = gst_element_factory_make("playbin", "play");
	if (play == NULL)
		NSLog(@"playbin creation failed.");
		
	GstBus *bus = gst_pipeline_get_bus(GST_PIPELINE(play));
	gst_bus_set_sync_handler(bus, sync_handler, NULL);
	gst_object_unref(bus);
	return self;
}

- (void) dealloc
{
	gst_element_set_state(play, GST_STATE_NULL);
	gst_object_unref(GST_OBJECT(play));
	gst_deinit();
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

- (void) setURL: (NSURL *)newUrl
{
	ASSIGN(url, newUrl);

	const char *mrl = [[url relativeString] UTF8String];
	if (mrl == NULL)
	{
		NSLog(@"Invalid string  %@ from URL %@", [url relativeString], url);
		return;
	}
	else
		NSLog(@"Set url: %@", [url relativeString]);
		
	GstState state = [self gstState];
	if (state != GST_STATE_READY) 
		[self stop];
	
	g_object_set(G_OBJECT(play), "uri", mrl, NULL);
	gst_element_set_state(play, state);
	if ([self playing])
		[self startPositionUpdater];
		
	[[NSNotificationCenter defaultCenter]
	  postNotificationName: ETPlaybackStatusNotification
	  object:self];
}

- (NSURL *) url
{
	return url;
}

- (void) play
{
	NSLog(@"Play");
	gst_element_set_state(play, GST_STATE_PLAYING);
	[self startPositionUpdater];

	[[NSNotificationCenter defaultCenter]
	  postNotificationName: ETPlaybackStatusNotification
	  object:self];
}

- (BOOL) playing
{
	return ([self gstState] == GST_STATE_PLAYING);
}

- (void) pause
{
	gst_element_set_state(play, GST_STATE_PAUSED);

	[[NSNotificationCenter defaultCenter]
	  postNotificationName: ETPlaybackStatusNotification
	  object:self];
}

- (BOOL) paused
{
	return ([self gstState] == GST_STATE_PAUSED);
}

- (void) stop
{
	gst_element_set_state(play, GST_STATE_READY);

	[[NSNotificationCenter defaultCenter]
	  postNotificationName: ETPlaybackStatusNotification
	  object:self];
}

- (BOOL) stopped
{
	return ([self gstState] == GST_STATE_READY);
}

- (double) length
{
	GstFormat format = GST_FORMAT_TIME;
	gint64 length;
	
	BOOL ret = gst_element_query_duration(play, &format, &length);
	if (!ret)
	{
		NSLog(@"Get length failed.");
		return -1.0;
	}
	return ((double) length / 1000000000);

}

- (double) position
{
	gint64 current;
	GstFormat format = GST_FORMAT_TIME;
	BOOL ret = gst_element_query_position(play, &format, &current);
	if (!ret)
	{
		NSLog(@"Get position failed.");
		return -1.0;
	}
	return ((double) current / 1000000000);
}

- (void) setPosition: (double)newpos
{
	double ns = newpos * 1000000000;

	BOOL ret;
	ret = gst_element_seek_simple(play, 
	                              GST_FORMAT_TIME,
	                              GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT,
	                              ns);
	if (!ret)
	{
		NSLog(@"Seek failed.");
	}
}

- (void) setVolumeInPercentage: (unsigned int)volume
{
	g_object_set(play, "volume", ((gdouble) volume / (gdouble) 100), NULL);
}

- (unsigned int) volumeInPercentage
{
	gdouble vol;
	g_object_get(play, "volume", &vol, NULL);
	return ((unsigned int) (vol * 100));
}

@end


@implementation ETGStreamerWrapper (Private)

- (GstState) gstState
{
	GstState state;
	GstState pending;
	gst_element_get_state(play, &state, &pending, GST_CLOCK_TIME_NONE);
	return state;	
}

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
	if (![self playing])
		[self stopPositionUpdater];

	[[NSNotificationCenter defaultCenter]
	    postNotificationName: ETPositionChangedNotification
        object:self];
}

@end
