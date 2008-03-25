/*
	SCPower_Linux.h
 
	SCPower class to handle power related preferences.
 
	Copyright (C) 2007 Yen-Ju Chen
 
	Author:  Yen-Ju Chen <yjchenx at gmail>
	         Lennart Melzer <l.melzer at tu-bs dot de>
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

#ifdef LINUX

#import "SCPower.h"
#ifdef LIBACPI
#import <libacpi.h>
#endif

@interface SCPower (Private)
- (SCPowerStatus) statusFromPercentage;
- (SCPowerStatus) APMStatus;
- (SCPowerStatus) ACPIStatus;
- (BOOL) checkACPISupport;
@end


@implementation SCPower (Linux)

/* Both APM and ACPI set the percentage and should return consistent states. */
- (SCPowerStatus) statusFromPercentage
{
	if (percent > 75)
	{
		return SCPowerBatteryFull;
	}
	else if (percent > 50)
	{
		return SCPowerBatteryHigh;
	}
	else if (percent > 25)
	{
		return SCPowerBatteryMedium;
	}
	else if (percent > 0)
	{
		return SCPowerBatteryLow;
	}
	else
	{
		/* If percent is 0, the computer dies. So it is probably due to 
		   the failure of parsing power level. */
		return SCPowerUnknown;
	}
}

- (SCPowerStatus) APMStatus
{
	NSString *apm = [NSString stringWithContentsOfFile: @"/proc/apm"];
	NSArray *array = [apm componentsSeparatedByString: @" "];
	SCPowerStatus status = SCPowerUnknown;

	/* This is what I gather:
	   0: Driver-version, string
	   1: BIOS-version, string
	   2: APM flag, 0x01: bit16
                   0x02: bits32
                   0x04: idle-slows-clock
                   0x10: disabled
                   0x20: disengaged
	   3: AC line status, 0x00: off
                   0x01: on
                   0x02: backup
                   0xff: unknown (#f)
	   4: Battery status, 0x00: high
                   0x01: low
                   0x02: critical
                   0x03: charging
                   0x04: absent
                   0xff: unknown (#f)
	   5: Battery flag, 0x01: high
                   0x02: low
                   0x04: critical
                   0x08: charging
                   0x80: absent
	   6: battery percent, could be '0x??', '??%'
	   7: Battery time, number
	   8: Battery time unit, string
	*/
	if ([[array objectAtIndex: 3] isEqualToString: @"0x01"])
	{
		if ([[array objectAtIndex: 4] isEqualToString: @"0x03"])
		{
			/* We are charging */
			status = SCPowerACCharging;
		}
		else
		{
			/* Full ? */
			status = SCPowerACFull;
		}
	}
	else if ([[array objectAtIndex: 3] isEqualToString: @"0x00"])
	{
		/* We are not on power */
		NSString *s = [array objectAtIndex: 6];
		if ([s hasSuffix: @"\%"])
		{
			/* We are in format of '56%', luckly !! */
			s = [s substringToIndex: [s length] - 1];
			percent = [s intValue];
			status = [self statusFromPercentage];
		}
	}

	return status;
}

- (SCPowerStatus) ACPIStatus
{
	SCPowerStatus status = SCPowerUnknown;

#ifdef LIBACPI
	global_t acpiStatus;

	if (init_acpi_acadapt(&acpiStatus) != SUCCESS)
                return SCPowerUnknown;
 
	if (acpiStatus.adapt.ac_state == P_AC)
	{
		/* We're on AC-Adaptor */
		if (init_acpi_batt(&acpiStatus) == SUCCESS)
		{
			/* We're just caring for the first battery right now */
			read_acpi_batt(0);
			battery_t battery = batteries[0];
			if (battery.charge_state == C_CHARGED)
			{
				/* We've got a charged battery */
				status = SCPowerACFull;
			}
			else if (battery.charge_state == C_CHARGE)
			{
				/* We're charging the battery */
				status = SCPowerACCharging;
			}
		}
	}
	else if (acpiStatus.adapt.ac_state == P_BATT)
	{
		/* We're on Battery power */
		if (init_acpi_batt(&acpiStatus) == SUCCESS)
		{
			/* We're just caring for the first battery right now */
			read_acpi_batt(0);
			battery_t battery = batteries[0];
			percent = battery.percentage;
			status = [self statusFromPercentage];
		}
		
	}
#endif /* LIBACPI */

	return status;
}

- (BOOL) checkACPISupport
{
#ifdef LIBACPI
	return (check_acpi_support() == SUCCESS);
#else
	return NO;
#endif
}

- (SCPowerStatus) status
{
	/* Check /proc/apm (For Linux with APM) */
	if ([[NSFileManager defaultManager] fileExistsAtPath: @"/proc/apm"])
	{
		/* APM Supported */
		return [self APMStatus];
	}
	else if ([self checkACPISupport])
	{
		/* ACPI supported */
		return [self ACPIStatus];
	}
	else
	{
		return SCPowerUnknown;
	}
}

@end

#endif /* LINUX */

