/*
 * SCPower_FreeBSD.m - FreeBSD specific backend for SystemConfig
 *
 * Copyright 2006, David Chisnall
 * Copyright 2007, Yen-Ju Chen
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

#ifdef FREEBSD

#import "SCPower.h"
#import "TRSysctlByName.h"

@implementation SCPower (FreeBSD)

- (unsigned int) batteryLife
{
	return (unsigned int) performIntegerSysctlNamed("hw.acpi.battery.time");
}

- (unsigned char) batteryPercent
{
	return (unsigned char) performIntegerSysctlNamed("hw.acpi.battery.life");
}

- (BOOL) isUsingACLine
{
	return (BOOL) performIntegerSysctlNamed("hw.acpi.acline");
}

- (SCPowerStatus) status
{
	percent = [self batteryPercent];
	time = [self batteryLife];
	if ([self isUsingACLine])
	{
		if (percent > 98)
			return SCPowerACFull;
		else
			return SCPowerACCharging;
	}
	if (percent > 98)
		return SCPowerBatteryFull;
	else if (percent > 60)
		return SCPowerBatteryHigh;
	else if (percent > 25)
		return SCPowerBatteryMedium;
	else if (precent > 0)
		return SCPowerBatteryLow;
	else
		return SCPowerUnknown;
}

@end

#endif // FREEBSD
