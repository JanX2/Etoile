/** <title>PKPreferencesController</title>

	PKPreferencesController.m

	<abstract>Preferences window controller class</abstract>

	Copyright (C) 2006 Yen-Ju Chen
	Copyright (C) 2004 Quentin Mathe
                       Uli Kusterer

	Author:  Yen-Ju Chen <yjchenx gmail>
	Author:  Quentin Mathe <qmathe@club-internet.fr>
                 Uli Kusterer
        Date:  February 2005

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <AppKit/AppKit.h>
#import <PaneKit/PKPreferencesController.h>
#import <PaneKit/PKPreferencePaneRegistry.h>
#import "GNUstep.h"

/** <p>PKPreferencesController Description</p> */
@implementation PKPreferencesController

static PKPreferencesController	*sharedInstance = nil;

/** <p>Factory method which returns a singleton instance.</p> */
+ (PKPreferencesController *) sharedPreferencesController
{
  if (sharedInstance == nil) {
    sharedInstance = [[PKPreferencesController alloc] init];
  }
  return sharedInstance;
}

- (id) init
{
  self = [super init];
  ASSIGN(registry, [PKPreferencePaneRegistry sharedRegistry]);
  [(PKPreferencePaneRegistry *)registry loadAllPlugins];
  sharedInstance = self;
  return self;
}

/* Initialize stuff that can't be set in the nib/gorm file. */
- (void) awakeFromNib
{
  if ([owner isKindOfClass: [NSWindow class]])
  {
    /* Let the system keep track of where it belongs */
    [owner setFrameAutosaveName: @"PreferencesMainWindow"];
    [owner setFrameUsingName: @"PreferencesMainWindow"];
  }

  [super awakeFromNib];
}

@end
