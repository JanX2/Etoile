/*
**  CWPOP3CacheManager.m
**
**  Copyright (c) 2001-2007
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

#include <Pantomime/CWPOP3CacheManager.h>

#include <Pantomime/io.h>
#include <Pantomime/CWConstants.h>
#include <Pantomime/CWPOP3CacheObject.h>

#include <Foundation/NSArchiver.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>

#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <netinet/in.h>

static unsigned short version = 1;

//
//
//
@implementation CWPOP3CacheManager

- (id) initWithPath: (NSString *) thePath
{
  NSDictionary *attributes;
  unsigned short int v;
  
  _table = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 128);
  _count = 0;
  
  if ((_fd = open([thePath UTF8String], O_RDWR|O_CREAT, S_IRUSR|S_IWUSR)) < 0) 
    {
      NSLog(@"CANNOT CREATE OR OPEN THE CACHE!)");
      abort();
    }
  
  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"UNABLE TO LSEEK INITIAL");
      abort();
    }
  
  attributes = [[NSFileManager defaultManager] fileAttributesAtPath: thePath  traverseLink: NO];

  // If the cache exists, lets parse it.
  if ([[attributes objectForKey: NSFileSize] intValue])
    {
      NSString *aUID;
      NSDate *aDate;

      unsigned short len;
      char *s;
      int i;

      v = read_unsigned_short(_fd);

      // Version mismatch. We ignore the cache for now.
      if (v != version)
	{
	  ftruncate(_fd, 0);
	  [self synchronize];
	  return self;
	}      

      _count = read_unsigned_int(_fd);

      //NSLog(@"Init with count = %d  version = %d", _count, v);
  
      s = (char *)malloc(4096);
    
      for (i = 0; i < _count; i++)
	{
	  aDate = [NSCalendarDate dateWithTimeIntervalSince1970: read_unsigned_int(_fd)];
	  read_string(_fd, s, &len);	  

	  aUID = AUTORELEASE([[NSString alloc] initWithData: [NSData dataWithBytes: s  length: len]
					       encoding: NSASCIIStringEncoding]);
	  NSMapInsert(_table, aUID, aDate);
	}
      
      free(s);
    }
  else
    {
      [self synchronize];
    }

  return self;
}

//
//
//
- (void) dealloc
{
  //NSLog(@"CWPOP3CacheManager: -dealloc, _fd was = %d", _fd);
  
  NSFreeMapTable(_table);
  if (_fd >= 0) close(_fd);
  [super dealloc];
}

//
//
//
- (NSCalendarDate *) dateForUID: (NSString *) theUID
{
  return NSMapGet(_table, theUID);
}

//
//
//
- (BOOL) synchronize
{
  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
      abort();
      return NO;
    }
  
  // We write our cache version, count and UID validity.
  write_unsigned_short(_fd, version);
  write_unsigned_int(_fd, _count);
 
  return (fsync(_fd) == 0);
}

//
//
//
- (void) writeRecord: (cache_record *) theRecord
{
  NSData *aData;

  // We do NOT write a record we already have in our cache.
  // Some POP3 servers, like popa3d, might return the same UID
  // for messages at different index but with the same content.
  // If that happens, we just don't write that value in our cache.
  if (NSMapGet(_table, theRecord->pop3_uid))
    {
     return;
   }

  if (lseek(_fd, 0L, SEEK_END) < 0)
    {
      NSLog(@"COULD NOT LSEEK TO END OF FILE");
      abort();
    }

  write_unsigned_int(_fd, theRecord->date);

  aData = [theRecord->pop3_uid dataUsingEncoding: NSASCIIStringEncoding];
  write_string(_fd, (unsigned char *)[aData bytes], [aData length]);
  
  
  NSMapInsert(_table, theRecord->pop3_uid, [NSCalendarDate dateWithTimeIntervalSince1970: theRecord->date]);
  _count++;
}

@end
