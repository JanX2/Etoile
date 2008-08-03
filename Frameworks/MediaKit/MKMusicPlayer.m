#import "MKMusicPlayer.h"
#import "MKMediaFile.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation MKMusicPlayer
- (id) init
{
	SUPERINIT;
	files = [[NSMutableArray alloc] init];
	return self;
}
- (id) initWithDevice:(id<MKSoundDevice>)device
{
	SELFINIT;
	ASSIGN(speaker, device);
	return self;
}
- (id) initWithDefaultDevice
{
	SELFINIT;
	speaker = [[[SoundService defaultAudioDevice] alloc] initForOutput];
	// 16-bit format.
	[speaker setFormat:16];
	return self;
}
- (void) play
{
	playing = YES;
}
- (void) pause
{
	playing = NO;
}
- (void) stop;
{
	[files removeAllObjects];
	DESTROY(file);
}
- (void) setURL:(NSURL*)aURL
{
	if ([aURL isEqual: [file URL]])
		return;
	file = [[MKMediaFile alloc] initWithURL:aURL];
	[file selectAnyAudioStream];
	int channels = [file channels];
	int rate = [file sampleRate];
	if (channels != [speaker setChannels:channels]
		||
		rate != [speaker setRate:rate])
	{
		[speaker reset];
		[speaker setChannels:[file channels]];
		[speaker setRate:[file sampleRate]];
	}
}
- (void) next
{
	DESTROY(file);
	if ([files count] != 0)
	{
		[files removeObjectAtIndex:0];
	}
	if ([files count] == 0)
	{
		playing = NO;
	}
	else
	{
		[self setURL:[files objectAtIndex:0]];
	}
}
- (int64_t) currentPosition
{
	return [file timestamp];
}
- (void) seekTo:(int64_t)milliseconds
{
	[file seekTo:milliseconds];
}
- (int64_t) duration
{
	return [file duration];
}
- (BOOL) isPlaying
{
	return playing;
}
- (BOOL) shouldIdle
{
	return playing;
}
- (NSURL*) currentURL
{
	if ([files count] == 0)
	{
		return nil;
	}
	return [files objectAtIndex:0];
}
- (void) addURL:(NSURL*)aURL
{
	[files addObject:aURL];
	if (file == nil)
	{
		[self setURL:aURL];
	}
}
- (void) setQueue:(NSArray*)queue
{
	ASSIGN(files, [queue mutableCopy]);
	if ([files count] > 0)
	{
		[self setURL:[files objectAtIndex:0]];
	}	
}
- (void) idle
{
	// FIXME: Should probably malloc / realloc this and store it in an ivar
	// rather than allocating it on the stack all the time.
	int bufferSize = [file requiredBufferSize];
	if (bufferSize > bufferSpace)
	{
		NSLog(@"Resizing buffer...");
		if (buffer == NULL)
		{
			buffer = malloc(bufferSize * 2);
		}
		else
		{
			buffer = realloc(buffer, bufferSize);
		}
		bufferSpace = bufferSize;
	}
	if (file != nil
	    &&
	    (bufferSize = [file decodeAudioTo:buffer size:bufferSize]) >= 0)
	{
		[speaker playSample:buffer count:bufferSize];
	}
	else
	{
		[self next];
	}
}
- (int) volume
{
	return [speaker leftVolume];
}
- (void) setVolume:(int)aVolume
{
	[speaker setVolumeLeft:aVolume right:aVolume];
}
- (int) queueSize
{
	return [files count];
}
- (void) dealloc
{
	[speaker release];
	[file release];
	[files release];
	if (NULL != buffer)
	{
		free(buffer);
	}
	[super dealloc];
}
@end


