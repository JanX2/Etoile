/*
**  MixerChannelView.m
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

#import <MultimediaKit/MixerChannelView.h>
#import <AppKit/AppKit.h>

@implementation MixerChannelView

- (void) sliderChanged: (id)sender
{
  [_delegate channel: number changeLeft: [leftSlider floatValue]
                                  right: [rightSlider floatValue]];
}

- (void) muteChanged: (id)sender
{
  [_delegate channel: number didChangeMute: [sender state]];
}

- (void) recordChanged: (id)sender
{
  [_delegate channel: number didChangeRecord: [sender state]];
}

- (id) initWithFrame: (NSRect) aRect;
{
  self = [super initWithFrame: aRect];
 
  number = -1;

  box = [[NSBox alloc] initWithFrame: NSMakeRect(2,2,
                                      channelViewWidth-5,
                                      channelViewHeight-5)];
  [box setBorderType: NSGrooveBorder];
  [box setTitlePosition: NSAtTop];

  leftSlider = [[NSSlider alloc] initWithFrame: NSMakeRect(11, 50, 
                                                sliderWidth, 
                                                sliderHeight)];
  [leftSlider setMinValue: 0.0];
  [leftSlider setMaxValue: 1.0];
  [leftSlider setTarget: self];
  [leftSlider setAction: @selector(sliderChanged:)];

  rightSlider = [[NSSlider alloc] initWithFrame: NSMakeRect(42, 50, 
                                                 sliderWidth, 
                                                 sliderHeight)];
  [rightSlider setMinValue: 0.0];
  [rightSlider setMaxValue: 1.0];
  [rightSlider setTarget: self];
  [rightSlider setAction: @selector(sliderChanged:)];

  muteButton = [[NSButton alloc] initWithFrame: NSMakeRect(5,25,60,15)];
  [muteButton setButtonType: NSRadioButton];
  [muteButton setTitle: @" Mute"];
  [muteButton setImagePosition: NSImageLeft];
  [muteButton setTarget: self];
  [muteButton setAction: @selector(muteChanged:)];

  recordButton = [[NSButton alloc] initWithFrame: NSMakeRect(5,5,60,15)];
  [recordButton setButtonType: NSRadioButton];
  [recordButton setTitle: @" Record"];
  [recordButton setImagePosition: NSImageLeft];
  [recordButton setTarget: self];
  [recordButton setAction: @selector(recordChanged:)];

  [box addSubview: leftSlider];
  [box addSubview: rightSlider];
  [box addSubview: muteButton];
  [box addSubview: recordButton];

  [self addSubview: box];

  return self;
}

- (void) dealloc
{
  RELEASE(name);
  RELEASE(box);
  RELEASE(leftSlider);
  RELEASE(rightSlider);
  RELEASE(muteButton);
  RELEASE(recordButton);
  [super dealloc];
}

- (void) setLeftChannel: (float) value
{
  [leftSlider setFloatValue: value];
}

- (float) leftChannel
{
  return [leftSlider floatValue];
}

- (void) setRightChannel: (float) value
{
  [rightSlider setFloatValue: value];
}

- (float) rightChannel
{
  return [rightSlider floatValue];
}

- (void) setMute: (int) state
{
  [muteButton setState: state];
}

- (int) mute
{
  return [muteButton state];
}

- (void) setRecord: (int) state
{
  if (state == -1)
    [recordButton removeFromSuperview];
  [recordButton setState: state];
}

- (int) record
{
  return [recordButton state];
}

- (void) setName: (NSString *) string
{
  RELEASE(name);
  name = string;
  [box setTitle: name];
  RETAIN(name);
}

- (NSString *) name
{
  return name;
}

- (void) setNumber: (int) num
{
  number = num;
}

- (int) number
{
  return number;
}

- (void) setDelegate: (id) aObject
{
  _delegate = aObject;
}

- (id) delegate
{
  return _delegate;
}

@end
