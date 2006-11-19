/*
**  MixerView.m
**
**  Copyright (c) 2002, 2003, 2006
**
**  Author: Yen-Ju Chen <yjchenx gmail>
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
#import <MultimediaKit/MixerView.h>
#import <MultimediaKit/MixerChannelView.h>
#import <AppKit/AppKit.h>

@implementation MixerView

- (void) updateChannel: (NSNotification *) not
{
  NSLog(@"update Channel %d", [mixer currentChannel]);
}

- (void) channel: (int) number changeLeft: (float) left
                                    right: (float) right
{
  float volume, balance;

  LR_TO_VB(left, right, volume, balance);

  [mixer setCurrentChannel: number];
  [mixer setCurrentVolume: volume];
  [mixer setCurrentBalance: balance];
}

- (void) channel: (int) number
         didChangeMute: (int) state
{
  [mixer setCurrentChannel: number];
  [mixer setCurrentMute: state];
}

- (void) channel: (int) number
         didChangeRecord: (int) state
{
  [mixer setCurrentChannel: number];
  [mixer setCurrentRecord: state];
}

- (id) initWithFrame: (NSRect) frame
{
  self = [super initWithFrame: frame];

  int i, y = 50;
  float left, right;
  MixerChannelView *channelView;

  ASSIGN(mixer, [Mixer sharedMixer]);

  // Init mixer
  [mixer setCurrentBalance: 0.0];
  [mixer setCurrentChannel: 0];

  // Get number of channels
  numberOfChannel = [mixer totalChannels];
  channelViews = [[NSMutableArray alloc] init];

  // Generate enough channel view
  for(i = 0; i < numberOfChannel; i++) {
    y = 1 + channelViewWidth * i;
    [mixer setCurrentChannel: i];
    channelView = [[MixerChannelView alloc] initWithFrame: NSMakeRect(y,1,
                                                  channelViewWidth,
                                                  channelViewHeight)];
    [channelView setName: [[mixer currentName] capitalizedString]];
    [channelView setNumber: i];
    [channelView setDelegate: self];
    VB_TO_LR([mixer currentVolume], [mixer currentBalance], left, right);
    [channelView setLeftChannel: left];
    [channelView setRightChannel: right];
    [channelView setMute: [mixer isCurrentMuted]];

    if ([mixer currentCanRecord])
      [channelView setRecord: [mixer isCurrentRecord]];
    else
      [channelView setRecord: -1]; /* Take off recordButton */

    [self  addSubview: channelView];
    [channelViews addObject: channelView];

    DESTROY(channelView);
  }

  size = NSMakeSize(y+channelViewWidth, channelViewHeight);

  return self;
}

- (void) dealloc
{
  DESTROY(mixer);
  DESTROY(channelViews);
  [super dealloc];
}

- (NSSize) sizeToFit
{
  [self setFrameSize: size];
  return size;
}

@end
