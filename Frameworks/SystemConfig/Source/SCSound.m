/*
	SCSound.h
 
	SCSound class to handle sound related preferences.
 
	Copyright (C) 2006 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
    Date:  November 2006
 
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <Foundation/Foundation.h>
#import "SCSound.h"
#import <fcntl.h>
#import <unistd.h>
#import <sys/ioctl.h>
#import <sys/soundcard.h>

NSString *const SCSoundDidChangeNotification = @"SCSoundDidChangeNotification";

@implementation SCSound

- (id) init
{
  self = [super init];
  mixer_fd = open("/dev/mixer", O_RDWR); 
  if (mixer_fd < 0)
  {
    /* Cannot open mixer. Quit. */
    [self dealloc];
    return nil;
  }
  int status;
  status  = ioctl(mixer_fd, SOUND_MIXER_READ_STEREODEVS, &stereodevs);
  if (status < 0)
  {
    /* Cannot get stereo mask */
    [self dealloc];
    return nil;
  }
  status = ioctl(mixer_fd, SOUND_MIXER_READ_RECMASK, &recmask);
  if (status < 0)
  {
    /* Cannot get record eask */
    [self dealloc];
    return nil;
  }
  return self;
}

- (void) dealloc
{
  if (mixer_fd > 0)
  {
    close(mixer_fd);
    mixer_fd = -1;
  }
  [super dealloc];
}

/* Input/Output selection methods */

- (NSDictionary *) availableAudioInputs
{
	return nil;
}

- (NSDictionary *) availableAudioOutputs
{
	return nil;
}

- (void) setAudioInput: (SCAudioDevice *)input
{

}

- (void) setAudioOutput: (SCAudioDevice *)ouput
{

}

/* Volumes methods */

- (int) _volumeAtChannel: (int) channel
{
  int volume, status;
  status = ioctl(mixer_fd, MIXER_READ(channel), &volume);
  if (status < 0)
  {
    return -1; /* read failed */
  }
  if (stereodevs & (1 << channel))
  {
    return (((volume & 0xff00) >> 8) + (volume & 0x00ff)) / 2; /* stereo */
  }
  else
  {
    return volume; /* mono */
  }
}

- (void) _setVolume: (int) v atChannel: (int) channel
{
  int volume, status;
  if (stereodevs & (1 << channel))
  {
    volume = (v << 8) + v; /* stereo */
  }
  else
  {
    volume = v; /* mono */
  }
  status = ioctl(mixer_fd, MIXER_WRITE(channel), &volume);
  if (status < 0)
  {
    /* write failed */
  }
  /* We post a distant notification to sync everything which uses it. */
  NSNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
  [nc postNotificationName: SCSoundDidChangeNotification
                    object: nil];
}

- (int) inputVolume
{
  return [self _volumeAtChannel: SOUND_MIXER_RECLEV];
}

- (void) setInputVolume: (int)volume
{
  return [self _setVolume: volume atChannel: SOUND_MIXER_RECLEV];
}

- (int) outputVolume
{
  return [self _volumeAtChannel: SOUND_MIXER_VOLUME];
}

- (void) setOutputVolume: (int)volume
{
  return [self _setVolume: volume atChannel: SOUND_MIXER_VOLUME];
}

- (BOOL) silent
{
  return ([self outputVolume] == 0);
}
- (void) setSilent: (BOOL)silent
{
  [self setOutputVolume: 0];
}

/* Alert sound methods */

- (int) alertVolume
{
	return -1;
}

- (void) setAlertVolume: (int)volume
{

}

- (NSString *) alertSound
{
	return nil;
}

- (void) setAlertSound: (NSString *)soundName
{

}

- (BOOL) isVisualFeedbackForAlertEnabled
{
	return NO;
}

- (void) setVisualFeedbackForAlertEnabled: (BOOL) flash
{

}

@end
