/** <title>PKPreferencePaneRegistry</title>

	PKPreferencePaneRegistry.m
 
	<abstract>Prefeference pane manager class used to register new preference panes and 
    obtain already registered preference panes</abstract>
 
	Copyright (C) 2006 Yen-Ju Chen
	Copyright (C) 2004 Uli Kusterer
 
	Author:  Yen-Ju Chen
	Author:  Uli Kusterer
             Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2004
 
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

#ifdef HAVE_UKTEST
#import <UnitKit/UnitKit.h>
#endif

#import <PaneKit/PKPreferencePane.h>
#import <PaneKit/PKPreferencePaneRegistry.h>
#import <PaneKit/CocoaCompatibility.h>

static PKPreferencePaneRegistry *sharedPrefPanesRegistry;

/** <p>PKPrefPanesRegistry Description</p> */
@implementation PKPreferencePaneRegistry

/** <p>Returns PKPrefPanesRegistry shared instance (singleton).</p> */
+ (id) sharedRegistry
{	    
  if (sharedPrefPanesRegistry == nil) {
    sharedPrefPanesRegistry = [[PKPreferencePaneRegistry alloc] init];
  }
  return sharedPrefPanesRegistry;
}

- (id) init
{
  self = [super init];
  [self setInstantiate: NO];
  return self;
}

/** <p>Locates and loads <em>preference pane</em> bundles.</p>
    <p>Normally you only need to call this method to load a preference pane.</p> */
- (void) loadAllPlugins
{
  [self loadPluginsOfType: @"prefPane"];
}

- (NSMutableDictionary *) loadPluginForPath: (NSString *)path
{
  NSMutableDictionary *info = [super loadPluginForPath: path];
	
  /* Plugin key pieces haven't been loaded, we give up */
  if (info == nil)
    return nil;
    
  NSString *type = [[info objectForKey: @"path"] pathExtension];
  NSBundle *bundle = [NSBundle bundleWithPath: path];
  id name;
  id iconFileName;
	
  /* Retrieve pane specific informations we need to display the preference 
     pane in presentation list, without loading the related nib file and the
     whole plugin/pane code. */
  if ([type isEqualToString: @"prefPane"]) /* System Preferences pane. */
  {
    name = [[bundle infoDictionary] objectForKey: @"NSPrefPaneIconLabel"];
    if (name != nil && [name isEqual: [NSNull null]] == NO && 
       [name length] != 0) 
    {
      [info setObject: name forKey: @"name"];
    }
        
    iconFileName = [[bundle infoDictionary] objectForKey: @"NSPrefPaneIconFile"];
    if (iconFileName != nil && [iconFileName isEqual: [NSNull null]] == NO)
    {
      NSString *iconPath = [bundle pathForImageResource: iconFileName];
      NSImage *image = nil;
            
      if (iconPath != nil)
        image = [[[NSImage alloc] initWithContentsOfFile: iconPath] autorelease];
            
      if (image != nil)
        [info setObject: image forKey: @"image"]; 
    }
  }
    
  return info;
}

#ifdef HAVE_UKTEST
- (void) testPreferencePaneAtPath
{
    UKFalse([self instantiate]);
}
#endif

/** <p>Loads the plugin bundle located at <var>path</var>, checks it conforms to 
    <em>Plugin schema</em> stored in the related bundle property list.</p>
    <p>Every property list values associated to <em>Plugin schema</em> are put in a
    dictionary to be used as plugin object, eventual validity errors
    are reported each time a value is read in NSBundle description values
    returned by -infoDictionary.</p> */
- (PKPreferencePane *) preferencePaneAtPath: (NSString *)path
{
  return [self paneAtPath: path];
}

- (PKPreferencePane *) preferencePaneWithIdentifier: (NSString *)identifier
{
  return [self paneWithIdentifier: identifier];
}

@end

