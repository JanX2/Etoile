/*
**  MixerView.h
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

#import <AppKit/NSView.h>

@class MixerChannelView;
@class Mixer;
@class NSMutableArray;

@interface MixerView: NSView
{
  Mixer *mixer;
  int numberOfChannel;
  NSMutableArray *channelViews;
  NSSize size; // The size to contain all channels
}

- (NSSize) sizeToFit; // Resize to fit all channels. Return size 
- (void) channel: (int) number changeLeft: (float) left right: (float) right;
- (void) channel: (int) number didChangeMute: (int) state;
- (void) channel: (int) number didChangeRecord: (int) state;

@end

