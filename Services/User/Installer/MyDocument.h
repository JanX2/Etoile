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
//#include "MyWindowController.h"

@interface MyDocument : NSDocument
{
  id packageBundle;
  id packageName;
  id packageStatus;
  id packageSizes;
  id packagePlatforms;
  id packageVersion;
  id packageLocation;
  id packageDescription;
  id packageLicence;
  id packageFiles;
  id packageIcon;
  id packageManager;
  id _delegate;
  id progressPanel;
  //  id progressIndicator;
  IBOutlet NSProgressIndicator *progressIndicator;
  IBOutlet NSTextField *installStep;
  IBOutlet NSTextField *installLocation;
  IBOutlet NSButton *locationSelectButton;
  //  NSString *test;
  NSString *filename;
  //  MyWindowController *windowController;
}
- (BOOL) installPackage: (id) sender;
- (NSString *) chooseInstallationPath: (id) sender;
@end
