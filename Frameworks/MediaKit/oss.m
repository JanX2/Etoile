#import "oss.h"
#include <sys/ioctl.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/soundcard.h>
#import <EtoileFoundation/EtoileFoundation.h>

// This should really be /dev/dspW since /dev/dsp defaults to 8-bit format (if
// you actually bother to follow the spec).  A certain popular free *NIX seems
// to be developed by people who can't read specs, however, and doesn't provide
// /dev/dspW
#define DEVICE_NAME "/dev/dsp"

#define TRY_IOCTL(name,...) \
	do \
	{\
		if (ioctl(dev, name, ## __VA_ARGS__) == -1) \
		{\
			[NSException raise:@"OSSException"\
						format:@"Failure in %s ioctl", #name];\
		}\
	}\
	while(0)


@implementation OSSDevice
- (id) init
{
	SUPERINIT;
	return self;
}
- (id) initForInput:(BOOL) aFlag
{
	SELFINIT;
	int mode = O_WRONLY;
	if (aFlag)
	{
		mode = O_RDONLY;
	}
	if ((dev = open(DEVICE_NAME, mode, 0)) == -1)  
	{
		[self release];
		return nil;
	} 
	return self;
}
- (id) initForInput
{
	return [self initForInput:YES];
}
- (id) initForOutput
{
	return [self initForInput:NO];
}
- (BOOL) recordSample:(void*)bytes count:(int)count
{
	return read(dev, bytes, count) == count;
}
- (BOOL) playSample:(void*)bytes count:(int)count
{
	return write(dev, bytes, count) == count;
}
- (int) setFormat:(int) format
{
	int f = format;
	TRY_IOCTL(SNDCTL_DSP_SETFMT, &f);
	return f;
}
- (int) setChannels:(int) channels
{
	ioctl(dev, SNDCTL_DSP_CHANNELS, &channels);
	return channels;
}
- (int) setRate:(int)rate
{
	ioctl(dev, SNDCTL_DSP_SPEED, &rate);
	return rate;
}
- (BOOL) setVolumeLeft:(int)left right:(int)right
{
	left = MIN(left, 100);
	right = MIN(right, 100);
	int level=((int)left)|((int)right<<8);
	int setlevel = level;
	TRY_IOCTL(SNDCTL_DSP_SETPLAYVOL, &level);
	return level == setlevel;
}
- (int) volume
{
	int level;
	TRY_IOCTL(SNDCTL_DSP_GETPLAYVOL, &level);
	return level;
}
- (int) leftVolume
{
	return [self volume] & 0xff;
}
- (int) rightVolume
{
	return ([self volume] >> 8)& 0xff;
}
- (int) format
{
	return [self setFormat:AFMT_QUERY];
}
- (void) sync
{
	TRY_IOCTL(SNDCTL_DSP_SYNC, 0);
}
- (void) reset
{
	TRY_IOCTL(SNDCTL_DSP_RESET, 0);
}
@end
