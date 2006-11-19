/*
**  Mixer.m
**
**  Copyright (c) 2002, 2003, 2006
**
**  Author: Yen-Ju  <yjchenx gmail>
**  Rewritten from WMix-3.0 (timecop [timecop@japan.co.jp])
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU Lesser General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU Lesser General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import <MultimediaKit/Mixer.h>
#import <MultimediaKit/MixerChannel.h>
#import <fcntl.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>

static const char *channel_names[] = SOUND_DEVICE_NAMES;

@interface Mixer (private)
- (BOOL) updateState;
- (void) setState;
- (BOOL) updateRecordState;
- (BOOL) setRecordState;
@end

@implementation Mixer (private)
- (void) setState
{
  float left, right;
  int bothVolume, rightVolume, leftVolume;

  if ([mixerChannel[currentChannel] isMuted]) {
    left = 0.0;
    right = 0.0;
  } else {
    VB_TO_LR([mixerChannel[currentChannel] volume],
             [mixerChannel[currentChannel] balance],
             left, right);
  }
  leftVolume = (int) (100.0 * left);
  rightVolume = (int) (100.0 * right);
  bothVolume = ((rightVolume << 8) | leftVolume);
  ioctl(mixer_fd, MIXER_WRITE([mixerChannel[currentChannel] deviceNumber]),
                              &bothVolume);
}

- (BOOL) updateState
{
  int bothVolume, leftVolume, rightVolume;
  float left, right;
  int srcmask, ch;
  float volume, balance;

  if (ioctl(mixer_fd, SOUND_MIXER_READ_RECSRC, &srcmask) == -1) {
      NSLog(@"mixer read failed");
      return NO;
    }

  for (ch = 0; ch < totalChannels; ch++) {
    if (ioctl(mixer_fd, MIXER_READ([mixerChannel[ch] deviceNumber]), 
              &bothVolume) == -1)
      {
         NSLog(@"mixer read failed\n");
         return NO;
      }

    if (bothVolume != [mixerChannel[ch] lastVolume]) {
          leftVolume = bothVolume & 0xFF;
          rightVolume = bothVolume >> 8;

        if ((leftVolume > 0) || (rightVolume > 0))
           [mixerChannel[ch] setIsMuted: NO];

        left = (float) leftVolume / 100.0;
        right = (float) rightVolume / 100.0;

        if (![mixerChannel[ch] isMuted]) {
          if ([mixerChannel[ch] isStereo]) {
             LR_TO_VB(left, right, volume, balance);
             [mixerChannel[ch] setVolume: volume];
             [mixerChannel[ch] setBalance: balance];
          } else {
             [mixerChannel[ch] setVolume: left];
             [mixerChannel[ch] setBalance: 0.0];
          }

          [mixerChannel[ch] setLastVolume: bothVolume];
        }
     }
     [mixerChannel[ch] setIsRecording: 
                  ((1 << [mixerChannel[ch] deviceNumber]) & srcmask) != 0];

/* For debug
     NSLog(@"--- MIXER ---");
     NSLog(@"Name: %@", [mixerChannel[ch] name]);
     NSLog(@"Device Number: %d", [mixerChannel[ch] deviceNumber]);
     NSLog(@"Last Volume: %d", [mixerChannel[ch] lastVolume]);
     NSLog(@"Volume: %f", [mixerChannel[ch] volume]);
     NSLog(@"Balance: %f", [mixerChannel[ch] balance]);
     NSLog(@"Can Record ? %d", [mixerChannel[ch] canRecord]);
     NSLog(@"Is Recording ? %d", [mixerChannel[ch] isRecording]);
     NSLog(@"Is Stereo ? %d", [mixerChannel[ch] isStereo]);
     NSLog(@"Is Muted ? %d", [mixerChannel[ch] isMuted]);
*/
  }

  return YES;
}

- (BOOL) updateRecordState
{
  int srcmask, ch;

  if (ioctl(mixer_fd, SOUND_MIXER_READ_RECSRC, &srcmask) == -1) {
     NSLog(@"mixer read failed");
     return NO;
  }

  for (ch = 0; ch < totalChannels; ch++) {
     [mixerChannel[ch] setIsRecording: 
                  (((1 << [mixerChannel[ch] deviceNumber]) & srcmask) != 0)];
  }
  return YES;  
}

- (BOOL) setRecordState
{
    int srcmask;

    if (ioctl(mixer_fd, SOUND_MIXER_READ_RECSRC, &srcmask) == -1) {
      NSLog(@"error: recording source mask ioctl failed");
      return NO;
    }

    if (((1 << [mixerChannel[currentChannel] deviceNumber]) & srcmask) == 0)
        srcmask |= (1 << [mixerChannel[currentChannel] deviceNumber]);
    else
        srcmask &= ~(1 << [mixerChannel[currentChannel] deviceNumber]);

    if (ioctl(mixer_fd, SOUND_MIXER_WRITE_RECSRC, &srcmask) == -1) {
        NSLog(@"error: recording source mask ioctl failed");
        return NO;
    }
    return YES;
}
@end

