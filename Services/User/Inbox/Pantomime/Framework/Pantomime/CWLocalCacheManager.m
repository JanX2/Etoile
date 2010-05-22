/*
**  CWLocalCacheManager.m
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

#include <Pantomime/CWLocalCacheManager.h>

#include <Pantomime/io.h>
#include <Pantomime/CWConstants.h>
#include <Pantomime/CWFlags.h>
#include <Pantomime/CWLocalFolder.h>
#include <Pantomime/CWLocalMessage.h>
#include <Pantomime/CWParser.h>
#include <Pantomime/NSData+Extensions.h>

#include <Foundation/NSArchiver.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSNull.h>
#include <Foundation/NSValue.h>

#include <stdlib.h>
#include <string.h>
#include <sys/types.h>  // For open() and friends.
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>     // For lseek()
#include <netinet/in.h> // For ntohl()

static unsigned short version = 1;

//
// Cache structure:
//
// Start   length Description
// 
// 0       2      Cache version
// 2       4      Number of cache entries
// 6       4      Modification date of the underlying mbox file
//                Modification of the underlying cur/ directory for maildir
// [10]    4      File size of the underlying mbox file. This entry does NOT exist for maildir cache.
// 14+/10+        Beginning of the first cache entry
// 
// 0       4      Record length, including this field. The record consist of cached message headers / attributes.
// 4       4      Flags
// 8       4      Date
// 12      4+     Position for mbox / Filename for maildir
// 16+     4      Size
//
//
@implementation CWLocalCacheManager

//
//
//
- (id) initWithPath: (NSString *) thePath  folder: (id) theFolder
{
  NSDictionary *attributes;
  unsigned int d, s, c;
  unsigned short int v;
  BOOL broken;

  self = [super initWithPath: thePath];

  // We get the attributes of the mailbox
  if ([theFolder type] == PantomimeFormatMbox)
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [theFolder path]  traverseLink: NO];
    }
  else
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [NSString stringWithFormat: @"%@/cur", [theFolder path]]
						   traverseLink: NO];
    }

  d = [[attributes objectForKey: NSFileModificationDate] timeIntervalSince1970];
  s = [[attributes objectForKey: NSFileSize] intValue];
  broken = NO;

  // We get the attribtes of the cache
  attributes = [[NSFileManager defaultManager] fileAttributesAtPath: thePath  traverseLink: NO];

  _folder = theFolder;
  _count = _modification_date = 0;

  if ((_fd = open([thePath UTF8String], O_RDWR|O_CREAT, S_IRUSR|S_IWUSR)) < 0) 
    {
      AUTORELEASE(self);
      return nil;
    }

  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      AUTORELEASE(self);
      return nil;
    }
  
  // If the cache exists, lets parse it.
  if ([[attributes objectForKey: NSFileSize] intValue])
    {
      unsigned int i;

      v = read_unsigned_short(_fd);

      // HACK: We IGNORE all the previous cache.
      if (v != version)
	{
	  //NSLog(@"Ignoring the old cache format.");
	  ftruncate(_fd, 0);
	  [self synchronize];
	  return self;
	}

      _count = read_unsigned_int(_fd);
      _modification_date = read_unsigned_int(_fd);

      if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
	{
	  _size = read_unsigned_int(_fd);
	  
	  if (s != _size || d != _modification_date) broken = YES;
	}
      else
	{
	  //NSLog(@"Asking enumerator...");
	  c = [[[[NSFileManager defaultManager] enumeratorAtPath: [NSString stringWithFormat: @"%@/cur/", [theFolder path]]] allObjects] count];
	  //NSLog(@"Done! count = %d", c);
	  
	  if (c != _count || d != _modification_date) broken = YES;
	}
 
      if (broken)
	{
	  //NSLog(@"Broken cache, we must invalidate.");
	  _count = _size = 0;
	  ftruncate(_fd,0);
	  [self synchronize];
	  return self;
	}
      
      //NSLog(@"Version = %i  date  = %d  size = %d count = %d", v, d, _size, _count);

      for (i = 0; i < _count; i++)
	{
	  [((CWFolder *)_folder)->allMessages addObject: AUTORELEASE([[CWLocalMessage alloc] init])];
	}
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
  //NSLog(@"CWLocalCacheManager: -dealloc");
  
  if (_fd >= 0) close(_fd);

  [super dealloc];
}


//
// If this method is invoked on already initialized messages, we use
// the file position or filename field in order to determine if we already
// initialized or not the message.
//
- (void) initInRange: (NSRange) theRange
{
  CWLocalMessage *aMessage;
  CWFlags *theFlags;
  
  unsigned short int len, tot;
  unsigned char *r, *s;
  int begin, end, i;
  BOOL b;

  begin = (theRange.location >= 0 ? theRange.location : 0);
  end = (NSMaxRange(theRange) <= _count ? NSMaxRange(theRange) : _count);

  if (lseek(_fd, ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox) ? 14L : 10L, SEEK_SET) < 0)
    {
      NSLog(@"lseek failed in initInRange:");
      abort();
    }
  
  //NSLog(@"init from %d to %d, count = %d, size of char %d", begin, end, _count, sizeof(char));

  s = (unsigned char *)malloc(65536);
  tot = 0;

  // We MUST skip the last few bytes...
  for (i = begin; i < end ; i++)
    {
      // aMessage = [[CWLocalMessage alloc] init];
      aMessage = [((CWFolder *)_folder)->allMessages objectAtIndex: i];
      [aMessage setFolder: _folder];
      [aMessage setMessageNumber: i+1];
      b = NO;

      // With read: 1.157
      // With read+malloc+free: 1.201
      // Without read, malloc, free + in-memory parsing: .847
      // Inline: .892 (not worth it)
      // With 'static' buffer: .839 (not worth it)

      // We parse the record length, date, flags, position in file and the size.
      len = read_unsigned_int(_fd);

      r = (unsigned char *)malloc(len-4);
      
      if (read(_fd, r, len-4) < 0) { NSLog(@"read failed"); abort(); }

      theFlags = AUTORELEASE([[CWFlags alloc] initWithFlags: read_unsigned_int_memory(r)]);
      [aMessage setReceivedDate: [NSCalendarDate dateWithTimeIntervalSince1970: read_unsigned_int_memory(r+4)]];

      if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
	{
	  if ([aMessage filePosition] == 0)
	    {
	      [aMessage setFilePosition: read_unsigned_int_memory(r+8)];
	      [aMessage setSize: read_unsigned_int_memory(r+12)];
	      b = YES;
	    }
	  tot = 16;
	}
      else
	{
	  read_string_memory(r+8, s, &len);
	  if (![aMessage filename])
	    {
	      [aMessage setMailFilename: [NSString stringWithUTF8String: (const char *)s]];
	      [aMessage setSize: read_unsigned_int_memory(r+len+10)];
	      b = YES;
	    }
	  tot = len+14;
	}

      if (!b)
	{
	  free(r);
	  continue;
	}

      // We set the flags, only if we need to as they might have
      // changed since the last time this method was called.
      [aMessage setFlags: theFlags];

      // .209ms
      read_string_memory(r+tot, s, &len);
      [CWParser parseFrom: [NSData dataWithBytes: s  length: len]  inMessage: aMessage  quick: YES];
      tot += len+2;
     
      // .462ms (+253ms), .217ms
      read_string_memory(r+tot, s, &len);
      [CWParser parseInReplyTo: [NSData dataWithBytes: s  length: len]  inMessage: aMessage  quick: YES];
      tot += len+2;
      
      // .468ms (+4ms)
      read_string_memory(r+tot, s, &len);
      [CWParser parseMessageID: [NSData dataWithBytes: s  length: len]  inMessage: aMessage  quick: YES];
      tot += len+2;

      // .560ms (+92ms)
      read_string_memory(r+tot, s, &len);
      [CWParser parseReferences: [NSData dataWithBytes: s  length: len]  inMessage: aMessage  quick: YES];
      tot += len+2;

      // .731ms (+171ms), .135ms
      read_string_memory(r+tot, s, &len);
      [CWParser parseSubject:  [NSData dataWithBytes: s  length: len]  inMessage: aMessage  quick: YES];
      tot += len+2;
      
      // .823ms (+92ms), .80ms
      read_string_memory(r+tot, s, &len);
      [CWParser parseDestination: [NSData dataWithBytes: s  length: len]
		forType: PantomimeToRecipient
		inMessage: aMessage
		quick: YES];
      tot += len+2;
      
      // .948ms (+125 to +163ms)
      read_string_memory(r+tot, s, &len);
      [CWParser parseDestination: [NSData dataWithBytes: s  length: len]
		forType: PantomimeCcRecipient
		inMessage: aMessage
		quick: YES];

      free(r);
    }

  free(s);
}

//
// access/mutation methods
//
- (NSDate *) modificationDate
{
  return [NSDate dateWithTimeIntervalSince1970: _modification_date];
}

- (void) setModificationDate: (NSDate *) theDate
{
  _modification_date = [theDate timeIntervalSince1970];
}

//
//
//
- (unsigned int) fileSize
{
  return _size;
}

- (void) setFileSize: (unsigned int) theSize
{
  _size = theSize;
}

//
//
//
- (BOOL) synchronize
{
  NSDictionary *attributes; 
  CWLocalMessage *aMessage;
  unsigned int len, flags;
  int i;

  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [(CWLocalFolder *)_folder path]
						   traverseLink: NO];
    }
  else
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [NSString stringWithFormat: @"%@/cur", [(CWLocalFolder *)_folder path]]
						   traverseLink: NO];
    }
  
  _modification_date = [[attributes objectForKey: NSFileModificationDate] timeIntervalSince1970];
  _count = [_folder->allMessages count];

  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
    }
  
  // We write our cache version, count, modification date and size.
  write_unsigned_short(_fd, version);
  write_unsigned_int(_fd, _count);
  write_unsigned_int(_fd, _modification_date);

  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
    {
      _size = [[attributes objectForKey: NSFileSize] intValue];
      write_unsigned_int(_fd, _size);
    }

  // We now update the message flags
  //NSLog(@"Synching flags for mailbox %@, count = %d", [(CWLocalFolder *)_folder path], _count);
  for (i = 0; i < _count; i++)
    {
      len = read_unsigned_int(_fd);
      //NSLog(@"len = %d", len);

      if ((NSNull *)(aMessage = [_folder->allMessages objectAtIndex: i]) != [NSNull null])
	{
	  flags = ((CWFlags *)[aMessage flags])->flags;
	  write_unsigned_int(_fd, flags);
	  lseek(_fd, (len-8), SEEK_CUR);
	  //NSLog(@"wrote = %d", flags);
	}
      else
	{
	  lseek(_fd, (len-4), SEEK_CUR);
	}
    }
  //NSLog(@"Done!");
 
  return (fsync(_fd) == 0);
}


//
//
//
- (NSUInteger) count
{
  return _count;
}

//
//
//
- (void) writeRecord: (cache_record *) theRecord
{
  unsigned int len;

  if (lseek(_fd, 0L, SEEK_END) < 0)
    {
      NSLog(@"COULD NOT LSEEK TO END OF FILE");
      abort();
    }
  
  // We calculate the length of this record (including the
  // first five fields, which is 20 bytes long and is added
  // at the very end)
  len = 0;
  len += [theRecord->from length]+2;
  len += [theRecord->in_reply_to length]+2;
  len += [theRecord->message_id length]+2;
  len += [theRecord->references length]+2;
  len += [theRecord->subject length]+2;
  len += [theRecord->to length]+2;
  len += [theRecord->cc length]+2;

  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMaildir)
    {
      len += strlen(theRecord->filename)+2;
      len += 16;
    }
  else
    {
      len += 20;
    }

  // We write the length of our entry
  write_unsigned_int(_fd, len);

  // We write the flags, date, position and the size of the message.
  write_unsigned_int(_fd, theRecord->flags);
  write_unsigned_int(_fd, theRecord->date);

  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
    {
      write_unsigned_int(_fd, theRecord->position);
    }
  else
    {
      write_string(_fd, (unsigned char *)theRecord->filename, strlen(theRecord->filename));
    }
  
  write_unsigned_int(_fd, theRecord->size);
  
  // We write the read of our cached headers (From, In-Reply-To, Message-ID, References, Subject and To)
  write_string(_fd, (unsigned char *)[theRecord->from bytes], [theRecord->from length]);
  write_string(_fd, (unsigned char *)[theRecord->in_reply_to bytes], [theRecord->in_reply_to length]);
  write_string(_fd, (unsigned char *)[theRecord->message_id bytes], [theRecord->message_id length]);
  write_string(_fd, (unsigned char *)[theRecord->references bytes], [theRecord->references length]);
  write_string(_fd, (unsigned char *)[theRecord->subject bytes], [theRecord->subject length]);
  write_string(_fd, (unsigned char *)[theRecord->to bytes], [theRecord->to length]);
  write_string(_fd, (unsigned char *)[theRecord->cc bytes], [theRecord->cc length]);

  _count++;
}


//
// For mbox-based and maildir-base cache:
//
// This method MUST be called after writing the new mbox
// on disk but BEFORE we actually removed the deleted
// messages from the allMessages ivar.
//
//
- (void) expunge
{
  NSDictionary *attributes;
  CWLocalMessage *aMessage;

  unsigned int cache_size, flags, i, len, total_deleted, total_length, type, v;
  short delta;
  char *buf;

  //NSLog(@"rewriting cache");

  // We get the current cache size
  cache_size = lseek(_fd, 0L, SEEK_END);

  if (lseek(_fd, ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox) ? 14L : 10L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
      abort();
    }

  total_deleted = total_length = 0;  
  type = [(CWLocalFolder *)_folder type];
  
  //
  // We alloc a little bit more memory that we really need in
  // case we have to rewrite the filename for a maildir cache
  // and the filename length is greater than the previous one.
  //
  buf = (char *)malloc(cache_size+[_folder count]*10);
  _count = [_folder->allMessages count];

  for (i = 0; i < _count; i++)
    {
      len = read_unsigned_int(_fd);
      aMessage = [_folder->allMessages objectAtIndex: i];
      flags = ((CWFlags *)[aMessage flags])->flags;
      delta = 0;

      if ((flags&PantomimeDeleted) == PantomimeDeleted)
	{
	  // We skip over that record
	  lseek(_fd, len-4, SEEK_CUR);
	  total_deleted++;
	  //NSLog(@"Skip %d bytes, index %d!", len, i);
	}
      else
	{	  
	  //
	  // For mbox-based caches, we must update the file position of
	  // our cache entries and also the size of the message in the cache.
	  //
	  if (type == PantomimeFormatMbox)
	    {
	      // We write the rest of the record into the memory
	      if (read(_fd, (buf+total_length+4), len-4) < 0) { NSLog(@"read failed"); abort(); }

	      // We update the position in the mailbox file by
	      // overwriting the current value in memory
	      v = htonl([aMessage filePosition]);
	      memcpy((buf+total_length+12), (char *)&v, 4);
	      //NSLog(@"Wrote file position %d", ntohl(v));
	      
	      // We update the size of the message by overwriting
	      // the current value in memory
	      v = htonl([aMessage size]);
	      memcpy((buf+total_length+16), (char *)&v, 4);
	      //NSLog(@"Wrote message size %d", ntohl(v));
	    }
	  //
	  // For maildir-based caches, we must update the filename of our
	  // cache entries in case flags were flushed to the disk.
	  //
	  else
	    {
	      unsigned short c0, c1, old_len, r;
	      char *filename;
	      int s_len;

	      // We read our Flags, Date, and the first two bytes
	      // of our filename into memory.
	      if (read(_fd, (buf+total_length+4), 10) < 0) { NSLog(@"read failed"); abort(); }

	      // We read the length of our previous string
	      c0 = *(buf+total_length+12);
	      c1 = *(buf+total_length+13);
	      old_len = ntohs((c1<<8)|c0);

	      //NSLog(@"Previous length = %d  Filename = |%@|", old_len, [aMessage mailFilename]);
	      filename = (char *)[[aMessage mailFilename] UTF8String];
	      s_len = strlen(filename);
	      delta = s_len-old_len;
	      
	      //if (delta != 0) NSLog(@"i = %d  delta = %d |%@| s_len = %d", i, delta, [aMessage mailFilename], s_len);
	      
	      // We write back our filename
	      r = htons(s_len);
	      memcpy((buf+total_length+12), (char *)&r, 2);
	      memcpy((buf+total_length+14), filename, s_len);

	      // We read the rest in our memory. We first skip or old filename string.
	      if (lseek(_fd, old_len, SEEK_CUR) < 0) { NSLog(@"lseek failed"); abort(); }
	      //NSLog(@"must read back into memory %d bytes", len-old_len-14);
	      if (read(_fd, (buf+total_length+s_len+14), len-old_len-14) < 0) { NSLog(@"read failed"); abort(); }
	      //NSLog(@"current file pos after full read %d", lseek(_fd, 0L, SEEK_CUR));
	    }

	  // We write back our record length, adjusting its size if we need
	  // to, in the case we are handling a maildir-based cache.
	  len += delta;
	  v = htonl(len);
	  memcpy((buf+total_length), (char *)&v, 4);

	  total_length += len;
	  //NSLog(@"_size = %d  total_length = %d", _size, total_length);
	}
    }

  if (lseek(_fd, 0L, SEEK_SET) < 0)
    {
      NSLog(@"fseek failed");
    }

  // We write our cache version, count, modification date our new size
  cache_size = total_length+([(CWLocalFolder *)_folder type] == PantomimeFormatMbox ? 14 : 10);
  _count -= total_deleted;

  write_unsigned_short(_fd, version);
  write_unsigned_int(_fd, _count);

  if ([(CWLocalFolder *)_folder type] == PantomimeFormatMbox)
      {
	attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [(CWLocalFolder *)_folder path]
						     traverseLink: NO];
	
	_modification_date = [[attributes objectForKey: NSFileModificationDate] timeIntervalSince1970];
	_size = [[attributes objectForKey: NSFileSize] intValue];
	write_unsigned_int(_fd, _modification_date);
	write_unsigned_int(_fd, _size);
      }
  else
    {
      attributes = [[NSFileManager defaultManager] fileAttributesAtPath: [NSString stringWithFormat: @"%@/cur", [(CWLocalFolder *)_folder path]]
						   traverseLink: NO];
      _modification_date = [[attributes objectForKey: NSFileModificationDate] timeIntervalSince1970];
      _size = 0;
      write_unsigned_int(_fd, _modification_date);
    }
  
  // We write our memory cache
  write(_fd, buf, total_length);

  //ftruncate(_fd, _size);
  ftruncate(_fd, cache_size);
  free(buf);

  //NSLog(@"Done!");
}
@end
