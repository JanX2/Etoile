/*
**  CWCacheManager.h
**
**  Copyright (c) 2004-2007
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

#ifndef _Pantomime_H_CWCacheManager
#define _Pantomime_H_CWCacheManager

#import <Foundation/NSArray.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>

//
//
//
typedef struct {
  unsigned int date;
  unsigned int flags;
  unsigned int position;   // For mbox based cache files
  unsigned int size;
  unsigned int imap_uid;   // For IMAP
  char *filename;          // For maildir base cache files
  NSString *pop3_uid;      // For POP3
  NSData *from;
  NSData *in_reply_to;
  NSData *message_id;
  NSData *references;
  NSData *subject;
  NSData *to;
  NSData *cc;
} cache_record;

//
// Simple macro used to initialize a record to some
// default values. Faster than a memset().
//
#define CLEAR_CACHE_RECORD(r) \
 r.date = 0; \
 r.flags = 0; \
 r.position = 0; \
 r.size = 0; \
 r.imap_uid = 0; \
 r.pop3_uid = nil;\
 r.from = nil; \
 r.in_reply_to = nil; \
 r.message_id = nil; \
 r.references = nil; \
 r.subject = nil; \
 r.to = nil; \
 r.cc = nil;

/*!
  @class CWCacheManager
  @discussion This class is used to provide a generic superclass for
              cache management with regard to various CWFolder sub-classes.
	      CWIMAPFolder, CWLocalFolder and CWPOP3Folder can make use of a
	      cache in order to speedup lots of operations.
*/
@interface CWCacheManager : NSObject
{
  @protected
    NSMutableArray *_cache;
    NSString *_path;
    unsigned int _count;
    int _fd;
}

/*!
  @method initWithPath:
  @discussion This method is the designated initializer for the
              CWCacheManager class.
  @param thePath The complete path where the cache will be eventually
                 saved to.
  @result A CWCacheManager subclass instance, nil on error.
*/
- (id) initWithPath: (NSString *) thePath;

/*!
  @method path
  @discussion This method is used to obtain the path where the
              cache has been loaded for or where it'll be saved to.
  @result The path.
*/
- (NSString *) path;

/*!
  @method setPath:
  @discussion This method is used to set the path where the
              cache will be loaded from or where it'll be saved to.
  @param thePath The complete path.
*/
- (void) setPath: (NSString *) thePath;

/*!
  @method invalidate
  @discussion This method is used to invalide all cache entries.
*/
- (void) invalidate;

/*!
  @method synchronize
  @discussion This method is used to save the cache on disk.
              If the cache is empty, this method does not
	      write it on disk and returns YES.
  @result YES on success, NO otherwise.
*/
- (BOOL) synchronize;

/*!
  @method count
  @discussion This method returns the number of cache_record
              entries present in the cache.
  @result The count;
*/
- (unsigned int) count;

@end

#endif // _Pantomime_H_CWCacheManager
