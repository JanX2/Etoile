/*
   Project: Installer

   Copyright (C) 2004 Frederico Munoz

   Author: Frederico S. Munoz

   Created: 2004-06-22 15:45:55 +0100 by fsmunoz

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

#include <AppKit/AppKit.h>
#include "PackageManager.h"

@implementation PackageManager
- (id)initWithFile: filename withExtension: docType;

//- init
{
  [super init];
  NSLog (@"PM init");
  // NEW METHOD, taken from Preferences.app by Jeff 

  NSMutableArray		*dirList = [[NSMutableArray alloc] initWithCapacity: 10];
  NSArray				*temp;
  NSMutableArray		*modified = [[NSMutableArray alloc] initWithCapacity: 10];
  NSEnumerator		*counter;
  id					obj;
  

  //    First, load and init all bundles in the app resource path

  NSLog (@"Loading local bundles...");
  
  counter = [[self bundlesWithExtension: @"installer" inPath: [[NSBundle mainBundle] resourcePath]] objectEnumerator];
  
  while ((obj = [counter nextObject])) {
    NSLog (@"Found local bundle %@", obj);
    NSEnumerator *enum2 = [[self bundlesWithExtension: @"installer" inPath: obj] objectEnumerator];
    NSString *str;
    
    //    while ((str = [enum2 nextObject])) {
    //       [self loadBundleWithPath: obj];
      
      Class principalClass;
      NSLog (@"Trying %@", obj);
      NSBundle *aBundle;
      //      NSString *path;
      //NSLog (@"Found bundle %@ in dir %@", aString, bundlesPath);
      //      path = [NSString stringWithFormat: @"%@/%@",
      //		       bundlesPath,
      //		       aString];
      
      aBundle = [NSBundle bundleWithPath: obj];
      
      if (aBundle)
	{
	  //  NSLog (@"Bundle %@ loaded and being instanciated", aString);
	  Class aClass;
	  aClass = [aBundle principalClass];
	  //	      _bundle = aClass;
	  pm = [aClass new];
	  if ([pm handlesPackage: filename] == YES)
	    {
	      //  NSLog (@"Bundle %@ claimed the package", aString);
	      return pm;
	    }
	  else
	    {
	      //     return nil;
	    }
	}
      
      //      }  
    
  }
  
  /*
    Then do the same for external bundles
  */
  NSLog (@"Loading foreign bundles...");
  // Get the library dirs and add our path to all of its entries
  temp = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSAllDomainsMask, YES);
  
  counter = [temp objectEnumerator];
  while ((obj = [counter nextObject])) {
    [modified addObject: [obj stringByAppendingPathComponent: @"Installer"]];
  }
  [dirList addObjectsFromArray: modified];
  
  // Okay, now go through dirList loading all of the bundles in each dir
  counter = [dirList objectEnumerator];
  while ((obj = [counter nextObject])) {
    NSEnumerator	*enum2 = [[self bundlesWithExtension: @"installer" inPath: obj] objectEnumerator];
    NSString		*str;
    
    while ((str = [enum2 nextObject])) {
      //      [self loadBundleWithPath: str];
      
      Class principalClass;
      NSLog (@"Trying %@", str);
      NSBundle *aBundle;
      //      NSString *path;
      //NSLog (@"Found bundle %@ in dir %@", aString, bundlesPath);
      //      path = [NSString stringWithFormat: @"%@/%@",
      //		       bundlesPath,
      //		       aString];
      
      aBundle = [NSBundle bundleWithPath: str];
      
      if (aBundle)
	{
	  //  NSLog (@"Bundle %@ loaded and being instanciated", aString);
	  Class aClass;
	  aClass = [aBundle principalClass];
	  //	      _bundle = aClass;
	  pm = [aClass new];
	  if ([pm handlesPackage: filename] == YES)
	    {
	      //  NSLog (@"Bundle %@ claimed the package", aString);
	      return pm;
	    }
	  else
	    {
	      //     return nil;
	    }
	}
      
    }
  }
}

- (NSArray *) bundlesWithExtension: (NSString *) extension inPath: (NSString *) path
{
  NSMutableArray  *bundleList = [[NSMutableArray alloc] initWithCapacity: 10];
  NSEnumerator    *enumerator;
  NSFileManager   *fm = [NSFileManager defaultManager];
  NSString                *dir;
  BOOL                    isDir;

  // ensure path exists, and is a directory
  if (![fm fileExistsAtPath: path isDirectory: &isDir])
    return nil;

  if (!isDir)
    return nil;

  // scan for bundles matching the extension in the dir
  enumerator = [[fm directoryContentsAtPath: path] objectEnumerator];
  while ((dir = [enumerator nextObject])) {
    if ([[dir pathExtension] isEqualToString: extension])
      [bundleList addObject: [path stringByAppendingPathComponent: dir]];
  }
  return bundleList;
}

@end
