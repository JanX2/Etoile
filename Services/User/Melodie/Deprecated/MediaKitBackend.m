#import "MediaKitBackend.h"
#import <EtoileFoundation/EtoileFoundation.h>


@implementation MediaKitBackend
- (id) init
{
	SUPERINIT;
	player = [[[MKMusicPlayer alloc] initWithDefaultDevice] inNewThread];
	[player retain];
	return self;
}
- (id) delegate 
{
   	return nil; 
}
- (void) setDelegate: (id)aDelegate {}
- (BOOL) playing
{
	return [player isPlaying];
}
- (void) play
{
	[player play];
}
- (BOOL) paused
{
	return ![player isPlaying] && (nil != [player currentFile]);
}
- (void) pause
{
	[player pause];
}
- (BOOL) stopped
{
	return (nil == [player currentFile]);
}
- (void) stop
{
	[player stop];
}
- (NSURL *) url
{
	return [NSURL fileURLWithPath:[player currentFile]];
}
- (void) addURL: (NSURL *)newUrl
{
	[player addFile:[newUrl absoluteString]];
}
- (void) setURL: (NSURL *)newUrl
{
	if (nil != newUrl)
	{
		BOOL isPlaying = [player isPlaying];
		[player stop];
		[player addFile:[newUrl path]];
		if (isPlaying)
		{
			[player play];
		}
	}
}
- (double) length
{
	return ((double)[player duration]) * 1000.0;
}
- (double) position
{
	return ((double)[player currentPosition]) * 1000.0;
}
- (void) setPosition: (double)aPosition
{
	int64_t position = aPosition / 1000;
	[player seekTo:position];
}

- (unsigned int) volumeInPercentage
{
	return [player volume];
}
- (void) setVolumeInPercentage: (unsigned int)volume
{
	[player setVolume:volume];
}
@end
