//
//  GSPreferencePane.m
//  GSSystemPreferences
//
//  Created by Uli Kusterer on 22.10.04.
//  Copyright 2004 M. Uli Kusterer. All rights reserved.
//

#import "GSPreferencePane.h"
#import "GSSysPrefsAppDelegate.h"
#import <AppKit/AppKit.h>


NSString *NSPreferencePaneDoUnselectNotification = @"NSPreferencePaneDoUnselect";
NSString *NSPreferencePaneCancelUnselectNotification = @"NSPreferencePaneCancelUnselect";


@implementation GSPreferencePane

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
		[_owner loadPrefPane: nil];
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
	return( [[_owner currPane] objectForKey: @"prefPane"] == self );
}


-(void) updateHelpMenuWithArray:(NSArray *)inArrayOfMenuItems
{
	NSLog(@"GSPreferencePane: updateHelpMenuWithArray: not yet implemented.");
}


-(void)	setOwner: (GSSysPrefsAppDelegate*)owner
{
	_owner = owner;
}


@end
