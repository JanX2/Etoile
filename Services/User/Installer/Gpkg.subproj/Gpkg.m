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

#import "Gpkg.h"

@interface Gpkg (Private)

- (BOOL) atomicallyCopyPath: (NSString *) sourcePath toPath: (NSString *) destinationPath ofType: (NSString *)fileType  withAttributes: (NSDictionary *) attributes;
- getAllInfo;
- uncompressPackage;

@end

@implementation Gpkg (Private)
- uncompressPackage
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

- getAllInfo
{
  
  NSFileManager *aFileManager;
  NSArray *allFiles;
  NSString *inputString = [NSString new];
  NSString *sizesFileContents = [NSString new];
  NSMutableDictionary *sizesValues = [NSMutableDictionary new];
  //  NSString *contentsPath = [[NSString alloc]initWithString: packagePath];
  NSString *contentsPath = [NSString stringWithString: [packagePath stringByAppendingPathComponent:@"Contents"]];
  //  NSString *bomContents;
  int j;
  
  //  [contentsPath setStringValue: [packagePa
  NSLog (@"Contents at: %@",contentsPath);


  aFileManager = [NSFileManager defaultManager];

  //  bundlesPath =  [NSString stringWithString: @"./Gpkg.subproj"];
  //[bundlesPath initWithString: filename];
  //  appDir = [NSString new];

  
  allFiles = [aFileManager directoryContentsAtPath: packagePath];
  NSString *descriptionPlistPath = [NSBundle pathForResource:@"Description" 
					     ofType:@"plist"
					     inDirectory: contentsPath];
  NSString *infoPlistPath = [NSBundle pathForResource:@"Info" 
				      ofType:@"plist"
				      inDirectory: contentsPath];
  paxArchivePath = [NSBundle pathForResource:@"Archive" 
				       ofType:@"pax.gz"
				       inDirectory: contentsPath];
  NSString *bomPath = [NSBundle pathForResource:@"Archive" 
				ofType:@"bom"
				inDirectory: contentsPath];
  NSString *licensePath = [NSBundle pathForResource:@"License" 
				    ofType: nil
				    inDirectory: contentsPath];
  NSString *readmePath = [NSBundle pathForResource:@"ReadMe" 
				   ofType: nil
				   inDirectory: contentsPath];
  NSString *welcomePath = [NSBundle pathForResource:@"Welcome" 
				    ofType: nil
				    inDirectory: contentsPath];
  
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

-(BOOL) atomicallyCopyPath: (NSString *) sourcePath 
		    toPath: (NSString *) destinationPath 
		    ofType: (NSString *)fileType 
	    withAttributes: (NSDictionary *) attributes 
{
  
  NSFileManager *manager = [NSFileManager defaultManager];
  
  if ([fileType isEqualToString: NSFileTypeDirectory] == NO)
    {
      // Processing regular file
      NSLog (@"Processing file %@", sourcePath );
      
      if ([manager copyPath: sourcePath toPath: destinationPath handler: nil] != NO)
	{
	  return YES;
	}
      else
	{
	  NSLog (@"Failed installing a file %@", sourcePath);
	  return NO;
	}
    } //end File processing
  else
    {
      //Processing Directories
      //	  NSLog (@"Processing dir %@", key);
      NSLog (@"Processing dir %@", sourcePath);
      
      if ([manager createDirectoryAtPath: destinationPath
		   attributes: attributes] != NO)
	{
	  return YES;
	}
      else
	{
	  NSLog (@"Failed creating a directory %@", destinationPath);
	  return NO;
	} 
      
    } //end Dir processing
} // end while 

@end

@implementation Gpkg
- int 
{
  [super init];
  //  totalSteps = [NSString new];
  return self;
}




- (BOOL) handlesPackage: (NSString *)pkgPath;
{
  NSLog (@"Entered Gpkg handlesPackage");
  if ([[pkgPath pathExtension] isEqualToString: @"pkg"])
    {
      NSLog (@"Returning YES");
      // packagePath = [NSString stringWithString: [pkgPath stringByAppendingPathComponent:@"Contents"]];
      packagePath = [NSString stringWithString: pkgPath];
      [packagePath retain];
      [self getAllInfo];
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
  NSArray *paths;
  BOOL isDir;
  //  NSString *receiptsFolder;
  NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: packagePath];
  NSFileManager *manager = [NSFileManager defaultManager];

  id key;
  
  paths = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSUserDomainMask, YES);
  
  //    NSString  *receiptsFolder = [[NSString alloc] initWithString: [[[paths objectAtIndex: 0] stringByAppendingPathComponent:@"Receipts"] stringByAppendingPathComponent: [packagePath lastPathComponent]]];  

  if (([manager fileExistsAtPath: [[[paths objectAtIndex: 0] stringByAppendingPathComponent:@"Receipts"] stringByAppendingPathComponent: [packagePath lastPathComponent]] isDirectory: &isDir] && isDir )!= NO)
    {
      NSLog (@"File exists");
    }
  else
    {
      NSLog (@"File doesn't exist");
    }
  //  NSString *receiptsFolder = [NSString stringWithString: @"ADB"];  
  
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

  packageSizes = [NSString stringWithFormat: @"%d installed, %i packaged", 
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
  NSMutableDictionary *receiptBom = [NSMutableDictionary new];
  NSMutableDictionary *installedFiles = [NSMutableDictionary new];
  NSMutableArray *newFileOrder = [NSMutableArray new];
  NSArray *fileOrder = [NSArray new];
  NSData *receiptData;
  NSString *destination = [[[NSHomeDirectory() stringByAppendingPathComponent:@"GNUstep"]
			     stringByAppendingPathComponent:@"Applications"]
			    //			    stringByAppendingPathComponent: appDirectoryName];
			    stringByAppendingPathComponent: @"123"];

  //  NSLog (@"Install Location: %i",[installLocation retainCount]);
  [self preInstall];
  NSFileManager *manager = [NSFileManager defaultManager];
  /*    
  //NSString *appDir = [packageTempDir stringByAppendingPathComponent: appDirectoryName];
  NSString *appDir = [packageTempDir stringByAppendingPathComponent: @"123"];
  */
//  NSLog(@"Testing appdir: %@", appDir);
  NSLog (@"moo");
  
  [self uncompressPackage];

  if ([manager changeCurrentDirectoryPath: packageTempDir] != NO)
    NSLog (@"Chdir OK");
  else
    NSLog (@"Chdir FAILED");

  //NSEnumerator *enumerator = [[bom objectForKey: @"Files"] keyEnumerator];
  //  fileOrder = [bom objectForKey: @"Order"];
  //NSLog (@"Order: %@",[fileOrder description]);
  NSEnumerator *enumerator = [[bom objectForKey: @"Order"] objectEnumerator];
  id key;
  while (key = [enumerator nextObject]) 
    {
      if ([self atomicallyCopyPath: [packageTempDir stringByAppendingPathComponent: key] 
		toPath: [installLocation stringByAppendingPathComponent: key]
		ofType: [[[bom objectForKey: @"Files"] objectForKey: key] valueForKey:@"NSFileType"]
		withAttributes: [bom objectForKey: key]] != NO)
	{
	  // Add copied file to the receipt bom
	  [installedFiles setObject: [[bom objectForKey: @"Files"] objectForKey: key] 
			  forKey: [installLocation stringByAppendingPathComponent: key]];	  
	  // Update progress indicator
	  [newFileOrder addObject: key];
	  [sender performSelectorOnMainThread: @selector(updateProgressWithFile:)
		  withObject: nil waitUntilDone: YES];
	}
      else
	{
	  NSLog (@"Failed installing a file %@", [installLocation stringByAppendingPathComponent: key]);	      
	}
    }
  
  [receiptBom setObject: installedFiles forKey:@"Files"];
  [receiptBom setObject: newFileOrder forKey:@"Order"];

  receiptData = [NSData dataWithData: [NSPropertyListSerialization dataFromPropertyList: receiptBom  
								   //format: NSPropertyListGNUstepBinaryFormat 
								   format: NSPropertyListXMLFormat_v1_0  
								   errorDescription: 0]];
  
  if ([receiptData writeToFile: @"/tmp/TI.bom" atomically: YES])
    NSLog (@"Success");
  
  [self installReceipt: receiptData];
  [self postInstall];
  exit (0);
  
  [pool release];
}

- (BOOL) installReceipt: (NSData *) receiptData;
{
  NSArray *paths;
  NSString *receiptsFolder = [NSString new];
  NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: packagePath];
  NSFileManager *manager = [NSFileManager defaultManager];
  id key;

  paths = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSUserDomainMask, YES);
  receiptsFolder = [[paths objectAtIndex: 0] stringByAppendingPathComponent:@"Receipts"];

  NSLog (@"Receipts are in %@", receiptsFolder);
    
  // Create the package top directory for the receipt

  if ([manager createDirectoryAtPath: [receiptsFolder stringByAppendingPathComponent: [packagePath lastPathComponent]]
	       attributes: nil] != NO)
    {
      NSLog (@"Created top receipt dir");
    }
  else
    {
      NSLog (@"Failed to create top receipt dir");
    }
  
  while (key = [dirEnum nextObject]) 
    {
      if (([[key lastPathComponent]isEqualToString: @"Archive.pax.gz"] 
	   ||[[key lastPathComponent]isEqualToString: @"Archive.bom"]) == NO)
	{ 
	  if ([self atomicallyCopyPath: [packagePath stringByAppendingPathComponent: key]
		    toPath: [[receiptsFolder stringByAppendingPathComponent: [packagePath lastPathComponent]] 
			      stringByAppendingPathComponent: key]
		    ofType: [[manager fileAttributesAtPath: [packagePath stringByAppendingPathComponent: key] traverseLink: NO] valueForKey: NSFileType]
		    withAttributes: [bom objectForKey: key]] != NO)
	    {
	      NSLog (@"Copied to receipt %@", key);
	    }
	  else
	    {
	      NSLog (@"Error in copying file to receipt: %@", key);
	    }
	}
      else
	{
	  if ([[key lastPathComponent]isEqualToString: @"Archive.bom"] != NO)
	    {
	      NSLog (@"Copying the new BOM");
	      if ([receiptData writeToFile:  [[receiptsFolder stringByAppendingPathComponent: [packagePath lastPathComponent]]stringByAppendingPathComponent: key]
			       atomically: YES])
		{
		  NSLog (@"Created new BOM!");
		}
	      else
		{
		  NSLog (@"Failed to create new BOM");
		}
	    }
	  else
	    {
	      NSLog (@"Skipping archive or BOM in the receipt");
	      
	    }
	}
    }	  
  
      /*
      if ([manager copyPath:[packagePath stringByAppendingPathComponent: key] toPath: [[receiptsFolder stringByAppendingPathComponent: [packagePath lastPathComponent]] stringByAppendingPathComponent: key] handler: nil] != NO)
	{
	  NSLog (@"Copying receipt %@", key);
	}
      else
	{
	  NSLog (@"Copying receipt ERRORfrom %@ to %@", [packagePath stringByAppendingPathComponent: key], [receiptsFolder stringByAppendingPathComponent: [packagePath lastPathComponent]]);
	}
      */

  return YES;
}

  - (BOOL) preInstall
{

    NSLog (@"preInstall: %@ , %@", packagePath, installLocation);

  return YES;
}
- (BOOL) postInstall
{
  //  NSLog (@"*** postInstall: %@, %@", packagePath, [self packageLocation]);
  return YES;
}


- (int) currentStep
{
  NSLog (@"Doing step");
  return 1;
}

- (int) totalSteps
{
  totalSteps = [[bom objectForKey: @"Files"] count];
  return totalSteps;
  //  return 10;
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
