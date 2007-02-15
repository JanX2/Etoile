/*
	SCConfig.h
 
	Utility code and SCConfigElement abstract class to represent any object 
	whose preferences can be modified.
 
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

// --------------------------------------------------
//    Error codes sent to the delegate
// --------------------------------------------------

#define SCREEN_ERROR ((int)0x4000)
#define MOUSE_ERROR ((int)0x2000)

enum {
	SCScreenResolutionChangeFailure =  SCREEN_ERROR | 1,
	SCScreenColorDepthChangeFailure =  SCREEN_ERROR | 2,
	SCScreenContrastChangeFailure =    SCREEN_ERROR | 3,
	SCScreenBrightnessChangeFailure =  SCREEN_ERROR | 4,
	SCScreenRefreshRateChangeFailure = SCREEN_ERROR | 5,
	
	SCMouseAccelerationChangeFailure =         MOUSE_ERROR | 1,
	SCMouseThresholdChangeFailure =            MOUSE_ERROR | 2,
	SCMouseDoubleClickIntervalChangeFailure =  MOUSE_ERROR | 3
};

// --------------------------------------------------
//    The SCConfigElement class
// --------------------------------------------------

@interface SCConfigElement : NSObject
{
	id delegate;
}

+ (SCConfigElement *) sharedInstance;

- (id) delegate;
- (void) setDelegate: (id)aDelegate;

@end

/* Delegate methods */

@interface SCConfigElement (Delegate)
- (void) configElement: (SCConfigElement *)element 
	preferenceModificationErrorOccured: (NSError *)error;
@end
