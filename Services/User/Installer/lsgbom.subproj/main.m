/*
   Project: lsgbom

   Copyright (C) 2005 Free Software Foundation

   Author: Frederico Muñoz,,,

   Created: 2005-03-06 01:22:35 +0000 by fsmunoz

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

#include <Foundation/Foundation.h>

int
main(int argc, const char *argv[])
{
  id pool = [[NSAutoreleasePool alloc] init];


  NSMutableDictionary *bom = [NSMutableDictionary new];
  NSData *bomData;
  NSEnumerator *enumerator;
  id key;
  NSArray *args = [[NSProcessInfo processInfo]arguments];

  // NEW FOR TESTING ONLY
  //  NSFileManager *manager = [NSFileManager defaultManager];
  //  NSString *appDir = @"/home/fsmunoz/Code/mkgbom/test.gbom";
  NSString *appDir = [NSString stringWithString : [args objectAtIndex: 1]];
  NSLog (@"Appdir: %@", appDir);
  //  exit(0);
  //  NSString bomFormat =   [NSPropertyListFormat new];//[NSString new];

  NSPropertyListFormat bomFormat;
  bomData = [NSData dataWithContentsOfFile: appDir];
  bom = [NSPropertyListSerialization propertyListFromData: bomData
				     mutabilityOption: NSPropertyListImmutable 
				     format:  &bomFormat
				     errorDescription: 0];
  
  enumerator = [[bom objectForKey: @"Files"] keyEnumerator];
  //  NSLog (@"BOM Format: %@", bomFormat);
  
  while ((key = [enumerator nextObject])) 
    {
      NSLog (@"Analysing %@ : Owner: %@   Checksum: %@", key, 
	     [[[bom objectForKey:@"Files"]objectForKey: key] fileOwnerAccountName],
	     [[[bom objectForKey:@"Files"]objectForKey: key] objectForKey:@"GSFileChecksum"]);
      //NSLog (@"Key %@  Value %@", key ,[bom objectForKey: key]); 
      /*
      if ([manager copyPath:[packageTempDir stringByAppendingPathComponent: key] toPath: [installLocation stringByAppendingPathComponent: key] handler: nil] == NO)
	{
	  NSLog (@"Failed installing a file %@", [installLocation stringByAppendingPathComponent: key]);
	}
      else
	{
	  NSLog (@"Success in installing a file %@", [installLocation stringByAppendingPathComponent: key]);
	}
      */
    }
  
  [pool release];

  return 0;
}

