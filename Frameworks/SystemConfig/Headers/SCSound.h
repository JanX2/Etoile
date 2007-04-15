/*
	SCSound.h
 
	SCSound class to handle sound related preferences.
 
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

// FIXME: Temporary hack to enable compilation, write a proper class.
#define SCAudioDevice NSString

/* This notification is posted to distributed notification center.
   Applications can read volume after receive this notification */
extern NSString *const SCSoundDidChangeNotification;

@interface SCSound : SCConfigElement
{
  int mixer_fd;
  int stereodevs;
  int recmask;
}

/* Input/Output selection methods */

- (NSDictionary *) availableAudioInputs;
- (NSDictionary *) availableAudioOutputs;

- (void) setAudioInput: (SCAudioDevice *)input;
- (void) setAudioOutput: (SCAudioDevice *)ouput;

/* Volumes methods */

/* Volume ranges from 0-100 */
- (int) inputVolume;
- (void) setInputVolume: (int)volume;
- (int) outputVolume;
- (void) setOutputVolume: (int)volume;
- (BOOL) silent;
- (void) setSilent: (BOOL)silent;

/* Alert sound methods */

- (int) alertVolume;
- (void) setAlertVolume: (int)volume;
- (NSString *) alertSound;
- (void) setAlertSound: (NSString *)soundName;
- (void) setVisualFeedbackForAlertEnabled: (BOOL) flash;
- (BOOL) isVisualFeedbackForAlertEnabled;

@end
