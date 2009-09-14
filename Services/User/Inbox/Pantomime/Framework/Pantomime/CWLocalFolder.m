/*
**  CWLocalFolder.m
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
#include <Pantomime/CWLocalFolder.h>

#include <Pantomime/CWConstants.h>
#include <Pantomime/CWRegEx.h>
#include <Pantomime/CWFlags.h>
#include <Pantomime/CWInternetAddress.h>
#include <Pantomime/CWLocalCacheManager.h>
#include <Pantomime/CWLocalFolder+maildir.h>
#include <Pantomime/CWLocalFolder+mbox.h>
#include <Pantomime/CWLocalMessage.h>
#include <Pantomime/CWLocalStore.h>
#include <Pantomime/CWMIMEMultipart.h>
#include <Pantomime/NSData+Extensions.h>
#include <Pantomime/NSFileManager+Extensions.h>
#include <Pantomime/NSString+Extensions.h>

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSHost.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSPathUtilities.h>

#include <ctype.h>
#include <fcntl.h>
#include <string.h>
#include <sys/file.h> // FIXME remove
#include <time.h>
#include <unistd.h>   // FIXME remove

#define FOLDER_APPEND_FAILED \
  aDictionary = (theFlags ? [NSDictionary dictionaryWithObjectsAndKeys: theData, @"NSData", self, @"Folder", theFlags, @"Flags", nil] : \
		 [NSDictionary dictionaryWithObjectsAndKeys: theData, @"NSData", self, @"Folder", nil]); \
	  PERFORM_SELECTOR_3([[self store] delegate], @selector(folderAppendFailed:), PantomimeFolderAppendFailed, aDictionary); \
  RELEASE(aMutableData); \
  RELEASE(pool); \
  return;

//
// Private methods
//
@interface CWLocalFolder (Private)

- (BOOL) _findInPart: (CWPart *) thePart
              string: (NSString *) theString
                mask: (PantomimeSearchMask) theMask
             options: (PantomimeSearchOption) theOptions;
@end


//
//
//
@implementation CWLocalFolder

- (id) initWithPath: (NSString *) thePath
{
  BOOL b;

  self = [super initWithName: [thePath lastPathComponent]];

  // We initialize those ivars in order to make sure we don't call
  // the assertion handler when using a maildir-based mailbox.
  stream = NULL;
  fd = -1;

  [self setPath: thePath];
   
  if ([[NSFileManager defaultManager] fileExistsAtPath: [NSString stringWithFormat: @"%@/new", _path]  isDirectory: &b] && b)
    {
      [self setType: PantomimeFormatMaildir];
    }
  else
    {
      [self setType: PantomimeFormatMbox];

      // We verify if a <name>.tmp was present. If yes, we simply remove it.
      if ([[NSFileManager defaultManager] fileExistsAtPath: [thePath stringByAppendingString: @".tmp"]])
	{
	  [[NSFileManager defaultManager] removeFileAtPath: [thePath stringByAppendingString: @".tmp"]
					  handler: nil];
	}
    }

  if ((_type == PantomimeFormatMbox) && ![self open_mbox])
    {
      AUTORELEASE(self);
      return nil;
    }
  
  return self;
}


//
//
//
- (void) dealloc
{
  //NSLog(@"LocalFolder: -dealloc. fd = %d, stream is NULL? %d", fd, (stream == NULL));

  NSAssert3(fd < 0 && !stream, @"-[%@ %@, path %@] must invoke -close before - dealloc'ing",
	    NSStringFromClass(isa), NSStringFromSelector(_cmd), _path);

  RELEASE(_path);
  [super dealloc];
}


//
//
//
- (void) parse: (BOOL) theBOOL
{
  NSAutoreleasePool *pool;
  
  //
  // If we already have messages in our folder, that means parse was already invoked.
  // In this particular case, we do nothing. If we got no messages but we already
  // have invoked -parse before, that won't do any harm.
  //
  if ([allMessages count])
    {
      // 
      // If we are using a maildir-based mailbox, we scan the /new and /tmp directories
      // in order to move any messages in there to our /cur directory.
      //
      if (_type == PantomimeFormatMaildir)
	{  
	  NSFileManager *aFileManager;
	  
	  aFileManager = [NSFileManager defaultManager];
	  
	  if ([[aFileManager directoryContentsAtPath: [NSString stringWithFormat: @"%@/new", _path]] count] > 0 || 
	      [[aFileManager directoryContentsAtPath: [NSString stringWithFormat: @"%@/tmp", _path]] count] > 0)
	    {
	      pool = [[NSAutoreleasePool alloc] init];
	      [self parse_maildir: @"new"  all: theBOOL];
	      [self parse_maildir: @"tmp"  all: theBOOL];
	      RELEASE(pool);
	    }
	}


      PERFORM_SELECTOR_2([[self store] delegate], @selector(folderPrefetchCompleted:), PantomimeFolderPrefetchCompleted, self, @"Folder");
      return;
    }

 
  //
  // We are NOT using the cache.
  //
  pool = [[NSAutoreleasePool alloc] init];
  
  //
  // Parse the mail store. For mbox, it will be one file.
  // For maildir, there will be a file for each message 
  // in the "cur" and "new" sub-directories.
  //
  switch (_type)
    {
    case PantomimeFormatMaildir:
      [self parse_maildir: @"cur"  all: theBOOL];
      [self parse_maildir: @"new"  all: theBOOL];
      break;
    case PantomimeFormatMbox:
    default:
      [self parse_mbox: _path  stream: [self stream]  flags: nil  all: theBOOL];
      break;
    }
  
  PERFORM_SELECTOR_2([[self store] delegate], @selector(folderPrefetchCompleted:), PantomimeFolderPrefetchCompleted, self, @"Folder");
  RELEASE(pool);
}





//
// This method is used to close the current folder.
// It creates a temporary file where the folder is written to and
// it replaces the current folder file by this one once everything is
// alright.
//
- (void) close
{  
  //NSLog(@"LocalFolder: -close");

  // We close the current folder
  if (_type == PantomimeFormatMbox || _type == PantomimeFormatMailSpoolFile)
    {
      [self close_mbox];
    }
  
  // We synchorize our cache one last time
  if (_type == PantomimeFormatMbox || _type == PantomimeFormatMaildir)
    {
      [_cacheManager synchronize];
    }

  POST_NOTIFICATION(PantomimeFolderCloseCompleted, _store, [NSDictionary dictionaryWithObject: self  forKey: @"Folder"]);
  PERFORM_SELECTOR_2([_store delegate], @selector(folderCloseCompleted:), PantomimeFolderCloseCompleted, self, @"Folder");

  // We remove our current folder from the list of open folders in the store
  [_store removeFolderFromOpenFolders: self];
}


//
// This method permanently removes messages that have the flag PantomimeDeleted.
//
- (void) expunge
{
  switch (_type)
    {
    case PantomimeFormatMbox:
      [self expunge_mbox];
      break;
    case PantomimeFormatMaildir:
      [self expunge_maildir];
      break;
    default:
      {
	// Do nothing.
      }
    }
  
  if (_allContainers)
    {
      [self thread];
    }
}


//
// access / mutation methods
//

//
// This method returns the file descriptor used by this local folder.
//
- (int) fd
{
  return fd;
}


//
// This method sets the file descriptor to be used by this local folder.
//
- (void) setFD: (int) theFD
{
  fd = theFD;
}


//
//
//
- (NSString *) path
{
  return _path;
}


- (void) setPath: (NSString *) thePath
{
  ASSIGN(_path, thePath);
}


//
// This method returns the file stream used by this local folder.
//
- (FILE *) stream
{
  return stream;
}


//
// This method sets the file stream to be used by this local folder.
//
- (void) setStream: (FILE *) theStream
{
  stream = theStream;
}


//
//
//
- (PantomimeFolderFormat) type
{
  return _type;
}

- (void) setType: (PantomimeFolderFormat) theType
{
  _type = theType;
}


//
//
//
- (PantomimeFolderMode) mode
{
  return PantomimeReadWriteMode;
}


//
// This method is used to append a message to this folder. The message
// must be specified in raw source. The message is appended to the 
// local file and is initialized after.
//
- (void) appendMessageFromRawSource: (NSData *) theData
                              flags: (CWFlags *) theFlags
{
  NSString *aMailFile, *aMailFilePath;
  NSMutableData *aMutableData;
  NSDictionary *aDictionary;
  CWLocalMessage *aMessage;
  NSAutoreleasePool *pool;
  FILE *aStream;
  
  long mark, file_position;

  pool = [[NSAutoreleasePool alloc] init];

  aMutableData = [[NSMutableData alloc] initWithData: theData];
  aMailFile = nil;
  aStream = NULL;

  if (!theData || [theData length] == 0)
    {
      FOLDER_APPEND_FAILED;
    }

  // Set the appropriate stream
  if (_type == PantomimeFormatMaildir)
    {
      aMailFile = [NSString stringWithFormat: @"%@:%@", [NSString stringWithFormat: @"%d.%d%d%d.%@",
								  time(NULL), 
								  getpid(),
								  rand(),
								  [_cacheManager count],
								  [[NSHost currentHost] name]],
			    ((id)theFlags ? (id)[theFlags maildirString] : (id)@"2,")];
      
      aMailFilePath = [NSString stringWithFormat: @"%@/cur/%@", _path, aMailFile];

#ifdef __MINGW32__      
      aStream = fopen([aMailFilePath UTF8String], "bw+");
#else
      aStream = fopen([aMailFilePath UTF8String], "w+");
#endif

      if (!aStream)
	{
	  FOLDER_APPEND_FAILED;
	}
    }
  else
    {
      aStream = [self stream];
      aMailFilePath = _path;
    }


  // We keep the position where we were in the file
  mark = ftell(aStream);

  if (mark < 0)
    {
      FOLDER_APPEND_FAILED;
    }
  
  //
  // If the message doesn't contain the "From ", we add it.
  //
  // From qmail's mbox(5) man page:
  //
  //   The  From_  line  always  looks  like  From  envsender  date
  //   moreinfo.  envsender is one word, without spaces or tabs; it
  //   is usually the envelope sender of the message.  date is  the
  //   delivery date of the message.  It always contains exactly 24
  //   characters in asctime format.  moreinfo is optional; it  may
  //   contain arbitrary information.
  //
  if (![aMutableData hasCPrefix: "From "] && _type == PantomimeFormatMbox)
    {
      NSString *aString;

      // If there was no envelope sender, by convention the mailbox name used is MAILER-DAEMON.
      // Whitespace characters in the envelope sender mailbox name are by convention replaced by hyphens.
      aString = [NSString stringWithFormat: @"From MAILER-DAEMON %@\n", [[NSCalendarDate calendarDate]
									  descriptionWithCalendarFormat: @"%a %b %d %H:%M:%S %Y"]];
      [aMutableData insertCString: [aString cString]  atIndex: 0];
    }
  
  // We MUST replace every "\nFrom " in the message by "\n From ", if we have a mbox file.
  if (_type == PantomimeFormatMbox)
    {
      NSRange aRange;

      aRange = [aMutableData rangeOfCString: "\nFrom "];
      
      while (aRange.location != NSNotFound)
	{
	  [aMutableData replaceBytesInRange: aRange  withBytes: "\n From "];
	  
	  aRange = [aMutableData rangeOfCString: "\nFrom "
				 options: 0
				 range: NSMakeRange(aRange.location + aRange.length,
						    [aMutableData length] - aRange.location - aRange.length) ];
	}
  
      //
      // From qmail's mbox(5) man page:
      //
      //  A message encoded in mbox format begins with a  From_  line,
      //  continues  with a series of non-From_ lines, and ends with a
      //  blank line.
      //  ...
      //  The final line is a completely  blank  line  (no  spaces  or
      //  tabs).  Notice that blank lines may also appear elsewhere in
      //  the message.
      //
      [aMutableData appendCString: "\n\n"];
    }
  
  // We go at the end of the file...
  if (fseek(aStream, 0L, SEEK_END) < 0)
    {
      FOLDER_APPEND_FAILED;
    }
  
  // We get the position of our message in the file. We need
  // to keep it in order to correctly seek back at the beginning
  // of the message to parse it.
  if ((file_position = ftell(aStream)) < 0)
    {
      FOLDER_APPEND_FAILED;
    }
      
  // We write the string to our local folder
  if (fwrite([aMutableData bytes], 1, [aMutableData length], aStream) <= 0)
    {
      FOLDER_APPEND_FAILED;
    }

  // We parse the message using our code, which will also update
  // our cache if present
  if (fseek(aStream, file_position, SEEK_SET) < 0)
    {
      FOLDER_APPEND_FAILED;
    }
  
  [self parse_mbox: aMailFile  stream: aStream  flags: theFlags  all: NO];
  
  // We get back our message
  aMessage = [allMessages objectAtIndex: [allMessages count]-1];

  // We set our flags
  if (theFlags)
    {
      [aMessage setFlags: theFlags];
    }

  // We finally reset our fp where the mark was set
  if (_type != PantomimeFormatMaildir)
    {
      if (fseek(aStream, mark, SEEK_SET) < 0)
	{
	  FOLDER_APPEND_FAILED;
	}
    }
  else
    {
      if (fclose(aStream) != 0)
	{
	  FOLDER_APPEND_FAILED;
	}
    }
  
  aDictionary = (theFlags ? [NSDictionary dictionaryWithObjectsAndKeys: theData, @"NSData", self, @"Folder", theFlags, @"Flags", nil] :
		 [NSDictionary dictionaryWithObjectsAndKeys: theData, @"NSData", self, @"Folder", nil]);
  PERFORM_SELECTOR_3([[self store] delegate], @selector(folderAppendCompleted:), PantomimeFolderAppendCompleted, aDictionary);

  RELEASE(aMutableData);
  RELEASE(pool);
}


//
//
//
- (void) search: (NSString *) theString
	   mask: (PantomimeSearchMask) theMask
	options: (PantomimeSearchOption) theOptions
{
  NSMutableArray *aMutableArray;
  NSAutoreleasePool *pool;
  NSDictionary *userInfo;
  CWLocalMessage *aMessage;

  int i, count;

  aMutableArray = [NSMutableArray array];

  pool = [[NSAutoreleasePool alloc] init];
  count = [allMessages count];

  for (i = 0; i < count; i++)
    {
      aMessage = [allMessages objectAtIndex: i];
          
      //
      // We search inside the Message's content.
      //
      if (theMask == PantomimeContent)
	{
	  BOOL messageWasInitialized, messageWasMatched;
	  
	  messageWasInitialized = [aMessage isInitialized];
	  messageWasMatched = NO;
	  
	  if (!messageWasInitialized)
	    {
	      [aMessage setInitialized: YES];
	    }
	  
	  // We search recursively in all Message's parts
	  if ([self _findInPart: (CWPart *)aMessage
		    string: theString
		    mask: theMask
		    options: theOptions])
	    {
	      [aMutableArray addObject: aMessage];
	      messageWasMatched = YES;
	    }
	  
	  // We restore the message initialization status if the message doesn't match
	  if (!messageWasInitialized && !messageWasMatched)
	    {
	      [aMessage setInitialized: NO];
	    }
	}
      //
      // We aren't searching in the content. For now, we search only in the Subject header value.
      //
      else
	{
	  NSString *aString;

	  aString = nil;

	  switch (theMask)
	    {
	    case PantomimeFrom:
	      if ([aMessage from])
		{
		  aString = [[aMessage from] stringValue];
		}
	      break;
	      
	    case PantomimeTo:
	      aString = [NSString stringFromRecipients: [aMessage recipients]
				  type: PantomimeToRecipient];
	      break;

	    case PantomimeSubject:
	    default:
	      aString = [aMessage subject];
	    }
	 
	  
	  if (aString)
	    {
	      if ((theOptions&PantomimeRegularExpression))
		{
		  NSArray *anArray;
		  
		  anArray = [CWRegEx matchString: aString
				     withPattern : theString
				     isCaseSensitive: (theOptions&PantomimeCaseInsensitiveSearch)];
		  
		  if ([anArray count] > 0)
		    {
		      [aMutableArray addObject: aMessage];
		    }
		}
	      else
		{
		  NSRange aRange;
		  
		  if ((theOptions&PantomimeCaseInsensitiveSearch))
		    {
		      aRange = [aString rangeOfString: theString
					options: NSCaseInsensitiveSearch]; 
		    }
		  else
		    {
		      aRange = [aString rangeOfString: theString]; 
		    }
		  
		  if (aRange.length > 0)
		    {
		      [aMutableArray addObject: aMessage];
		    }
		}
	    }
	}
    } // for (i = 0; ...
	  
  RELEASE(pool);

  userInfo = [NSDictionary dictionaryWithObjectsAndKeys: self, @"Folder", aMutableArray, @"Results", nil];

  POST_NOTIFICATION(PantomimeFolderSearchCompleted, [self store], userInfo);
  PERFORM_SELECTOR_3([[self store] delegate], @selector(folderSearchCompleted:), PantomimeFolderSearchCompleted, userInfo);
}

@end


//
// Private methods
//
@implementation CWLocalFolder (Private)

- (BOOL) _findInPart: (CWPart *) thePart
	      string: (NSString *) theString
		mask: (PantomimeSearchMask) theMask
             options: (PantomimeSearchOption) theOptions
  
{  
  if ([[thePart content] isKindOfClass:[NSString class]])
    {
      // The part content is text; we perform the search      
      if ((theOptions&PantomimeRegularExpression))
	{
	  // The search pattern is a regexp

	  NSArray *anArray;
	  
	  anArray = [CWRegEx matchString: (NSString *)[thePart content]
			     withPattern : theString
			     isCaseSensitive: (theOptions&PantomimeCaseInsensitiveSearch)];
		  
	  if ([anArray count] > 0)
	    {
	      return YES;
	    }
	}
      else
	{
	  NSRange range;

	  if (theOptions&PantomimeCaseInsensitiveSearch)
	    {
	      range = [(NSString *)[thePart content] rangeOfString: theString
				   options: NSCaseInsensitiveSearch];
	    }
	  else
	    {
	      range = [(NSString *)[thePart content] rangeOfString: theString]; 
	    }
		  
	  if (range.length > 0)
	    {
	      return YES;
	    }
	}
    }
  
  else if ([[thePart content] isKindOfClass: [CWMessage class]])
    {
      // The part content is a message; we parse it recursively
      return [self _findInPart: (CWPart *)[thePart content]
		   string: theString
		   mask: theMask
		   options: theOptions];
    }
  else if ([[thePart content] isKindOfClass: [CWMIMEMultipart class]])
    {
      // The part content contains many part; we parse each part
      CWMIMEMultipart *aMimeMultipart;
      CWPart *aPart;
      int i, count;
      
      aMimeMultipart = (CWMIMEMultipart*)[thePart content];
      count = [aMimeMultipart count];
      
      for (i = 0; i < count; i++)
	{
	  // We get our part
	  aPart = [aMimeMultipart partAtIndex: i];
	  
	  if ([self _findInPart: (CWPart *)aPart
		     string: theString 
		     mask: theMask
		     options: theOptions])
	    {
	      return YES;
	    }
	}
    }
  
  return NO;
}

@end
