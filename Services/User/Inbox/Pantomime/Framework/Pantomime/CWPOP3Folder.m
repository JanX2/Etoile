/*
**  CWPOP3Folder.m
**
**  Copyright (c) 2001-2006
**
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation; either
**  version 2.1 of the License, or (at your option) any later version.
**  
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**  
**  You should have received a copy of the GNU Lesser General Public
**  License along with this library; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#include <Pantomime/CWPOP3Folder.h>

#include <Pantomime/CWConnection.h>
#include <Pantomime/CWConstants.h>
#include <Pantomime/CWMessage.h>
#include <Pantomime/CWPOP3CacheManager.h>
#include <Pantomime/CWPOP3CacheObject.h>
#include <Pantomime/CWPOP3Message.h>
#include <Pantomime/CWPOP3Store.h>
#include <Pantomime/CWTCPConnection.h>
#include <Pantomime/NSData+Extensions.h>
#include <Pantomime/NSString+Extensions.h>

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>

#include <limits.h>
#include <stdio.h>
#include <string.h>

#if !defined(UINT_MAX)
#define UINT_MAX (unsigned int)~0
#endif

//
// Private methods
//
@interface CWPOP3Folder (Private)
- (void) _deleteOldMessages;
@end


//
//
//
@implementation CWPOP3Folder

- (id) initWithName: (NSString *) theName
{
  self = [super initWithName: theName];
  _leave_on_server = YES;
  _retain_period = 0;
  return self;
}


//
//
//
- (void) prefetchMessageAtIndex: (int) theIndex
		  numberOfLines: (unsigned int) theNumberOfLines
{
  [_store sendCommand: POP3_TOP  arguments: @"TOP %d %d", theIndex, theNumberOfLines];
}


//
//
//
- (void) prefetch
{
  [_store sendCommand: POP3_STAT  arguments: @"STAT"];
}


//
// This method does nothing.
//
- (void) close
{
  // We do nothing.
}


//
//
//
- (BOOL) leaveOnServer
{
  return _leave_on_server;
}


//
//
//
- (void) setLeaveOnServer: (BOOL) theBOOL
{
  _leave_on_server = theBOOL;
}


//
//
//
- (unsigned int) retainPeriod
{
  return _retain_period;
}


//
// The retain period is set in days.
//
- (void) setRetainPeriod: (unsigned int) theRetainPeriod
{
  _retain_period = theRetainPeriod;
}


//
//
//
- (PantomimeFolderMode) mode
{
  return PantomimeReadWriteMode;
}


//
//
//
- (void) expunge
{
  int count;

  count = [self count];

  // We mark it as deleted if we need to
  if (!_leave_on_server)
    {
      int i;

      for (i = 1; i <= count; i++)
	{
	  [_store sendCommand: POP3_DELE  arguments: @"DELE %d", i];
	}
    }
  else if (_retain_period > 0)
    {
      [self _deleteOldMessages];
    }

  [_store sendCommand: POP3_EXPUNGE_COMPLETED  arguments: @""];
}


//
// In POP3, we do nothing.
//
- (void) search: (NSString *) theString
	   mask: (PantomimeSearchMask) theMask
	options: (PantomimeSearchOption) theOptions
{
}

@end


//
// Private methods
//
@implementation CWPOP3Folder (Private)

- (void) _deleteOldMessages
{
  int i, count;

  count = [self count];
  
  for (i = count; i > 0; i--)
    {
      NSDate *aDate;
      
      aDate = [_cacheManager dateForUID: [[allMessages objectAtIndex: i-1] UID]];
      
      if (aDate)
	{
	  NSCalendarDate *aCalendarDate;
	  int days;
	  
	  // We get the days interval between our two dates
	  aCalendarDate = [NSCalendarDate calendarDate];
	  [aCalendarDate years: NULL
			 months: NULL
			 days: &days
			 hours: NULL
			 minutes: NULL
			 seconds: NULL
			 sinceDate: aDate];
	  
	  if (days >= _retain_period)
	    {
	      [_store sendCommand: POP3_DELE  arguments: @"DELE %d", i];
	    }
	}
    }
}

@end
