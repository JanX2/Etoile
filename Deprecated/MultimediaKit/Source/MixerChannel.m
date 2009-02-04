/*
**  MixerChannel.m
**
**  Copyright (c) 2002, 2003, 2006
**
**  Author: Yen-Ju  <yjchenx@hotmail.com>
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

#import <MultimediaKit/MixerChannel.h>
#import <Foundation/NSString.h>

@implementation MixerChannel

- (id) init
{
  self = [super init];
  name = @"";
  return self;
}

- (void) dealloc
{
  RELEASE(name);
  [super dealloc];
}

// Access methods
- (NSString *) name
{
  return name;
}

- (void) setName: (NSString *) theName
{
  ASSIGN(name, theName);
}

- (int) deviceNumber
{
  return deviceNumber;
}

- (void) setDeviceNumber: (int) number
{
  deviceNumber = number;
}

- (int) lastVolume
{
  return lastVolume;
}

- (void) setLastVolume: (int) number
{
  lastVolume = number;
}

- (float) volume
{
  return volume;
}

- (void) setVolume: (float) aVolume
{
  volume = aVolume;
}

- (float) balance
{
  return balance;
}

- (void) setBalance: (float) aBalance
{
  balance = aBalance;
}

- (BOOL) canRecord
{
  return canRecord;
}

- (void) setCanRecord: (BOOL) aBool
{
  canRecord = aBool;
}

- (BOOL) isRecording
{
  return isRecording;
}

- (void) setIsRecording: (BOOL) aBool
{
  isRecording = aBool;
}

- (BOOL) isStereo
{
  return isStereo;
}

- (void) setIsStereo: (BOOL) aBool
{
  isStereo = aBool;
}

- (BOOL) isMuted
{ 
  return isMuted;
}

- (void) setIsMuted: (BOOL) aBool
{
  isMuted = aBool;
}

@end
