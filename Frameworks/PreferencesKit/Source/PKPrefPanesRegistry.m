/*
	PKPrefPanesRegistry.h
 
	PrefPanes manager class used to register new preference panes and obtain 
 already registered preference panes
 
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

static PKPrefPanesRegistry *sharedPrefPanesRegistry;

// FIXME: Will need to removed when implemented elsewhere
@interface NSArray (ObjectWithValueForKey)
- (id) objectWithValue: (id)value forKey: (NSString *)key;
@end

@implementation PKPrefPanesRegistry

+ (void) initialize
{
    if (self == [PKPrefPanesRegistry class])
    {
        sharedPrefPanesRegistry = [[PKPrefPanesRegistry alloc] init];
    }
}

/** Returns PKPrefPanesRegistry shared instance (singleton). */
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

/** Locates and loads Preference Pane bundles.<br />
    Normally you only need to call this method to load a preference pane. */
- (void) loadAllPlugins
{
	[self loadPluginsOfType: @"prefPane"];
	[self loadPluginsOfType: @"prefsModule"];
}

#ifdef HAVE_UKTEST
- (void) testPreferencePaneAtPath
{
    UKFalse([self instantiate]);
}
#endif

/** <p>Loads the plugin bundle located at <var>path</var>, checks it conforms to 
    <strong>Plugin schema</strong> stored in the related bundle property list.</p>
    <p>Every property list values associated to Plugin schema are put in a
    dictionary to be used as plugin object, eventual validity errors
    are reported each time a value is read in NSBundle description values
    returned by <ref>-infoDictionary</ref>.</p> */
- (PKPreferencePane *) preferencePaneAtPath: (NSString *)path
{
	NSMutableDictionary *info = [self loadPluginForPath: path];
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
			Class mainClass = [[info objectForKey: @"class"] pointerValue];
            id module;
            NSImage *image;
            NSString *name;
            
            pane = [[[PKPrefsModulePrefPane alloc] initWithBundle: [info objectForKey: @"bundle"]] autorelease];
			module = [[[mainClass alloc] initWithOwner: (PKPrefsModulePrefPane *)pane] autorelease];	/* Pane takes over ownership of the module. */
			image = [module buttonImage];
            if (image == nil)
                image = [NSImage imageNamed: @"NSApplicationIcon"]; /* Falling back on our default icon */
            [info setObject: image forKey: @"image"];
            name = [module buttonCaption];
            if (name == nil)
                name = @"Unknown";
			[info setObject: name forKey: @"name"];
		}
		
		[info setObject: pane forKey: @"instance"];

		[pane loadMainView];
	}
	
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
