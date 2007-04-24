/*
	SCHardware.m

	SCHardware functions which should issue reboot, shutdown and suspend as 
	expected by the host system.
 
    Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2007

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
#import <dbus/dbus.h>

/* Suspend support overview

   Warning: All the documentation should be correct, but errors may still exist
   because the topic isn't really well documented by Linux distributions.

   Terminology reminder...
   sleep/suspend: suspend to ram
   hibernate: suspend to disk

   At this time, most Linux distributions support suspend and hibernate by
   relying on HAL and custom scripts. Similar support is on the way for FreeBSD
   and Solaris.

   The normal path usually looks like:
   DBus -> HAL -> custom scripts -> ACPI scripts -> ACPI

   The purpose of calling HAL through DBus is mainly to allow normal user to 
   request operations like suspend, reboot and shutdown. HAL daemon (hald) runs
   as root, but DBus calls can be issued by a normal user. HAL checks the user
   who issue such DBus call is at console (check pam_atconsole module) before
   making possible to bypass usual security restriction.

   On Ubuntu, the path looks like:
   DBus -> HAL -> pmi action sleep -> /etc/acpi/sleep.sh -> ACPI
   pmi part mostly only takes care of discarding sleep requests when sleep is 
   already on the way. All the heavy part of the work is done in sleep.sh. This
   script has been heavily tweaked by Ubuntu to workarounds a bunch of hardware
   and driver issues.

   To take another example (way more convoluted), on OpenSuse:
   DBus -> powersaved -> /usr/lib/powersave/scripts/ -> ACPI
   The previous line should describe how it is handled on OpenSuse 10.2. In 
   addition, there is 'powersave' which is just a command-line tool to talk to 
   'powersaved' through DBus. In this case, the path is: 
   powersave-> DBus -> powersaved -> /usr/lib/powersave/scripts/
   If OpenSuse still relies on ACPI, it doesn't use acpi script support to 
   handle power management but rather its own architecture called powersave.
   However it needs acpid in order to react to power management events coming
   from hardware. Finally it disables acpid hooks to avoid acpi scripts to be
   run.
   If you emit an HAL call to request suspend, it will be handled by pm-utils
   backend. In next OpenSuse version, pm-utils will replace 
   /usr/lib/powersave/scripts/ as suspend support backend in all cases.
   DBus -> HAL -> pm-suspend (pm-utils) -> ACPI

   Now a last example on a distribution which doesn't support pm-utils but 
   provides HAL and powersave. Here is how the path would look like:
   DBus -> HAL -> powersave -> DBus -> powersaved 
   -> /usr/lib/powersave/scripts/ -> ACPI

   In future, pm-utils should become the interface for power management on all
   Linux distributions. pm-utils is a Freedesktop project now.
 */

/*
 * HAL Power Management (over DBus)
 */

/* Test HAL call over DBus with dbus-send --system --print-reply 
   --dest=org.freedesktop.Hal /org/freedesktop/Hal/devices/computer
   org.freedesktop.Hal.Device.SystemPowerManagement.Suspend int32:0 */

// FIXME: Implement shutdown, reboot, suspend check to know whether there are
// supported on this hardware and host system. 
BOOL DBus_isSupportedPowerManagementCall(NSString *propertyName)
{
	return YES;
}

/* If suspend fails, HAL is somewhat messed up. Any upcoming HAL calls are 
   going to get stuck in a queue. That's why suspend is currently disabled,
   otherwise it could prevent to reboot or shutdown. */
BOOL DBus_powerManagementCall(NSString *msgName)
{
	DBusConnection *connection;
	DBusError error;
	DBusMessage *message;
	DBusMessageIter args;
	DBusMessage *reply;
	int reply_timeout = -1;
	int result = -1;

	dbus_error_init(&error);

	connection = dbus_bus_get(DBUS_BUS_SYSTEM, &error);

	if (connection == NULL)
	{
		NSLog(@"For power management call, DBus fails to open connection to: %s", error.message);
		dbus_error_free(&error);
		return NO;
	}

	/* Construct the message */

	message = dbus_message_new_method_call(
		"org.freedesktop.Hal",  /* service */
		"/org/freedesktop/Hal/devices/computer", /* path */
		"org.freedesktop.Hal.Device.SystemPowerManagement",  /* interface */
		[msgName cString]); 

	if ([msgName isEqual: @"Suspend"])
	{
		int wakeupTime = 0;

		dbus_message_iter_init_append(message, &args);
		if (!dbus_message_iter_append_basic(&args, DBUS_TYPE_INT32, &wakeupTime)) 
		{ 
			NSLog(@"Out of memory to append argument for DBus power management call."); 
			return NO;
		}
	}

	/* Call method */
	if ([msgName isEqual: @"Suspend"])
		reply_timeout = INT_MAX;
	NSDebugLog(@"SCHardware", "DBus sends %@ with timeout %d", msgName, 
		reply_timeout);
	reply = dbus_connection_send_with_reply_and_block(connection, message, 
		reply_timeout, &error);

	if (dbus_error_is_set(&error))
	{
		NSLog(@"For power management call, DBus error: %s", error.message);
		return NO;
    }

	/* Extract the data from the reply */
	if (!dbus_message_get_args(reply, &error, 
		DBUS_TYPE_INT32, &result, DBUS_TYPE_INVALID))
	{ 
		NSLog(@"DBus fails to complete power management call: %s", 
			error.message);
		return NO;
	}

	NSDebugLog(@"SCHardware", "DBus reply is %d", reply);

	dbus_message_unref(reply);
	dbus_message_unref(message);

	return YES;
}

BOOL SCHardwareIsRebootSupported()
{
	return DBus_isSupportedPowerManagementCall(@"reboot");
}

BOOL SCHardwareIsShutDownSupported()
{
	return DBus_isSupportedPowerManagementCall(@"shutdown");
}

BOOL SCHardwareShutDown()
{
	if (DBus_isSupportedPowerManagementCall(@"shutdown"))
	{
		NSDebugLog(@"SCHardware", @"Shutdown supported");

		return DBus_powerManagementCall(@"Shutdown");
	}

	return NO;
}

BOOL SCHardwareReboot()
{
	if (DBus_isSupportedPowerManagementCall(@"reboot"))
	{
		NSDebugLog(@"SCHardware", @"Reboot supported");

		return DBus_powerManagementCall(@"Reboot");
	}

	return NO;
}

BOOL SCHardwareSuspend()
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	/* Suspend/sleep is disabled by default */
	if ([defaults boolForKey: @"EtoileSleepEnabled"]
		&& DBus_isSupportedPowerManagementCall(@"suspend"))
	{
		NSDebugLog(@"SCHardware", @"Suspend supported");

		return DBus_powerManagementCall(@"Suspend");
	}

	return NO;
}
