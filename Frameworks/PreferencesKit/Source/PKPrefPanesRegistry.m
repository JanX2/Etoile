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

#import "PKPrefsModulePrefPane.h"
#import "PKPrefPanesRegistry.h"


static PKPrefPanesRegistry *sharedRegistry = nil;


@implementation PKPrefPanesRegistry

+ (id) sharedRegistry
{	
	if(sharedRegistry == nil)
	{
		sharedRegistry = [[self alloc] init];
	}
	
	return sharedRegistry;
}

- (void) loadAllPlugins
{
	[self loadPluginsOfType: @"prefPane"];
	[self loadPluginsOfType: @"prefsModule"];
}

- (PKPreferencePane *) preferencePaneAtPath: (NSString *)path
{
	NSMutableDictionary *info = [self loadPluginForPath: path];
	PKPreferencePane *pane = [info objectForKey: @"instance"];
	
	if(pane == nil)
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
            
            pane = [[[PKPrefsModulePrefPane alloc] initWithBundle: [info objectForKey: @"bundle"]] autorelease];
			module = [[[mainClass alloc] initWithOwner: (PKPrefsModulePrefPane *)pane] autorelease];	/* Pane takes over ownership of the module. */
			[info setObject: [module buttonImage] forKey: @"image"];
			[info setObject: [module buttonCaption] forKey: @"name"];
		}
		
		[info setObject: pane forKey: @"instance"];
		[pane loadMainView];
	}
	
	return pane;
}


@end
