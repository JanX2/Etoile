/*
**  MixerChannel.h
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

#import <Foundation/NSObject.h>

@class NSString;

@interface MixerChannel: NSObject
{
  NSString *name;        /* name of channel */
  int deviceNumber;      /* channel device number */
  int lastVolume;        /* last known left/right volume */
                         /* in device format */
  float volume;          /* volumn, in [0, 1] */
  float balance;         /* balance, in [-1, 1] */
  BOOL canRecord;        /* capable of recoding ? */
  BOOL isRecording;      /* is it recording ? */
  BOOL isStereo;         /* capable of stereo ? */
  BOOL isMuted;          /* is it muted ? */
}

// Access methods
- (NSString *) name;
- (void) setName: (NSString *) name;
- (int) deviceNumber;
- (void) setDeviceNumber: (int) number;
- (int) lastVolume;
- (void) setLastVolume: (int) number;
- (float) volume;
- (void) setVolume: (float) volumn;
- (float) balance;
- (void) setBalance: (float) balance;
- (BOOL) canRecord;
- (void) setCanRecord: (BOOL) bool;
- (BOOL) isRecording;
- (void) setIsRecording: (BOOL) bool;
- (BOOL) isStereo;
- (void) setIsStereo: (BOOL) bool;
- (BOOL) isMuted;
- (void) setIsMuted: (BOOL) bool;

@end

