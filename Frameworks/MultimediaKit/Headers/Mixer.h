/*
**  Mixer.h
**
**  Copyright (c) 2002, 2003, 2006
**
**  Author: Yen-Ju  <yjchenx gmail>
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

#import <Foundation/NSObject.h>
#import <sys/soundcard.h>

/* Convert from left/right into volume/balance
 * left/right are [0,1]; volume is [0,1], balance is [-1,-1]
 */
#define LR_TO_VB(left, right, volume, balance) \
        if (left < 0) left = 0.0; \
        if (right < 0) right = 0.0; \
        volume = MAX(left, right); \
        if (left > right) \
          balance = -1.0 + right / left; \
        else if (right > left) \
          balance = 1.0 - left / right; \
        else \
          balance = 0.0;

#define VB_TO_LR(volume, balance, left, right) \
        left = volume * (1.0 - MAX(0.0, balance)); \
        right = volume * (1.0 + MIN(0.0, balance));

@class MixerChannel;
@class NSString;
@class NSArray;

@interface Mixer: NSObject
{
  NSString *device;
  MixerChannel *mixerChannel[SOUND_MIXER_NRDEVICES];
  int currentChannel;
  int totalChannels;
  int mixer_fd;
}

/* Use /dev/mixer by default */
+ (id) sharedMixer;

- (id) initWithDevice: (NSString *) device;

/* Hardware channels */
- (int) totalChannels;
- (NSArray *) allChannelNames;

/* Specify the channel to use */
- (void) setCurrentChannel: (int) deviceNumber;
- (int) currentChannel;
- (NSString *) currentName;

/* Change the volume of current channel */
- (float) currentVolume;
- (void) setCurrentVolume: (float) volume;
- (float) currentBalance;
- (void) setCurrentBalance: (float) balance;
- (BOOL) isCurrentMuted;
- (void) setCurrentMute: (BOOL) bool;
- (BOOL) isCurrentRecord;
- (void) setCurrentRecord: (BOOL) bool;
- (BOOL) currentCanRecord;
- (BOOL) isCurrentStereo;
@end

