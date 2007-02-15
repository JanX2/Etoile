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

/*
 * The document window has a popup menu that allows the user to switch
 * between different panels. When something is selected in it, switchView:
 * is called.
 *
 * The available panels are: "Info", "Files", "Licence", "Progress"
 */
@interface MyDocument : NSDocument
{
  PackageManager* packageManager;

  // ----------- wherever ----------
  
  // a text field showing the currently selected target install location
  IBOutlet NSTextField *installLocation;
  // a button that allows to change the desired install location for the package
  IBOutlet NSButton *locationSelectButton;
  
  
  // ----------- Info Panel ------------- 
  IBOutlet NSImageView* packageIcon;
  IBOutlet NSTextField* packageName;
  IBOutlet NSTextField* packageStatus; // Installed / Not installed
  IBOutlet NSTextField* packageSizes;  // XXX: Size_s_?
  IBOutlet NSTextField* packagePlatforms;
  IBOutlet NSTextField* packageVersion;
  IBOutlet NSTextField* packageLocation;
  IBOutlet NSTextView* packageDescription;

  // ------------ Licence Panel --------------
  IBOutlet NSTextView* packageLicence;

  // ------------- Files Panel -------------
  IBOutlet NSTextView* packageFiles;

  // ------------- Progress Panel ---------------
  IBOutlet NSProgressIndicator *progressIndicator;

  
  // ------------- Unidentified fields -------------
  // XXX: Likely to be a NSPanel, but what is it good for?
  IBOutlet id progressPanel;
  
  // XXX: What's this?
  IBOutlet NSTextField *installStep;
  
  
  NSString *filename;

  
  // the view on which setContentView: is called when the panel switches
  IBOutlet id holderView;

  // the different panels themselves
  IBOutlet NSView* infoView;
  IBOutlet NSView* licenceView;
  IBOutlet NSView* filesView;
  IBOutlet NSView* progressView;

  // The popup button that needs to be used in order to select a panel
  IBOutlet id viewSelector;
}
- (BOOL) installPackage: (id) sender;
- (NSString *) chooseInstallationPath: (id) sender;
- (void) switchView:(id)sender;
@end