static Mixer *sharedInstance = nil;

@implementation Mixer

+ (id) sharedMixer
{
  if (!sharedInstance)
    {
      sharedInstance = [[self alloc] initWithDevice: @"/dev/mixer"];
    }
  return sharedInstance;
}

- (id) initWithDevice: (NSString *) aDevice
{
  int devmask, srcmask, recmask, stmask;
  int count, mask;
 
  self = [super init];

  TEST_RELEASE(device);
  device = aDevice;
  RETAIN(device);

  totalChannels = 0;
  currentChannel = 0;

  mixer_fd = open([device cString], O_RDWR);

  if (mixer_fd == -1) {
      NSLog(@"error: cannot open mixer device %@", device);
      return nil;
    }

  if (ioctl(mixer_fd, SOUND_MIXER_READ_DEVMASK, &devmask) == -1) {
      NSLog(@"error: device mask ioctl failed");
      return nil;
    }

  if (ioctl(mixer_fd, SOUND_MIXER_READ_RECSRC, &srcmask) == -1) {
      NSLog(@"error: recording source mask ioctl failed");
      return nil;
    }

  if (ioctl(mixer_fd, SOUND_MIXER_READ_RECMASK, &recmask) == -1) {
      NSLog(@"error: recording mask ioctl failed");
      return nil;
    }

  if (ioctl(mixer_fd, SOUND_MIXER_READ_STEREODEVS, &stmask) == -1) {
      NSLog(@"error: stereo mask ioctl failed");
      return nil;
    }

  for (count = 0; count < SOUND_MIXER_NRDEVICES; count++) 
    {
       mask = 1 << count;
       if (mask & devmask) {
          mixerChannel[totalChannels] = [[MixerChannel alloc] init];
          [mixerChannel[totalChannels] setName: 
                       [NSString stringWithCString: channel_names[count]]];
          [mixerChannel[totalChannels] setDeviceNumber: count];
          [mixerChannel[totalChannels] setLastVolume: -1];
          [mixerChannel[totalChannels] setCanRecord: ((mask & recmask) != 0)];
          [mixerChannel[totalChannels] setIsRecording: ((mask & srcmask) != 0)];
          [mixerChannel[totalChannels] setIsStereo: ((mask & stmask) != 0)];
          [mixerChannel[totalChannels] setIsMuted: NO];
          ++totalChannels;
// Debug    NSLog(@"  %d: %s\n", totalChannels, channel_names[count]);
        }
    }
  if ([self updateState] == NO)
    return NO;

  return self;
}

- (void) dealloc
{
  RELEASE(device);
  [super dealloc];
}

- (void) setCurrentChannel: (int) number
{
  if ((currentChannel >= 0) && (currentChannel < totalChannels)) {
    currentChannel = number;
    [self updateRecordState];
  }
}

- (int) currentChannel
{
  return currentChannel;
}

- (int) totalChannels
{
  return totalChannels;
}

- (NSArray *) allChannelNames
{
  int i; 
  NSMutableArray *array = [NSMutableArray new];

  for(i = 0; i < totalChannels; i++)
    [array addObject: [mixerChannel[i] name]];

  return AUTORELEASE(array);
}

- (NSString *) currentName
{
  return [mixerChannel[currentChannel] name];
}

- (float) currentVolume
{
  [self updateState];
  return [mixerChannel[currentChannel] volume];
}

- (void) setCurrentVolume: (float) number
{
  if((number >= 0.0) && (number <= 1.0))
    {
      [mixerChannel[currentChannel] setVolume: number];
      [self setState];
    }
}

- (float) currentBalance
{
  [self updateState];
  return [mixerChannel[currentChannel] balance];
}

- (void) setCurrentBalance: (float) balance
{
  if((balance >= -1) && (balance <= 1.0)) {
    if ([mixerChannel[currentChannel] isStereo]) {
      [mixerChannel[currentChannel] setBalance: balance];
      [self updateState];
    }
  }
}

- (BOOL) isCurrentMuted
{
  return [mixerChannel[currentChannel] isMuted];
}

- (void) setCurrentMute: (BOOL) aBool
{
  [mixerChannel[currentChannel] setIsMuted: aBool];
  [self setState];
}

- (BOOL) isCurrentRecord
{
  return [mixerChannel[currentChannel] isRecording];
}

- (void) setCurrentRecord: (BOOL) aBool
{
  if ([mixerChannel[currentChannel] canRecord]) {
    [mixerChannel[currentChannel] setIsRecording: aBool];
    [self setRecordState];
    [self updateRecordState];
  }
}

- (BOOL) currentCanRecord
{
  return [mixerChannel[currentChannel] canRecord];
}

- (BOOL) isCurrentStereo
{
  return [mixerChannel[currentChannel] isStereo];
}
@end
