/*
   Project: mkgbom

   Copyright (C) 2005 Frederico Muñoz 

   Author: Frederico Muñoz

   Created: 2005-03-05 15:03:12 +0000 by fsmunoz

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <Foundation/Foundation.h>

int
main(int argc, const char *argv[])
{
  id pool = [[NSAutoreleasePool alloc] init];

  NSFileManager *manager = [NSFileManager defaultManager];
  NSArray *args = [[NSProcessInfo processInfo]arguments];
  //NSString *appDir = @"/home/fsmunoz/Code/AClock-0.2.3.pkg/AClock.app";
  NSString *appDir = [NSString stringWithString : [args objectAtIndex: 1]];
  //  NSString *appDir = @"/home/fsmunoz/Code";
  NSMutableDictionary *bom = [NSMutableDictionary new];
  NSMutableDictionary *fileAttrs = [NSMutableDictionary new];
  NSMutableDictionary *files = [NSMutableDictionary new];
  NSMutableDictionary *sizes = [NSMutableDictionary new];
  NSData *bomData;
  NSEnumerator *enumerator;
  NSLog (@"Appdir: %@", appDir);  
  int fileNumber = 0;
  unsigned long long totalSize = 0;

  if ([manager fileExistsAtPath:appDir])
    {
      NSLog (@"Root package contents found");

      NSString *file;
      NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: appDir];

      //        if ([manager changeCurrentDirectoryPath: appDir])
      //  	NSLog (@"Changed to package contents directory");
      //        else
      //  	 NSLog (@"Directory change failed!");
      
      //      [files setObject:  forKey: file];

      while (file = [dirEnum nextObject]) 
	{
	  
	  NSLog (@"Processing %@", file);
	  fileAttrs = [NSMutableDictionary dictionaryWithDictionary:[manager fileAttributesAtPath: [appDir stringByAppendingPathComponent:file] traverseLink: NO]];
	  
	  
	  // 	  NSLog (@"Owner: %@  UID: %@ Size: %@", 
	  // 		 [fileAttrs objectForKey: @"NSFileOwnerAccountName"], 
	  // 		 [fileAttrs objectForKey: @"NSFileOwnerAccountID"],
	  // 		 [fileAttrs objectForKey: @"NSFileSize"]);
	  
	  [files setObject: fileAttrs forKey: file];
	  fileNumber += 1;
	  totalSize += [[fileAttrs objectForKey: @"NSFileSize"] longLongValue];
	  
	  // Not used, possibily will contain a checksum
	  [fileAttrs setObject: @"0" forKey: @"GSFileChecksum"];
	}
    }
  else
    {
      NSLog(@"Could not find the specified file!");
    }
  [bom setObject: files forKey:@"Files"];
  
  [sizes setObject: [NSNumber numberWithInt: fileNumber] forKey: @"GSFileNumber"];
  [sizes setObject: [NSNumber numberWithLongLong: totalSize] forKey: @"GSTotalSize"];  
  [bom setObject: sizes forKey:@"Sizes"];
  //  enumerator = [bom keyEnumerator];
  //  NSLog (@"BOM Format: %@", bomFormat);
  
  //  while ((key = [enumerator nextObject])) 
  //  {



  NSLog(@"Number of files: %i", fileNumber);
  NSLog(@"Total Size: %i", totalSize);

  // Write to file

  bomData = [NSData dataWithData: [NSPropertyListSerialization dataFromPropertyList: bom  
							       //format: NSPropertyListGNUstepBinaryFormat  
							       format: NSPropertyListXMLFormat_v1_0  
							       errorDescription: 0]];

  if ([bomData writeToFile: @"./Archive.gbom" atomically: YES])
      NSLog (@"Success");
  else
      NSLog (@"Failure");
  //  [bom writeToFile: @"/home/fsmunoz/Code/mkgbom/test.plist" atomically: YES];
  [pool release];
  return 0;
}

