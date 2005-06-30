/*
	PKPreferencePane.h
 
	Preference pane class (was GSPreferencePane)
 
	Copyright (C) 2004 Uli Kusterer
 
	Author:  Uli Kusterer
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
#import <AppKit/AppKit.h>

NSString *NSPreferencePaneDoUnselectNotification = @"NSPreferencePaneDoUnselect";
NSString *NSPreferencePaneCancelUnselectNotification = @"NSPreferencePaneCancelUnselect";


@implementation PKPreferencePane

-(id)	initWithBundle: (NSBundle*) bundle
{
	self = [super init];
	
	_bundle = [bundle retain];
	
	return self;
}

-(void)	dealloc
{
	[_bundle release];
	[_topLevelObjects makeObjectsPerformSelector: @selector(release)];
	[_topLevelObjects release];
	
	[super dealloc];
}

-(NSBundle*) bundle
{
	return _bundle;
}

-(NSView*) loadMainView
{
	_topLevelObjects = [[NSMutableArray alloc] init];
	NSDictionary*	ent = [NSDictionary dictionaryWithObjectsAndKeys:
							self, @"NSOwner",
							_topLevelObjects, @"NSTopLevelObjects",
							nil];

	if( ![_bundle loadNibFile: [self mainNibName] externalNameTable: ent withZone: [self zone]] )
		return nil;
	
	[self assignMainView];
	[self mainViewDidLoad];
	
	return _mainView;
}


-(void)	assignMainView
{
	[self setMainView: [_window contentView]];
}


-(NSString*)	mainNibName
{
	return [[_bundle infoDictionary] objectForKey: @"NSMainNibFile"];
}

-(void)	willSelect		{}
-(void)	didSelect		{}
-(void)	willUnselect	{}
-(void)	didUnselect		{}
-(void)	mainViewDidLoad	{}


-(NSPreferencePaneUnselectReply) shouldUnselect
{
	return NSUnselectNow;
}


-(void)	replyToShouldUnselect: (BOOL)shouldUnselect
{
	if( shouldUnselect )
		[_owner updateUIForPreferencePane: nil];
}


-(void) setMainView: (NSView*)view
{
	[_mainView autorelease];
	_mainView = [view retain];
}


-(NSView*) mainView
{
	return _mainView;
}


-(NSView*) initialKeyView
{
	return _initialKeyView;
}


-(void) setInitialKeyView: (NSView*)view
{
	[_initialKeyView autorelease];
	_initialKeyView = [view retain];
}


-(NSView*) firstKeyView
{
	return _firstKeyView;
}


-(void) setFirstKeyView: (NSView*)view
{
	[_firstKeyView autorelease];
	_firstKeyView = [view retain];
}


-(NSView*) lastKeyView
{
	return _lastKeyView;
}


-(void) setLastKeyView: (NSView*)view
{
	[_lastKeyView autorelease];
	_lastKeyView = [view retain];
}


-(BOOL) autoSaveTextFields
{
	return YES;
}


-(BOOL) isSelected
{
	return( [_owner selectedPreferencePane] == self );
}


-(void) updateHelpMenuWithArray:(NSArray *)inArrayOfMenuItems
{
	NSLog(@"PKPreferencePane: updateHelpMenuWithArray: not yet implemented.");
}


-(void)	setOwner: (id <PKPreferencePaneOwner>)owner
{
	_owner = owner;
}


@end
