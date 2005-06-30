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
#import "PKPrefsModulePrefPane.h"


@implementation PKPrefsModulePrefPane

-(void)	dealloc
{
	[module release];
	
	[super dealloc];
}

-(NSView*) loadMainView
{
	[self assignMainView];
	[self mainViewDidLoad];
	
	return _mainView;
}


-(void)	assignMainView
{
	[self setMainView: [module view]];
}


-(void)	didSelect
{
	[module performSelector: [module buttonAction] withObject: nil];	// Send module its action once it's been selected.
}


// PrefsApplication Methods:
-(id) prefsController
{
	return self;	// This object plays app and controller and PrefPane.
}

-(void) moduleLoaded: (NSBundle*)aModule
{
	// Preferences.app sends this between controller and app.
	//	Plugins may use this to load sub-plugins, which we don't support.
	NSLog(@"PrefsApplication moduleLoaded - NYI!");
}


// PrefsController Methods:
-(id) currentModule
{
	if( [_owner selectedPreferencePane] == self )
		return module;
	else
		return nil;		// Might create a dummy object for other panes?
}


-(BOOL) setCurrentModule: (id)aPrefsModule
{
	if( !aPrefsModule )
		return NO;
	
	if( aPrefsModule == module )	// Can only select ourselves.
	{
		if( [_owner selectedPreferencePane] != self )
			return [_owner updateUIForPreferencePane: self];
	}
    
    return NO;
}


-(BOOL) registerPrefsModule: (id)aPrefsModule
{
	if( !module )
	{
		module = [aPrefsModule retain];
		return YES;
	}
	else
		return NO;	// Can't register a module twice, can't register additional modules for one plugin.
}


@end
