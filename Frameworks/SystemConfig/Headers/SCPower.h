/*
	SCPower.h
 
	SCPower class to handle power related preferences.
 
	Copyright (C) 2007 Yen-Ju Chen
 
	Author:  Yen-Ju Chen <yjchenx at gmail>
    Date:  September 2007

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "SCConfig.h"

typedef enum _SCPowerStatus {
	SCPowerUnknown = 0,
	SCPowerBatteryLow,
	SCPowerBatteryMedium,
	SCPowerBatteryHigh,
	SCPowerBatteryFull,
	SCPowerACCharging,
	SCPowerACFull,
} SCPowerStatus;

@interface SCPower : SCConfigElement
{
	int percent;
	int time;
}

@end

@interface SCPower (PlatformDependent)
- (SCPowerStatus) status;

/* For battery. Return -1 if unknown.
   Application should ask for -status before querying percent
   since some implementation may cache percent from -status. */
- (int) percent;

/* For battery, in minutes. Return -1 if unknown.
   Application should ask for -status before querying time 
   since some implementation may cache time from -status. */
- (int) time;
@end
