/*
   Project: Gpkg

   Copyright (C) 2004 Frederico Munoz

   Author: Frederico S. Munoz

   Created: 2004-06-22 15:45:21 +0100 by fsmunoz

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

#include "Gpkg.h"

@implementation Gpkg
- (BOOL) handlesPackage: (NSString *)pkgPath;
{
  NSLog (@"Entered Gpkg handlesPackage");
  if ([[pkgPath pathExtension] isEqualToString: @"pkg"])
    {
      NSLog (@"Returning YES");
      packagePath = [NSString stringWithString: [pkgPath stringByAppendingPathComponent:@"Contents"]];
      [self _getAllInfo];
      return YES;

    }  
  return NO;
}
- (NSString *) packageName
{
  //  return @"Test";
  //  return [infoValues objectForKey: @"Title"];
  return  [descriptionPlist objectForKey:@"IFPkgDescriptionTitle"];
}
- (NSString *) packageVersion
{
  //  return @"2.3";
  //  return [infoValues objectForKey: @"Version"];
  return  [descriptionPlist objectForKey:@"IFPkgDescriptionVersion"];
  //  return  [infoPlist objectForKey:@"CFBundleShortVersionString"];
}
- (BOOL) isInstalled
{
  return NO;
}
- (NSString *) packageDescription
{
  //  return @"Application to test Installer.app";
  //  return [infoValues objectForKey: @"Description"];
  return welcome;

}
- (NSString *) packageAuthor
{
  return @"Frederico Muñoz";
}

- (NSString *) packageLocation
{

  //  return @"Testing...";
  //  return [infoValues objectForKey: @"DefaultLocation"];
  return  installLocation;
}
- (NSString *) packageLicence
{
  return license;
  //  return @"Testing...";
}
- (NSImage *) packageIcon
{

  //  NSImage *icon = [NSImage new];
  //  [icon  initWithContentsOfFile: @"/home/fsmunoz/Code/AClock-0.2.3.pkg/AClock.tiff"];

  return icon;


}
- (NSString *) packageSizes
{

  packageSizes = [NSString stringWithFormat: @"%d installed, %i compressed", 
			   [[[bom objectForKey:@"Sizes"] objectForKey:@"GSTotalSize"] intValue], 14];
  return packageSizes;
}
- (NSString *) packagePlatform
{
  return @"i386 GNU/Linux";
  //  return [infoValues objectForKey: @"Description"];
}

- (NSString *) packageContents
{

  return [[[bom objectForKey:@"Files"] allKeys]componentsJoinedByString:@"\n"];
}

- (BOOL) installPackage: (id) sender
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSLog (@"InstallPackage received");
  NSMutableDictionary *receipt = [NSMutableDictionary new];
  NSMutableDictionary *installedFiles = [NSMutableDictionary new];
  NSData *receiptData;
  NSString *destination = [[[NSHomeDirectory() stringByAppendingPathComponent:@"GNUstep"]
			     stringByAppendingPathComponent:@"Applications"]
			    //			    stringByAppendingPathComponent: appDirectoryName];
			    stringByAppendingPathComponent: @"123"];

  NSFileManager *manager = [NSFileManager defaultManager];
  /*    
  //NSString *appDir = [packageTempDir stringByAppendingPathComponent: appDirectoryName];
  NSString *appDir = [packageTempDir stringByAppendingPathComponent: @"123"];
  */
