/** <title>PKPrefPanesRegistry</title>

	PKPrefPanesRegistry.m
 
	<abstract>PrefPanes manager class used to register new preference panes and 
    obtain already registered preference panes</abstract>
 
	Copyright (C) 2004 Uli Kusterer
 
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

#import "PKPrefsModulePrefPane.h"
#import "PKPreferencePane.h"
#import "PKPrefPanesRegistry.h"
#import "CocoaCompatibility.h"

static PKPrefPanesRegistry *sharedPrefPanesRegistry;

/** <p>PKPrefPanesRegistry Description</p> */
@implementation PKPrefPanesRegistry

+ (void) initialize
{
    if (self == [PKPrefPanesRegistry class])
    {
        sharedPrefPanesRegistry = [[PKPrefPanesRegistry alloc] init];
    }
}

/** <p>Returns PKPrefPanesRegistry shared instance (singleton).</p> */
+ (id) sharedRegistry
{	    
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
	[self loadPluginsOfType: @"prefsModule"];
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
        if (name != nil && [name isEqual: [NSNull null]] == NO && [name length] != 0)
            [info setObject: name forKey: @"name"];
        
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
    else if ([type isEqualToString: @"prefsModule"]) /* Backbone Preferences.app PrefsModules are wrapped in a special GSPreferencePane subclass. */
    {
        // NOTE: For prefs module, we cannot use lazy class instanciation 
        // because pane label and icon are provided with module object methods 
        // -buttonCaption and -buttonImage. That's why we call 
        // -preferencePaneAtPath to force module class allocation, otherwise
        // label and icon displayed in presentation list would be empty (or match
        // other plist entries like NSApplicationIcon, CFBundleName).
        
        Class mainClass = [[info objectForKey: @"class"] pointerValue];
        id pane;
        id module;
        NSImage *image;
        NSString *name;
        
        pane = [[[PKPrefsModulePrefPane alloc] initWithBundle: [info objectForKey: @"bundle"]] autorelease];
        [info setObject: pane forKey: @"instance"];
        
        module = [[[mainClass alloc] initWithOwner: (PKPrefsModulePrefPane *)pane] autorelease];	/* Pane takes over ownership of the module. */
        
        image = [module buttonImage];
        if (image != nil)
            [info setObject: image forKey: @"image"];
                
        name = [module buttonCaption];
        if (name != nil && [name length] != 0)
            [info setObject: name forKey: @"name"];
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
    NSMutableDictionary *info = [pluginPaths objectForKey: path];
    
    /* We check whether the plugin is already loaded. When it isn't, we try
       to load it. */
    // NOTE: We may check plugin conforms to preference pane schema. In case of
    // invalidity, it would be reloaded. For now, we only check the plugin 
    // availability.
    if (info == nil)
        info = [self loadPluginForPath: path];
    
	PKPreferencePane *pane = [info objectForKey: @"instance"];
	
	if (pane == nil)
	{
		NSString *type = [[info objectForKey: @"path"] pathExtension];
		
		if ([type isEqualToString: @"prefPane"]) /* System Preferences pane. */
		{
			Class mainClass = [[info objectForKey: @"class"] pointerValue];
			pane = [[[mainClass alloc] initWithBundle: [info objectForKey: @"bundle"]] autorelease];
		}
		else if ([type isEqualToString: @"prefsModule"]) /* Backbone Preferences.app PrefsModules are wrapped in a special GSPreferencePane subclass. */
		{
            // NOTE: Instanciation is done in -loadPluginForPath: for prefs 
            // module. More explanations in -loadPluginForPath.
		}
		
		[info setObject: pane forKey: @"instance"];
	}
    
    if ([pane mainView] == nil)
        [pane loadMainView];
	
	return pane;
}

- (PKPreferencePane *) preferencePaneWithIdentifier: (NSString *)identifier
{
    NSDictionary *plugin = [[self loadedPlugins] objectWithValue: identifier forKey: @"identifier"];
    PKPreferencePane *pane;
    
    pane = [self preferencePaneAtPath: [plugin objectForKey: @"path"]];
    
    return pane;
}

@end
