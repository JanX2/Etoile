/*
**  MixerChannelView.h
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

#import <AppKit/NSView.h>

#define channelViewWidth 90
#define channelViewHeight 190

#define sliderWidth 15
#define sliderHeight 100

@class NSBox;
@class NSString;
@class NSSlider;
@class NSButton;

@interface MixerChannelView : NSView
{
  NSBox *box;
  NSString *name;
  NSSlider *leftSlider, *rightSlider;
  NSButton *muteButton, *recordButton;
  int number;
  id _delegate;
}

- (void) setName: (NSString *) name;
- (NSString *) name;
- (void) setNumber: (int) number;
- (int) number;
- (void) setDelegate: (id) delegate;
- (id) delegate;
- (void) setLeftChannel: (float) value;
- (float) leftChannel;
- (void) setRightChannel: (float) value;
- (float) rightChannel;
- (void) setMute: (int) state;
- (int) mute;
- (void) setRecord: (int) state;
- (int) record;

@end

@interface NSObject (MixerChannelView)

- (void) channel: (int) deviceNumber 
         changeLeft: (float) left 
         right: (float) right;
- (void) channel: (int) deviceNumber
         didChangeMute: (int) state;
- (void) channel: (int) deviceNumber
         didChangeRecord: (int) state;
@end

