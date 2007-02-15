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
#include "MyDocument.h"

/**
 * Manages the document window of a package.
 * 
 */ 
@implementation MyDocument


- (void)windowControllerDidLoadNib: (NSWindowController *) aController
{
  [super windowControllerDidLoadNib: aController];    
  [[NSNotificationCenter defaultCenter] addObserver: self
					selector: @selector(updateProgressWithFile:)
					name: @"ProgressShouldUpdate"
					object: nil];  

  //NSLog (@"windowControllerDidLoadNib: %@",[self hash]);
  [holderView setContentView: [[infoView contentView] retain]];  
  [packageName setStringValue: [packageManager packageName]];
  [packageVersion setStringValue: [packageManager packageVersion]];
  [packageDescription setString: [packageManager packageDescription]];
  [packageFiles setString: [packageManager packageContents]];
  [packageSizes setStringValue: [packageManager packageSizes]];
  [packagePlatforms setStringValue: [packageManager packagePlatform]];
  [packageIcon setImage: [packageManager packageIcon]];
  [packageLicence setString: [packageManager packageLicence]];
  [packageLocation setStringValue: [packageManager packageLocation]];
  
  if ([packageManager isInstalled] == YES)
    [packageStatus setStringValue: @"Installed"];
  else
    [packageStatus setStringValue: @"Not installed"];
   [progressIndicator setDoubleValue: 0.0];

  NSLog(@"End of WCDLN");


}
- (BOOL) readFromFile: (NSString *) fileName ofType: (NSString *) fileType
{

  filename = [NSString stringWithString: fileName];
  packageManager = [[PackageManager alloc]initWithFile: filename 
					  withExtension: [self fileType]];
  //  NSLog(@"");
  if (packageManager == nil)
    {
      NSLog (@"****** PM NOT INITIATED IN AWAKE******");
      // return NO;
    }
  else
    {
            NSLog (@"Returning from readFile: %@ Type: %@", fileName,fileType);
	    return YES;
    }
  //  return YES;
}

- (NSString *) windowNibName
{
  NSLog (@"windowNibName");
  return @"Package";
}

- (BOOL) installPackage: (id) sender
{

   NSLog (@"installPackage of package: %@", [packageName stringValue]);
   [installLocation setStringValue: [packageManager packageLocation]];

   if ([packageManager isRelocatable] == YES)
     [locationSelectButton setEnabled: YES];
   else
     [locationSelectButton setEnabled: NO];

   //[installLocation setStringValue: @"123"];
   //   NSLog (@"Install Location: %@", [installLocation stringValue]);

   //   [progressIndicator setMaxValue: 100.0];
   [progressIndicator setMinValue: 0.0];  
   [progressIndicator setMaxValue: [packageManager totalSteps]];
   NSLog(@"%@",progressIndicator);
   NSLog (@"Max: %g",[progressIndicator maxValue]);
   //   [progressIndicator setDoubleValue: 0.0];
   if (progressIndicator != nil)
     {
       NSLog(@"********min: %g max: %g present: %g",[progressIndicator minValue],[progressIndicator maxValue],[progressIndicator doubleValue]);
     }


   [viewSelector selectItemWithTitle:@"Progress"];
   [self switchView: viewSelector];
   //   [progressPanel makeKeyAndOrderFront: sender];

   
   [NSThread detachNewThreadSelector:@selector (installPackage:)
	     toTarget:packageManager
	     withObject:self];
   
   //    [packageManager installPackage:self];

	NSLog (@"totalSteps: %i", [packageManager totalSteps]);
   /*      
   NSLog(@"min: %g max: %g present: %g",[progressIndicator minValue],[progressIndicator maxValue],[progressIndicator doubleValue]);
   */
}

//- updateProgress: (int) step withName: (NSString *) name;
- updateProgressWithFile: (NSString *) name;
{
  //  sleep (1);
  //  NSString *name = [NSString stringWithString: [not object]];

  [progressIndicator incrementBy: 1.0];
  //[progressIndicator setNeedsDisplay: YES];
  //  [progressPanel flushWindow];
  //  [progressPanel display];

  //  [progressIndicator display];
  //  [installStep setStringValue: [name lastPathComponent]];

  NSLog (@"Beep...");
  NSLog(@"File: %@; min: %g max: %g present: %g", name , [progressIndicator minValue],[progressIndicator maxValue],[progressIndicator doubleValue]);
  
}
 - (NSString *) chooseInstallationPath: (id) sender
 {
   //   NSLog (@"Choos install path");
   NSOpenPanel *myOP = [[NSOpenPanel alloc] init];

   [myOP setCanChooseFiles: NO];
   [myOP setCanChooseDirectories: YES];

   //   [progressPanel display];

   if ( [myOP runModalForDirectory: [installLocation stringValue] file: nil types: nil] == NSOKButton )
     
     {
       //       [installLocation setStringValue: [myOP filename]];
       [packageManager setPackageLocation: [myOP filename]];
       [installLocation setStringValue: [packageManager packageLocation]];
     }
   else
     {
     NSLog (@"Cancel");
     }
   //   NSLog (@"FIleName: %@", [myOP filename]);

   [myOP release];
   [progressPanel makeKeyAndOrderFront: sender];
   return @"123";
}
- (void) switchView:(id)sender
{
  NSLog (@"Switching");
  if ( [[[sender selectedItem]title] isEqualToString: @"Info"] )
    {
      [holderView setContentView: [[infoView contentView] retain]];
      NSLog (@"Retain count: %i",[[infoView contentView] retainCount]);
    }
  if ( [[[sender selectedItem]title] isEqualToString: @"Licence"] )
    {
      [holderView setContentView: [[licenceView contentView]retain]];      
    }
  if ( [[[sender selectedItem]title] isEqualToString: @"Files"] )
    {
      [holderView setContentView: [[filesView contentView]retain]];      
    }
  if ( [[[sender selectedItem]title] isEqualToString: @"Progress"] )
    {
      [holderView setContentView: [[progressView contentView]retain]];      
    }
  /*
  else if ( [[[sender selectedItem]title] isEqualToString: @"List"] )
    {
      [holderView setContentView: listBox];
    }
  else if ( [[[sender selectedItem]title] isEqualToString: @"Prefs"] )
    {
      NSLog(@"Prefs: %@",[prefsBox contentView]);

      if (!prefsView) {
	NSLog (@"beep");
	prefsView = [NSView new];
	prefsView = [[prefsBox contentView] retain];
	[prefsView removeFromSuperview];
	[prefsBox setContentView: NULL];
	[prefsBox release];
	prefsBox = nil;
	[packageName setStringValue: @"w00t!"];
      }
      
      [holderView setContentView: prefsView];
    }
  */
}
@end
