/*
	MusicPlayerController.m
	
	Copyright (C) 2008 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  June 2008
 
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
#import <Cocoa/Cocoa.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>
#import <CoreObject/CoreObject.h>
#import <IconKit/IconKit.h>
#import <MediaKit/MKMusicPlayer.h>

#import "MusicPlayerController.h"
#import "ETMusicFile.h"

@interface MusicPlayerController (Private)

- (void) timerEvent: (id)sender;

@end

@implementation MusicPlayerController : NSObject

- (id) init
{
	SUPERINIT
	
	player = [[[MKMusicPlayer alloc] initWithDefaultDevice] inNewThread];
	[player retain];

	uiUpdateTimer = 
			[NSTimer scheduledTimerWithTimeInterval:1
			                                 target:self
			                               selector:@selector(timerEvent:)
			                               userInfo:nil
			                                repeats:YES];
	return self;
}

- (void) dealloc
{
	[uiUpdateTimer invalidate];
	[player release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[playPauseButton
	   setImage: [[IKIcon iconWithIdentifier: @"media-playback-start"] image]];
	[nextButton 
	   setImage: [[IKIcon iconWithIdentifier: @"go-next"] image]];
	[previousButton
	   setImage: [[IKIcon iconWithIdentifier: @"go-previous"] image]];
	
	[volumeSlider setIntValue: [player volume]];
}

- (IBAction) playPause: (id)sender
{
	if (![player isPlaying])
		[player play];
	else
	{	
		[player pause];
		[playPauseButton setImage: [[IKIcon iconWithIdentifier: @"media-playback-start"] image]];
	}
}

- (IBAction) setPosition: (id)sender
{
	[player seekTo: [positionSlider intValue]];
}

- (IBAction) setVolume: (id)sender
{
	[player setVolume: [volumeSlider intValue]];
}

- (IBAction) next: (id)sender
{
	[player next];
}

- (IBAction) previous: (id)sender
{
}

- (void) playObject: (ETLayoutItem *)anObject 
              start: (BOOL)shouldStart
{
	NSLog(@"Playing URL: %@", [[anObject representedObject] URL]);
	[player stop];
	[player addURL: [[anObject representedObject] URL]];

	if (shouldStart)
		[player play];
}

- (void) play
{
	[player play];
}

- (void) pause
{
	[player pause];
}

@end

@implementation MusicPlayerController (Private)

- (void) timerEvent: (id)sender
{
	NSString *icon;
	if ([player isPlaying])
		icon = @"media-playback-pause";
	else
		icon = @"media-playback-start";

	[playPauseButton setImage: [[IKIcon iconWithIdentifier: icon] image]];

	[positionSlider setIntValue: [player currentPosition]];
	
	[positionSlider setMaxValue:[player duration]];

}

@end