//  NSLog(@"Testing appdir: %@", appDir);
  NSLog (@"moo");
  
  [self _uncompressPackage];

  if ([manager changeCurrentDirectoryPath: packageTempDir] != NO)
    NSLog (@"Chdir OK");
  else
    NSLog (@"Chdir FAILED");

  NSEnumerator *enumerator = [[bom objectForKey: @"Files"] keyEnumerator];
  id key;
  while ((key = [enumerator nextObject])) 
    {
      //      NSLog (@"Verifying %@", [[bom objectForKey: @"Files"] objectForKey: key]);

      NSLog (@"Copying %@ to %@", [packageTempDir stringByAppendingPathComponent: key],
	     [installLocation stringByAppendingPathComponent: key]);
      
      
      //[manager copyPath:[appDir stringByAppendingPathComponent:file] toPath:destination handler:nil];	  
      if ([manager copyPath:[packageTempDir stringByAppendingPathComponent: key] toPath: [installLocation stringByAppendingPathComponent: key] handler: nil])
	{
	  //	  [installedFiles setObject: [[bom objectForKey: @"Files"] objectForKey: key] forKey: key];
	  [installedFiles setObject: [[bom objectForKey: @"Files"] objectForKey: key] forKey: [installLocation stringByAppendingPathComponent: key]];
	}
      else
	{
	  [installedFiles setObject: [[bom objectForKey: @"Files"] objectForKey: key] forKey: [installLocation stringByAppendingPathComponent: key]];
	  NSLog (@"Failed installing a file");
	}
    }
  
  [receipt setObject: installedFiles forKey:@"Files"];
  receiptData = [NSData dataWithData: [NSPropertyListSerialization dataFromPropertyList: bom  
								   //format: NSPropertyListGNUstepBinaryFormat 
								   format: NSPropertyListXMLFormat_v1_0  
								   errorDescription: 0]];

  /*
  if ([receipt writeToFile: @"/tmp/TI.bom" atomically: YES])
      NSLog (@"Success");
  */
  [self installReceipt: bom];
  exit (0);

  [pool release];
}
- (BOOL) installReceipt: (NSDictionary*) receipt;
{
  NSArray *paths;
  NSString *receiptsFolder = [[NSString alloc] init];
  NSString *tempArchive = [NSString new];
  NSString *tempBom = [NSString new];

  paths = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSSystemDomainMask, YES);
  receiptsFolder = [paths objectAtIndex: 0];
  NSLog (@"Receipts are in %@", receiptsFolder);

  tempArchive = [NSBundle pathForResource:@"Archive" 
			     ofType:@"pax.gz"
			     inDirectory: packageTempDir];
  tempBom = [NSBundle pathForResource:@"Archive" 
		      ofType:@"bom"
		      inDirectory: packageTempDir];
  
  NSLog (@"Archive to remove: %@", tempArchive);
  NSLog (@"BOM to remove: %@", tempBom);
  return YES;
}
- _getAllInfo
{
  
  NSFileManager *aFileManager;
  NSArray *allFiles;
  NSString *inputString = [NSString new];
  NSString *sizesFileContents = [NSString new];
  NSMutableDictionary *sizesValues = [NSMutableDictionary new];
  //  NSString *bomContents;
  int j;
  

  aFileManager = [NSFileManager defaultManager];

  //  bundlesPath =  [NSString stringWithString: @"./Gpkg.subproj"];
  //[bundlesPath initWithString: filename];
  //  appDir = [NSString new];
  allFiles = [aFileManager directoryContentsAtPath: packagePath];
  NSString *descriptionPlistPath = [NSBundle pathForResource:@"Description" 
					     ofType:@"plist"
					     inDirectory: packagePath];
  NSString *infoPlistPath = [NSBundle pathForResource:@"Info" 
				      ofType:@"plist"
				      inDirectory: packagePath];
  paxArchivePath = [NSBundle pathForResource:@"Archive" 
				       ofType:@"pax.gz"
				       inDirectory: packagePath];
  NSString *bomPath = [NSBundle pathForResource:@"Archive" 
				ofType:@"bom"
				inDirectory: packagePath];
  NSString *licensePath = [NSBundle pathForResource:@"License" 
				    ofType: nil
				    inDirectory: packagePath];
  NSString *readmePath = [NSBundle pathForResource:@"ReadMe" 
				   ofType: nil
				   inDirectory: packagePath];
  NSString *welcomePath = [NSBundle pathForResource:@"Welcome" 
				    ofType: nil
				    inDirectory: packagePath];
  
  license = [NSString stringWithContentsOfFile: licensePath];
  welcome = [NSString stringWithContentsOfFile: welcomePath];

  NSLog (@"Description: %@", descriptionPlistPath);  
  NSLog (@"Info: %@", infoPlistPath);
  NSLog (@"Archive: %@", paxArchivePath);  
  NSLog (@"BOM: %@", bomPath);  
  NSLog (@"License: %@", licensePath);  
  NSLog (@"Readme: %@", readmePath);  
  NSLog (@"Welcome: %@", welcomePath);  
  
  //  NSMutableDictionary *infoPlist = [NSMutableDictionary new];
  infoPlist = [NSPropertyListSerialization propertyListFromData: [[NSData dataWithContentsOfFile: infoPlistPath]retain]
					   mutabilityOption: NSPropertyListImmutable 
					   format:  0
					   errorDescription: 0];
  
  [infoPlist retain];

  descriptionPlist = [NSPropertyListSerialization propertyListFromData: [[NSData dataWithContentsOfFile: descriptionPlistPath]retain]
					   mutabilityOption: NSPropertyListImmutable 
					   format:  0
					   errorDescription: 0];
  
  [descriptionPlist retain];

  bom = [NSPropertyListSerialization propertyListFromData: [[NSData dataWithContentsOfFile: bomPath]retain]
					   mutabilityOption: NSPropertyListImmutable 
					   format:  0
					   errorDescription: 0];
  [bom retain];

  //  packageVersion = [infoPlist objectForKey:@"CFBundleShortVersionString"];
  //  exit(0);
  installLocation=[infoPlist objectForKey:@"IFPkgFlagDefaultLocation"];  
  [installLocation retain];
  [paxArchivePath retain];
  [packageTempDir retain];
  //  installerTempDir = [NSString stringWithString: [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSProcessInfo processInfo] processName]]];
  //  packageTempDir = [installerTempDir stringByAppendingPathComponent:  [descriptionPlist objectForKey:@"IFPkgDescriptionTitle"]];
  NSLog (@"Temp dir for package: %@", packageTempDir);
}
- (int) currentStep
{
  NSLog (@"Doing step");
  return 1;
}
- (int) totalSteps
{
  return totalSteps;
}
- _uncompressPackage
{

  NSLog(@"Hello uncompressPackage");
  NSArray *args;
  NSTask *task;
  NSData *data;
  NSString *lstr;
  NSString *gstr;
  NSString *lic;
  NSPipe *pipe = [NSPipe pipe];
  NSFileHandle *fileHandle;
  NSFileManager *manager = [NSFileManager defaultManager];
  
  NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSProcessInfo processInfo] processName]];
  
  NSLog (@"1");
  //packageTempDir is: TMP/Installer.app/
  //  packageTempDir = [NSString stringWithString: [[NSTemporaryDirectory() stringByAppendingPathComponent: [[NSProcessInfo processInfo] processName]] stringByAppendingPathComponent: appDirectoryName]];

  //  NSString *installerTempDir = [NSString stringWithString: [packageTempDir stringByDeletingLastPathComponent]];
  NSString *command;
  installerTempDir = [NSString stringWithString: [NSTemporaryDirectory() stringByAppendingPathComponent: [[NSProcessInfo processInfo] processName]]];
  packageTempDir = [installerTempDir stringByAppendingPathComponent:  [descriptionPlist objectForKey:@"IFPkgDescriptionTitle"]];

  NSLog (@"2");
  // Create the $TMP/Installer
  if (![manager fileExistsAtPath: installerTempDir])
    {
      NSLog (@"Created %@", installerTempDir);
      [manager createDirectoryAtPath: installerTempDir
	       attributes: [manager fileAttributesAtPath: NSTemporaryDirectory() traverseLink: NO]];
      //      [manager enforceMode: 0700  atPath: aString];
    }
  // Create the $TMP/Installer/SomePackage.app
  if (![manager fileExistsAtPath: packageTempDir])
    {
      NSLog (@"Created %@", packageTempDir);
      [manager createDirectoryAtPath: packageTempDir
	       attributes: [manager fileAttributesAtPath: installerTempDir traverseLink: NO]];
      //      [manager enforceMode: 0700  atPath: compressedPath];
    }
    
  //  NSLog (@"Copying %@ to %@", packageArchivePath, packageTempDir);
  NSLog (@"3");
  packageTempArchivePath = [packageTempDir stringByAppendingPathComponent: [paxArchivePath lastPathComponent]];
  if ([manager copyPath: paxArchivePath toPath: packageTempArchivePath  handler:nil])
    NSLog (@"Success!!!");
  else
    NSLog (@"Some weird error...");
  /*
  packageArchivePath = [packageTempDir stringByAppendingPathComponent: [packageArchivePath lastPathComponent]]; 
  if ([archiveFormat isEqualToString: @"TAR"])
    {
      command = [NSString stringWithString: @"tar"];
      args = [NSArray arrayWithObjects: @"-zxvf", packageArchivePath, nil];
    }
  if ([archiveFormat isEqualToString: @"PAX"])
    {
      command = [NSString stringWithString: @"pax"];
      args = [NSArray arrayWithObjects: @"-zrvf", packageArchivePath, nil];
    }
  //  appDir =  [compressedPath stringByAppendingPathComponent: [appDirPath lastPathComponent]];
  */
  command = [NSString stringWithString: @"pax"];
  args = [NSArray arrayWithObjects: @"-zrvf", paxArchivePath, nil];
  task = [NSTask new];
  [task setLaunchPath: command];
  [task setArguments: args];
  [task setStandardOutput: pipe];
  [task setCurrentDirectoryPath: packageTempDir];
  fileHandle = [pipe fileHandleForReading];
  [task launch];
  data = [fileHandle readDataToEndOfFile];
  [fileHandle closeFile];
  lstr = [[NSString alloc] initWithData: data
			   encoding: [NSString defaultCStringEncoding]];
  NSLog(@"This is lstr: %@", lstr);
  

}
- (BOOL) isRelocatable
{
 
  NSLog (@"Rel: %@",[infoPlist objectForKey: @"IFPkgFlagRelocatable"]);
  if ([infoPlist objectForKey: @"IFPkgFlagRelocatable"] != NO )
    return NO;
  else
    return YES;
}
- (BOOL) setPackageLocation: (NSString *) packageLocation
{
  /*
  if ([installLocation initWithString: packageLocation] != nil)
    return YES;
  else
    return NO;
  */
  ASSIGN (installLocation, packageLocation);
  return YES;
}
@end
