/* -*-objc-*- */

/** Implementation of SQLClientSQLite (sqlite 2) for GNUStep (Yen-Ju Chen)

   Copyright (C) 2004 Free Software Foundation, Inc.
   
   Written by:  Richard Frith-Macdonald <rfm@gnu.org>
   Date:	April 2004
   
   This file is part of the SQLClient Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.

   $Date$ $Revision$
   */ 
#include	<Foundation/NSString.h>
#include	<Foundation/NSData.h>
#include	<Foundation/NSDate.h>
#include	<Foundation/NSCalendarDate.h>
#include	<Foundation/NSException.h>
#include	<Foundation/NSProcessInfo.h>
#include	<Foundation/NSNotification.h>
#include	<Foundation/NSUserDefaults.h>
#include	<Foundation/NSMapTable.h>
#include	<Foundation/NSLock.h>
#include	<Foundation/NSNull.h>
#include	<Foundation/NSValue.h>
#include	<Foundation/NSAutoreleasePool.h>

#include 	"GNUstep.h"
#include	"SQLite.h"

#include	<sqlite.h>
#include	<string.h>
#include	<stdio.h>

@implementation	SQLiteClient

/* use [self database] as path to database file */
- (BOOL) backendConnect
{
  sqlite *sql;
  if (connected == NO)
    {
      if ([self database] != nil)
	{
	  NSString		*dbase = [self database];
	  int rc;
          char *errmsg;

	  [[self class] purgeConnections: nil];

	  if ([self debugging] > 0)
	    {
	      [self debug: @"Connect to '%@' as %@", [self database], [self name]];
	    }
	  //rc = sqlite_open((const char*)[dbase fileSystemRepresentation], &connection);
	  sql = sqlite_open([dbase cString], 0, &errmsg);
	  if (sql == NULL)
	    {
	      [self debug: @"Error connecting to '%@' (%@) - %s",
		[self name], [self database], errmsg];
	      sqlite_close(sql);
	      extra = 0;
	    }
	  else
	    {
	      connected = YES;
              extra = sql;

	      if ([self debugging] > 0)
		{
		  [self debug: @"Connected to '%@'", [self name]];
		}
	    }
	}
      else
	{
	  [self debug:
	    @"Connect to '%@' with no database configured",
	    [self name]];
	}
    }
  return connected;
}

- (void) backendDisconnect
{
  if (connected == YES)
    {
      NS_DURING
	{
	  if ([self isInTransaction] == YES)
	    {
	      [self rollback];
	    }

	  if ([self debugging] > 0)
	    {
	      [self debug: @"Disconnecting client %@", [self clientName]];
	    }
	  sqlite_close((sqlite *)extra);
	  extra = 0;
	  if ([self debugging] > 0)
	    {
	      [self debug: @"Disconnected client %@", [self clientName]];
	    }
	}
      NS_HANDLER
	{
	  extra = 0;
	  [self debug: @"Error disconnecting from database (%@): %@",
	    [self clientName], localException];
	}
      NS_ENDHANDLER
      connected = NO;
    }
}

- (void) backendExecute: (NSArray*)info
{
  NSString	*stmt;
  CREATE_AUTORELEASE_POOL(arp);

  stmt = [info objectAtIndex: 0];
  if ([stmt length] == 0)
    {
      RELEASE (arp);
      [NSException raise: NSInternalInconsistencyException
		  format: @"Statement produced null string"];
    }

  NS_DURING
    {
      const char	*statement;
      unsigned		length;
      int rc;
      char *err;

      /*
       * Ensure we have a working connection.
       */
      if ([self backendConnect] == NO)
	{
	  [NSException raise: SQLException
	    format: @"Unable to connect to '%@' to execute statement %@",
	    [self name], stmt];
	} 

      statement = (char*)[stmt UTF8String];
      length = strlen(statement);
#if 0 // Sqlite 2 seems not support BLOBs
      statement = [self insertBLOBs: info
	              intoStatement: statement
			     length: length
			 withMarker: "'''"
			     length: 3
			     giving: &length];
#endif

      rc = sqlite_exec((sqlite *)extra, statement, 0, 0, &err);
      if (rc != SQLITE_OK)
	{
	  [NSException raise: SQLException format: @"%s", err];
	}
    }
  NS_HANDLER
    {
      NSString	*n = [localException name];

      if ([n isEqual: SQLConnectionException] == YES) 
	{
	  [self backendDisconnect];
	}
      if ([self debugging] > 0)
	{
	  [self debug: @"Error executing statement:\n%@\n%@",
	    stmt, localException];
	}
      RETAIN (localException);
      RELEASE (arp);
      AUTORELEASE (localException);
      [localException raise];
    }
  NS_ENDHANDLER
  DESTROY(arp);
}

- (NSMutableArray*) backendQuery: (NSString*)stmt
{
  CREATE_AUTORELEASE_POOL(arp);
  NSMutableArray	*records = [[NSMutableArray alloc] init];

  if ([stmt length] == 0)
    {
      RELEASE (arp);
      [NSException raise: NSInternalInconsistencyException
		  format: @"Statement produced null string"];
    }

  NS_DURING
    {
      char	*statement;
      char 	*err;
      int	rc;
      const char *pzTail;
      sqlite_vm *ppVm;
      char *pzErrmsg;

      int pN;
      const char **pazValue;
      const char **pazColName;

      /*
       * Ensure we have a working connection.
       */
      if ([self backendConnect] == NO)
	{
	  [NSException raise: SQLException
	    format: @"Unable to connect to '%@' to run query %@",
	    [self name], stmt];
	} 

      statement = (char*)[stmt UTF8String];
      rc = sqlite_compile((sqlite *)extra, statement, &pzTail, &ppVm, &pzErrmsg);
      if (rc != SQLITE_OK) {NSLog(@"prepare failed: %s", pzErrmsg);}
      while ((rc = sqlite_step(ppVm, &pN, &pazValue, &pazColName)))
        {
          if (rc != SQLITE_ROW)
            break;

          int column_count = pN;
          int i;
          const char *column_name;
          const char *column_type;
          const char *value;
          id values[column_count];
          NSString *keys[column_count];
	  SQLRecord *record;
          for (i = 0; i < column_count; i++)
            {
              column_name = pazColName[i];
              column_type = pazColName[i+column_count];
              value = pazValue[i];
              keys[i] = [NSString stringWithUTF8String: column_name];
              /* Treat everything as TEXT */
              values[i] = [NSString stringWithUTF8String: value];
            }

	    record = [SQLRecord newWithValues: values
					   keys: keys
					  count: column_count];
	    [records addObject: record];
	    RELEASE(record);
        }
      if (rc != SQLITE_DONE)
        {
	  //[NSException raise: SQLException format: @"%s", sqlite3_errmsg((sqlite3 *)extra)];
	  [NSException raise: SQLException format: @"Error"];
	}
      sqlite_finalize(ppVm, &pzErrmsg);
    }
  NS_HANDLER
    {
      NSString	*n = [localException name];

      if ([n isEqual: SQLConnectionException] == YES) 
	{
	  [self backendDisconnect];
	}
      if ([self debugging] > 0)
	{
	  [self debug: @"Error executing statement:\n%@\n%@",
	    stmt, localException];
	}
      RETAIN (localException);
      RELEASE (arp);
      AUTORELEASE (localException);
      [localException raise];
    }
  NS_ENDHANDLER
  DESTROY(arp);
  return AUTORELEASE(records);
}

@end

