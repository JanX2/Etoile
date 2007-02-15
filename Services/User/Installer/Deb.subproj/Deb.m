/*
   Project: Deb

   Copyright (C) 2004 Frederico Munoz

   Author: Frederico S. Munoz

   Created: 2004-06-22 16:32:08 +0100 by fsmunoz

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

#include "Deb.h"

@implementation Deb
- init
{
  if ((self = [super init]) != nil) {
      pkgName = [NSString new];
      pkgVersion = [NSString new];
      pkgName = [NSString new];
      pkgAuthor = [NSString new];
      pkgSizes = [NSString new];
  }
  
  return self;
}


- (BOOL) handlesPackage: (NSString *)pkgPath
{
  if ([[pkgPath pathExtension] isEqualToString: @"deb"])
    {
      packagePath = [NSString stringWithString: pkgPath];
      [self _getAllInfo];
      return YES;
    }  
  return NO;
}


- (NSImage *) packageIcon
{
  NSImage *icon = [NSImage new];
  [icon  initWithContentsOfFile: @"./Resources/Deb.tiff"];
  return icon;
}


- (NSString *) packageName
{
  //  NSLog (@"Entered Deb packageName %@", pkgName);
  //return @"My Package Name from Deb.m";
  return pkgName;
}


- (NSString *) packageVersion
{
  return pkgVersion;
}


- (NSString *) packageLocation
{
  return packagePath;
}


- (NSString *) packageLicence
{
  return pkgLicence;
}


- (NSString *) packageAuthor
{
  return pkgAuthor;
}


- (NSString *) packageSizes
{
  return pkgSizes;
}


- (NSString *) packagePlatform
{
  return pkgPlatform;
}


- (BOOL) isInstalled
{
  return isInstalled;
}


- (NSString *) packageDescription
{
  //  NSLog (@"Testing access of instance variable packagePath : %@", packagePath);
  //  return @"Application to test Installer.app Deb bundle";
  return pkgDescription;
}


- (NSString *) packageContents
{
  return pkgContents;
}


- (BOOL) installPackage: (id) sender
{
  return YES;
}


- _getAllInfo
{

  NSLog(@"_getAllInfo");

  NSArray *args;
  NSTask *task;
  NSData *data;
  NSString *lstr;
  NSString *gstr;
  NSString *lic;
  NSPipe *pipe = [NSPipe pipe];
  NSPipe *pipe2 = [NSPipe pipe];
  NSPipe *pipe3 = [NSPipe pipe];
  NSPipe *pipe4 = [NSPipe pipe];
  NSPipe *pipe5 = [NSPipe pipe];
  NSFileHandle *fileHandle;
  NSScanner *scanner;


  // PACKAGE CONTENT
  args = [NSArray arrayWithObjects: @"-c", packagePath, nil];
  task = [NSTask new];
  [task setLaunchPath: @"/usr/bin/dpkg"];
  [task setArguments: args];
  [task setStandardOutput: pipe];
  fileHandle = [pipe fileHandleForReading];
  [task launch];
  data = [fileHandle readDataToEndOfFile];
  [fileHandle closeFile];
  lstr = [[NSString alloc] initWithData: data
			   encoding: [NSString defaultCStringEncoding]];
  NSLog(@"This is lstr: %@", lstr);
  
  // GENERAL INFORMATION ABOUT THE PACKAGE

  args = [NSArray arrayWithObjects: @"-f", packagePath, nil];
  task = [NSTask new];
  [task setLaunchPath: @"/usr/bin/dpkg"];
  [task setArguments: args];
  [task setStandardOutput: pipe2];
  fileHandle = [pipe2 fileHandleForReading];
  [task launch];
  data = [fileHandle readDataToEndOfFile];
  
  gstr = [[NSString alloc] initWithData: data
			   encoding: [NSString defaultCStringEncoding]];
  //  NSLog(@"This is gstr: %@", gstr);

  //SCAN
  
  scanner = [NSScanner scannerWithString: gstr];
  
  //find package name
  
  if ([scanner scanUpToString: @"Package: " intoString: 0] == YES 
      || [scanner scanString: @"Package: " intoString: 0])
    {
      [scanner scanUpToString: @"\n" intoString: &pkgName];
    }
  if ([scanner scanUpToString: @"Version: " intoString: 0] == YES 
      || [scanner scanString: @"Version: " intoString: 0])
    {
      [scanner scanUpToString: @"\n" intoString: &pkgVersion];
    }
  if ([scanner scanUpToString: @"Architecture: " intoString: 0] == YES 
      || [scanner scanString:  @"Architecture: " intoString: 0])
    {
      [scanner scanString:  @"Architecture: " intoString: 0];
      [scanner scanUpToString: @"\n" intoString: &pkgPlatform];
    }
  if ([scanner scanUpToString: @"Installed-Size: " intoString: 0] == YES 
      || [scanner scanString:  @"Installed-Size: " intoString: 0])
    {
      [scanner scanString:  @"Installed-Size: " intoString: 0];
      [scanner scanUpToString: @"\n" intoString: &pkgSizes];
    }
    if ([scanner scanUpToString: @"Maintainer: " intoString: 0] == YES 
      || [scanner scanString:  @"Maintainer: " intoString: 0])
    {
      [scanner scanString:  @"Maintainer: " intoString: 0];
      [scanner scanUpToString: @"\n" intoString: &pkgAuthor];
    }

  if ([scanner scanUpToString: @"Description: " intoString: 0] == YES 
      || [scanner scanString:  @"Description: " intoString: 0])
    {
      [scanner scanString:  @"Description: " intoString: 0];
      [scanner scanUpToString: @".\n" intoString: &pkgDescription];
    }

  // LICENCE INFORMATION
  NSLog(@"Licence follows");
  args = [NSArray arrayWithObjects: @"--fsys-tarfile",packagePath,nil];
  task = [NSTask new];
  [task setLaunchPath: @"/usr/bin/dpkg"];
  [task setArguments: args];
  [task setStandardOutput: pipe3];
  //fileHandle = [pipe3 fileHandleForReading];
  [task launch];

  NSMutableString *licPathPref = [NSMutableString new];
  NSMutableString *copyrightPath = [NSMutableString new];

  [copyrightPath initWithString: pkgName];
  [licPathPref initWithString: @"./usr/share/doc/"];
  [copyrightPath stringByAppendingPathComponent: @"copyright"];
  
  [copyrightPath setString: [licPathPref stringByAppendingPathComponent:copyrightPath]];

  [copyrightPath setString: [copyrightPath stringByAppendingPathComponent: @"copyright"]];
  //    copyrightPath = licPathPref;


  NSLog (@"Copyright file: %@",copyrightPath);
  NSLog (@"Copyright file2: %@",licPathPref);
  args = [NSArray arrayWithObjects: @"xOf", @"-", copyrightPath, nil];
  task = [NSTask new];
  [task setLaunchPath: @"/bin/tar"];
  [task setArguments: args];
  [task setStandardInput: pipe3];
  [task setStandardOutput: pipe4];
  fileHandle = [pipe4 fileHandleForReading];
  [task launch];

  data = [fileHandle readDataToEndOfFile];
  
  lic = [[NSString alloc] initWithData: data
  			   encoding: [NSString defaultCStringEncoding]];

  pkgLicence = [NSString stringWithString: lic];


  // Package Sizes

  // We already have Installed-Size in pkgSizes
  
  NSString *fileSize;
  NSNumber *fsize;
  NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath: packagePath 
							  traverseLink:YES];

  fsize = [fattrs objectForKey:NSFileSize];
  fileSize = [NSString stringWithFormat: @"%@ kb installed, %1.0f kb packaged",pkgSizes,[fsize floatValue] / 1024];
  
  pkgSizes = fileSize;
  NSLog (@"File Sizes: %@", fileSize);

  //NSLog(@"%@",lic);

  // Installation Status


  NSString *installedVersion = [NSString new];

  NSString *aptPolicy;

  args = [NSArray arrayWithObjects: @"policy", pkgName, nil];
  task = [NSTask new];
  [task setLaunchPath: @"/usr/bin/apt-cache"];
  [task setArguments: args];
  [task setStandardOutput: pipe5];
  fileHandle = [pipe5 fileHandleForReading];
  [task launch];
  data = [fileHandle readDataToEndOfFile];
  
  aptPolicy = [[NSString alloc] initWithData: data
				encoding: [NSString defaultCStringEncoding]];
  
  scanner = [NSScanner scannerWithString: aptPolicy];
  
  //find package name

  
  if ([scanner scanUpToString: @": " intoString: 0] == YES)
    {
      [scanner scanString: @": " intoString: 0];
      [scanner scanUpToString: @"\n" intoString: &installedVersion];
    }

  NSLog (@"%@", aptPolicy);
  NSLog (@"Installed Version:**%@**", installedVersion);
  

  if ( [installedVersion hasPrefix: @"("] == NO 
       && [installedVersion isEqualToString: @""] == NO
       )
						    
    {
      isInstalled = YES;
    }
  else
    {
      isInstalled = NO;
      NSLog (@"ITS NOT INSTALLED");
    }
    
  
  NSLog (@"PACKAGE NAME IN DEB.M: %@", pkgName);
  NSLog (@"Package Installed-Size %@", pkgSizes);
  pkgContents = [NSString stringWithString: lstr];
  NSLog(@"%@", [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]]);
  
  
  //  [pkgName retain];  
  //  [pkgName initWithString: @"cfingerd"];
  //  [pkgVersion initWithString: @"2.3.1"];
  
}
-(int) numberOfSteps
{
  return 42;
}
- currentStep
{
  NSLog (@"Next step :)");
}
@end
