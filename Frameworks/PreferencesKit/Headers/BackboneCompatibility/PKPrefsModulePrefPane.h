/*
	PKPrefsModulePrefPane.h
 
	Backbone preferences modules compatiblity subclass (was GSPrefsModulePrefPane)
 
	Copyright (C) 2004 Uli Kusterer
 
	Author:   Uli Kusterer
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

#import "PKPreferencePane.h"
#import "PrefsModule.h"

/*
	This is a compatibility class that wraps a GSPreferencePane around a
	GNUstep Preferences.app-style prefsModule bundle. That way,
	GSSystemPreferences.app only has to know about prefPanes. The only other
	place that needs to know about prefsModules is the plugin loader (UKPrefPaneRegistry).
	
	The plugin registry will automatically load prefsModule bundles and will
	create an object of this type around the PrefsModule-conformant class
	loaded from the bundle, which also stands in as the PrefsApp and PrefsController
	for the module.
	
	Note that our implementation of the prefsModule is rather simplistic.
	We do not support loading additional modules from the same plugin, nor do
	we allow that the plugin can know about other plugins that are installed
	and switch to them.
	
	And finally, the module's view is inserted automatically, whether it calls
	setCurrentModule: in response to its action or not. So, some modules may not
	work in this app. However, the main intent of supporting modules is so
	existing prefsModules don't have to be rewritten or thrown out, and so users
	don't need two apps for setting preferences.
*/


@interface PKPrefsModulePrefPane : PKPreferencePane <PrefsApplication, PrefsController>
{
	id <PrefsModule> module;
}

@end
