/*
	SCKeyboard.h
 
	SCKeyboard class to handle keyboard related preferences.
 
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
#import "SCConfig.h"

@class SCKeyboardModel;


@interface SCKeyboard : SCConfigElement
{

}

/* To control keyboard layout */

- (SCKeyboardModel *) keyboardModel;
- (void) setKeyboardModel: (SCKeyboardModel *)model;

/* Key repetition methods */

- (int) delayUntilKeyRepeat;
- (void) setDelayUntilKeyRepeat: (int)time;
// NOTE: keyRepeatRate could be a more appropriate choice.
- (int) keyRepeatInterval;
- (void) setKeyRepeatInterval: (int)time;

@end

/* Wrapper class to hide how host system specific keyboard layouts are accessed */
@interface SCKeyboardModel : NSObject
{

}

@end
