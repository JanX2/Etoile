/**
 * Étoilé ProjectManager - WorkspaceManager - PMWorkspaceManager.m
 *
 * Copyright (C) 2010 Christopher Armstrong <carmstrong@fastmail.com.au>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 **/
#import <EtoileFoundation/EtoileFoundation.h>
#import <Foundation/NSNotification.h>
#import <XCBKit/XCBWindow.h>
#import <XCBKit/XCBComposite.h>
#import <XCBKit/XCBRender.h>
#import <XCBKit/XCBDamage.h>
#import <XCBKit/XCBFixes.h>
#import "PMWorkspaceManager.h"
#import "PMWindowTracker.h"
#import "PMImpermanentView.h"

@implementation PMWorkspaceManager
- (id)init
{
	SUPERINIT;
	trackers = [NSMutableDictionary new];
	views = [NSMutableArray new];
	[[ETModelDescriptionRepository mainRepository]
		collectEntityDescriptionsFromClass: [PMImpermanentView class]
		excludedClasses: [NSArray array]
		resolveNow: NO];
	[[ETModelDescriptionRepository mainRepository]
		collectEntityDescriptionsFromClass: [PMWorkspaceManager class]
		excludedClasses: [NSArray array]
		resolveNow: YES];
	return self;
}
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[trackers release];
	[views release];
	[viewSwitcher release];
	[super dealloc];
}
- (void)applicationDidFinishLaunching: (NSNotification*)notification
{
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter
		addObserver: self
		   selector: @selector(windowAvailable:)
		       name: XCBWindowBecomeAvailableNotification
		     object: nil];
	[defaultCenter
		addObserver: self
		   selector: @selector(windowMapped:)
		       name: XCBWindowDidMapNotification
		     object: nil];
	[XCBConnection sharedConnection];

	[XCBConn setDelegate: self];
	[XCBFixes initializeExtensionWithConnection: XCBConn];
	[XCBRender initializeExtensionWithConnection: XCBConn];
	[XCBDamage initializeExtensionWithConnection: XCBConn];
	XCBScreen *screen = [[XCBConn screens] objectAtIndex: 0];
	[screen setTrackingChildren: YES];
	[[screen rootWindow]
		setEventMask: XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY | 
			XCB_EVENT_MASK_PROPERTY_CHANGE |
			XCB_EVENT_MASK_STRUCTURE_NOTIFY |
			XCB_EVENT_MASK_EXPOSURE];
	[XCBComposite initializeExtensionWithConnection: XCBConn];
	[XCBComposite redirectSubwindows: [screen rootWindow]
	                          method: XCB_COMPOSITE_REDIRECT_AUTOMATIC];

 	// viewSwitcher = [[ETModelDescriptionRenderer renderer] 
 	// 		renderModel: self 
 	// 		description: [[ETModelDescriptionRepository mainRepository] entityDescriptionForClass: [PMWorkspaceManager class]]];

	viewSwitcher = [[[ETLayoutItemFactory factory] itemGroupWithRepresentedObject: [self allViews]] retain];
	[viewSwitcher setSource: viewSwitcher];
	[viewSwitcher setSize: NSMakeSize(200, 400)];

	//ETIconLayout *layout = [ETIconLayout layout];
	[viewSwitcher setLayout: [ETColumnLayout layout]];
	//[layout setIconSizeForScaleFactorUnit: NSMakeSize(80, 80)];
	//[layout setMinIconSize: NSMakeSize(80, 80)];
	[[[ETLayoutItemFactory factory] windowGroup] addItem: viewSwitcher];
	[viewSwitcher reloadAndUpdateLayout];
}

- (void)windowAvailable: (NSNotification*)notification
{
	XCBScreen *screen = [[XCBConn screens] objectAtIndex: 0];
	XCBWindow *newXcbWindow = [notification object];
	if (![[newXcbWindow parent] isEqual: [screen rootWindow]])
		return;
	if (nil != [trackers objectForKey: newXcbWindow])
		return;
	if ([newXcbWindow isEqual: [XCBWindow unknownWindow]])
		return;
	[discoveredWindows addObject: newXcbWindow];

	PMWindowTracker *windowTracker = [[PMWindowTracker alloc] initByTrackingWindow: newXcbWindow];
	if (windowTracker == nil)
		return;
	if (nil != [trackers objectForKey: [windowTracker window]])
	{
		NSDebugLLog(@"PMWorkspaceManager", @"Already tracking window: %@", [windowTracker window]);
		[windowTracker release];
		return;
	}
	[windowTracker setDelegate: self];
	[trackers setObject: windowTracker forKey: [windowTracker window]];
	[windowTracker release];
}

- (void)windowMapped: (NSNotification*)notification
{
	[self windowAvailable: notification];
}

- (void)trackedWindowActivated: (PMWindowTracker*)tracker
{
	// FIXME: Determine the type of view by checking cached window properties
	NSLog(@"Tracked window (%@) activated - creating view (%@)", tracker, [tracker topLevelWindow]);
	PMImpermanentView *view = [[PMImpermanentView alloc] initWithWindowTracker: tracker];
	[view setDelegate: self];
	[(NSMutableArray*)[self allViews] addObject: view];
	[viewSwitcher reloadAndUpdateLayout];
	[view release];
}
- (void)trackedWindowDidShow: (PMWindowTracker*)tracker
{
}
- (void)trackedWindowDidHide: (PMWindowTracker*)tracker
{
}
- (void)trackedWindowDeactivated: (PMWindowTracker*)tracker
{
	// This only gets called when a tracked window turns out
	// to be in the withdrawn state.
	[tracker setDelegate: nil];
	[trackers removeObjectForKey: [tracker window]];
}
- (void)trackedWindowPixmapUpdated: (PMWindowTracker*)tracker
{
	
}

- (void)viewDeactivated: (PMImpermanentView*)view
{
	NSDebugLLog(@"PMWorkspaceManager", @"View deactivated: %@", view);
	[trackers removeObjectForKey: [[view tracker] window]];
	[(NSMutableArray*)[self allViews] removeObject: view];
	[viewSwitcher reloadAndUpdateLayout];
}

- (NSArray*)allViews
{
	return views;
}

+ (ETEntityDescription*)newEntityDescription
{
	ETEntityDescription *desc = [self newBasicEntityDescription];
	if ([[desc name] isEqual: [PMWorkspaceManager className]] == NO)
		return desc;

	ETPropertyDescription *allViews = [ETPropertyDescription 
		descriptionWithName: @"allViews" 
		               type: (id)@"PMImpermanentView"];
	[allViews setIsContainer: YES];
	[desc setPropertyDescriptions: A(allViews)];
	return desc;
}
- (NSArray*)properties
{
	return [[super properties] arrayByAddingObjectsFromArray: A(@"allViews")];
}
@end