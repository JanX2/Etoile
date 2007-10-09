/*
 * SCPower_OpenBSD.m - OpenBSD specific backend for SystemConfig
 *
 * Copyright 2007, David Chisnall
 * All rights reserved.
 *
 * Reformatted 
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, 
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright notice, 
 * this list of conditions and the following disclaimer in the documentation 
 * and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef OPENBSD

#include <fcntl.h>
#include <machine/apmvar.h>
#import "SCPower.h"
#import "TRSysctlByName.h"


@implementation SCPower (OpenBSD)
- (BOOL) isUsingACLine
{
	int apm = open("/dev/apm", O_RDONLY, 0);
	struct apm_power_info power;
	if(ioctl(apm, APM_IOC_GETPOWER, &power))
	{
		close(apm);
		return YES;
	}
	else
	{
		close(apm);
		return power.ac_state == APM_AC_ON;
	}
}

- (SCPowerStatus) status
{
	int apm = open("/dev/apm", O_RDONLY, 0);
	struct apm_power_info power;
	if(ioctl(apm, APM_IOC_GETPOWER, &power))
	{
		close(apm);
		return SCPowerUnknown;
	}
	else
	{
		close(apm);
		percent = (int) power.battery_life;
		time = power.minutes_left;
		if(power.ac_state == APM_AC_ON)
		{
			if(power.battery_state == APM_BATT_HIGH)
			switch(power.battery_state)
			{
				case APM_BATT_HIGH:
				case APM_BATTERY_ABSENT:
				case APM_BATT_UNKNOWN:
					return SCPowerACFull;
				default:
					return SCPowerACCharging;
			}
			return SCPowerACCharging;
		}
		else
		{
			if(percent > 98)
			{
				return SCPowerBatteryFull;
			}
			switch(power.battery_state)
			{
				case APM_BATT_HIGH:
					return SCPowerBatteryHigh;
				case APM_BATT_LOW:
					return SCPowerBatteryMedium;
				case APM_BATT_CRITICAL:
					return SCPowerBatteryLow;
				default:
					return SCPowerUnknown;
			}
		}
		
	}
}

@end

#endif // OPENBSD
