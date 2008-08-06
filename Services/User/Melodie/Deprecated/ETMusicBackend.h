/*
	ETMusicBackend.h
	
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

#import <Foundation/Foundation.h>

extern NSString *ETPlaybackStatusNotification;
extern NSString *ETURLFinishedNotification;
extern NSString *ETPositionChangedNotification;
extern NSString *ETTitleChangedNotification;

@protocol ETMusicBackend

- (id) delegate;
- (void) setDelegate: (id)delegate;
- (BOOL) playing;
- (void) play;
- (BOOL) paused;
- (void) pause;
- (BOOL) stopped;
- (void) stop;
- (NSURL *) url;
- (void) setURL: (NSURL *)newUrl;
- (double) length;
- (double) position;
- (void) setPosition: (double)aPosition;
- (unsigned int) volumeInPercentage;
- (void) setVolumeInPercentage: (unsigned int)volume;

// do we have separate notifications for everything, or
// have one that says, 'check the object'

/* 
 * The class will post these notifications:
 *
 * ETPlaybackStatusNotification 
 *  the playback status (playing, paused, stopped) changed
 *
 * ETURLFinishedNotification
 * 	the current URL finished; either the URL provided by the delegate
 *  started, or playback has ended.
 *
 * ETPositionChangedNotification
 * 	indicating that the track position changed, so update
 *  your UI.
 *
 * ETTitleChangedNotification
 * 	indicates that the name changed. Could be delivered in
 *  mid playback for a radio stream.
 */ 

@end

@protocol ETMusicBackendDelegate

- (NSURL *) musicBackendNextURL: (id)backend;

@end
