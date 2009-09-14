/*
**  CWLocalFolder+maildir.m
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

#include <Pantomime/CWLocalFolder+maildir.h>

#include <Pantomime/CWFlags.h>
#include <Pantomime/CWLocalCacheManager.h>
#include <Pantomime/CWLocalFolder+mbox.h>
#include <Pantomime/CWLocalMessage.h>
#include <Pantomime/CWLocalStore.h>
#include <Pantomime/NSString+Extensions.h>

#include <Foundation/NSFileManager.h>
#include <Foundation/NSNotification.h>

//
// The maildir format is well documented here:
//
// http://www.qmail.org/man/man5/maildir.html
// http://cr.yp.to/proto/maildir.html
//
@implementation CWLocalFolder (maildir)

- (void) expunge_maildir
{
  NSMutableArray *aMutableArray;
  CWLocalMessage *aMessage;
  CWFlags *theFlags;
  int count, i, msn;
  
  aMutableArray = AUTORELEASE([[NSMutableArray alloc] init]);
  count = [allMessages count];

  // We assume that our write operation was successful and we initialize our msn to 1
  msn = 1;
  
  for (i = 0; i < count; i++)
    {
      aMessage = [allMessages objectAtIndex: i];
      
      theFlags = [aMessage flags];
      
      if ([theFlags contain: PantomimeDeleted])
	{
	  [[NSFileManager defaultManager] removeFileAtPath: [NSString stringWithFormat: @"%@/cur/%@", [self path], [aMessage mailFilename]]
					  handler: nil];
	  [aMutableArray addObject: aMessage];
	}
      else
	{
	  // rewrite the message to account for changes in the flags
	  NSString *uniquePattern, *newFileName;
	  int indexOfPatternSeparator;
  
	  // We update our message's ivars (folder and size don't change)
	  [aMessage setMessageNumber: msn];
	  msn++;

	  // we rename the message according to the maildir spec by appending the status information the name
	  // name of file will be unique_pattern:info with the status flags in the info field
	  indexOfPatternSeparator = [[aMessage mailFilename] indexOfCharacter: ':'];
	  
	  if (indexOfPatternSeparator > 1)
	    {
	      uniquePattern = [[aMessage mailFilename] substringToIndex: indexOfPatternSeparator];
	    }
	  else
	    {
	      uniquePattern = [aMessage mailFilename];
	    }

	  // We build the new file name
	  newFileName = [NSString stringWithFormat: @"%@:%@", uniquePattern, [theFlags maildirString]];

	  // We rename the message file
	  if ([[NSFileManager defaultManager] movePath: [NSString stringWithFormat: @"%@/cur/%@", [self path], [aMessage mailFilename]]
					      toPath: [NSString stringWithFormat: @"%@/cur/%@", [self path], newFileName]
					      handler: nil])
	    {
	      [aMessage setMailFilename: newFileName];
	    }
	}
    }
    
  // We sync our cache
  if (_cacheManager) [_cacheManager expunge];
  [allMessages removeObjectsInArray: aMutableArray];
  
#warning also return when invoking the delegate
  POST_NOTIFICATION(PantomimeFolderExpungeCompleted, self, nil);
  PERFORM_SELECTOR_2([[self store] delegate], @selector(folderExpungeCompleted:), PantomimeFolderExpungeCompleted, self, @"Folder");
}


//
// This parses a local structure for messages by looking in the "cur" and "new" sub-directories.
//
- (void) parse_maildir: (NSString *) theDirectory  all: (BOOL) theBOOL
{
  NSString *aPath, *aNewPath, *thisMailFile;
  NSFileManager *aFileManager;
  NSMutableArray *allFiles;
  FILE *aStream;
  int i, count;
  BOOL b;

  if (!theDirectory)
    {
      return;
    }

  // We check if we must later move the file after
  // parsing it.
  b = NO;

  if ([theDirectory isEqualToString: @"new"] || [theDirectory isEqualToString: @"tmp"])
    {
      b = YES;
    }
  
  aFileManager = [NSFileManager defaultManager];

  // Read the directory
  aPath = [NSString stringWithFormat: @"%@/%@", _path, theDirectory];
  allFiles = [[NSMutableArray alloc] initWithArray: [aFileManager directoryContentsAtPath: aPath]];

  // We remove Apple Mac OS X .DS_Store file
  [allFiles removeObject: @".DS_Store"];
  count = [allFiles count];
  
  if (allFiles != nil && count > 0)
    {
      for (i = 0; i < count; i++)
	{
	  thisMailFile = [NSString stringWithFormat: @"%@/%@", aPath, [allFiles objectAtIndex: i]];

	  if (b)
	    {
	      aNewPath = [NSString stringWithFormat: @"%@/cur/%@", _path, [allFiles objectAtIndex: i]];
	    }

#ifdef __MINGW32__
	  aStream = fopen([thisMailFile UTF8String], "rb");
#else
	  aStream = fopen([thisMailFile UTF8String], "r");
#endif

	  if (!aStream)
	    {
	      continue;
	    }
	 
	  [self parse_mbox: (b ? aNewPath : thisMailFile)  stream: aStream  flags: nil  all: theBOOL];
	  
	  fclose(aStream);
	  
	  // If we read this from the "new" or "tmp" sub-directories,
	  // move it to the "cur" directory
	  if (b)
	    {
	      [aFileManager movePath: thisMailFile  toPath: aNewPath  handler: nil];
	    }	  
	}

      [_cacheManager synchronize];
    }

  RELEASE(allFiles);
}

@end
