/*
	PKPreferencesController.m

	Preferences window controller class

	Copyright (C) 2001 Dusk to Dawn Computing, Inc. 
	              2004 Quentin Mathe

	Author: Jeff Teunissen <deek@d2dc.net>
	        Quentin Mathe <qmathe@club-internet.fr>

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation; either version 2 of
	the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <PrefsModule/PrefsModule.h>
#import "PKPreferencesController.h"

static PKPreferencesController *sharedInstance = nil;
static NSMutableDictionary *modules = nil;
static id currentModule = nil;
static BOOL inited = NO;


@implementation PKPreferencesController

+ (PKPreferencesController *) sharedPreferencesController
{
	if (sharedInstance != nil)
	{
		return sharedInstance;
	}
	else
	{
		return [[self alloc] init];
	}
}

- (id) init
{
	if (sharedInstance != nil) 
	{
		[self dealloc];
	} 
	else 
	{
		self = [super init];
		modules = [[[NSMutableDictionary alloc] initWithCapacity: 5] retain];
	}
	
	return sharedInstance = self;	
}

/* Initialize stuff that can't be set in the nib/gorm file. */
- (void) awakeFromNib
{
	PKBundleController *bundleController = [PKBundleController sharedBundleController];
	
	/* Let the system keep track of where it belongs. */
	[window setFrameAutosaveName: @"PreferencesMainWindow"];
	[window setFrameUsingName: @"PreferencesMainWindow"];
	
	[bundleController setDelegate: self];
	[bundleController loadBundles];
	[prefsController initUI];
}

/* 
 * Since we manage a single instance of the class, we override the -retain
 * and -release methods to do nothing.
 */

- (id) retain
{
	return self;
}

- (oneway void) release
{
	return;
}

/*
 * Do some special handling so that instances created with +alloc can be
 * deleted, while still not allowing the shared instance to be deallocated.
 */
- (void) dealloc
{
	if (sharedInstance != nil && self != sharedInstance)
	{
		[super dealloc];
	}
	
	return;
}

/*
 * Modules related methods
 */
 
- (BOOL) registerPrefsModule: (id)aPrefsModule;
{
	NSString *identifier;
	
	if (!aPrefsModule
	|| ![aPrefsModule conformsToProtocol: @protocol(PrefsModule)])
		return NO;
		
	identifier = [aPrefsModule buttonCaption];

	if ([[modules allKeys] containsObject: identifier])
	{
		NSLog(@"The module named %@ cannot be loaded because there is \
		already a loaded module with this name", aPrefsModule);
	}
	else
	{
		[modules setObject: aPrefsModule forKey: identifier];
		[self updateUIForPrefsModule: aPrefsModule];
	}

	return YES;
}

- (BOOL) setCurrentModule: (id <PrefsModule>)aPrefsModule;
{
	NSView *mainView = [self prefsMainView];
	NSView *moduleView = [aPrefsModule view];
	NSRect mavFrame = [mainView frame];
	NSRect movFrame = [moduleView frame];
	NSRect cvFrame = [[window contentView] frame];
	NSRect cvWithoutToolbarFrame = [[window contentViewWithoutToolbar] frame];
	NSRect wFrame = [window frame];
	float height;
	
	if (aPrefsModule == nil || [modules objectForKey: [aPrefsModule buttonCaption]] == NO
		|| moduleView == nil)
	{
		return NO;
	}
	
	[[mainView subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	height = cvFrame.size.height - cvWithoutToolbarFrame.size.height +
	movFrame.size.height;
	
	[window setFrame: NSMakeRect(wFrame.origin.x, wFrame.origin.y + (wFrame.size.height - height),
		wFrame.size.width, height) display: YES animate: YES];	
	[moduleView setFrame: NSMakeRect(mavFrame.origin.x + (cvFrame.size.width - movFrame.size.width) / 2,
		movFrame.origin.y, movFrame.size.width, movFrame.size.height)];
		
	[mainView addSubview: moduleView];
	[mainView setNeedsDisplay: YES];
	
	[window setTitle: [aPrefsModule buttonCaption]];
	
	return YES;
}

/*
 * PrefsApplication delegate method
 */

- (void) moduleLoaded: (NSBundle *)aBundle
{
	NSDictionary *info = nil;

	/* Let's get paranoid about stuff we load... :) */
	if (aBundle == nil) 
	{
		NSLog (@"Controller -moduleLoaded: sent nil bundle");
		return;
	}

	if ((info = [aBundle infoDictionary]) == nil) 
	{
		NSLog (@"Bundle `%@ has no info dictionary!", aBundle);
		return;
	}

	if ([info objectForKey: @"NSExecutable"] == nil) 
	{
		NSLog (@"Bundle `%@ has no executable!", aBundle);
		return;
	}

	if ([aBundle principalClass] == nil) 
	{
		NSLog (@"Bundle `%@ has no principal class!", [[info objectForKey: @"NSExecutable"] lastPathComponent]);
		return;
	}

	if ([[aBundle principalClass] conformsToProtocol: @protocol(PrefsModule)] == NO) 
	{
		NSLog (@"Bundle %@ principal class does not conform to the PrefsModule protocol.", [[info objectForKey: @"NSExecutable"] lastPathComponent]);
		return;
	}

	[[[aBundle principalClass] alloc] initWithOwner: self];
}

/*
 * Accessors
 */

/* For compatibility with Backbone module */
- (id <PrefsController>) preferencesController 
{
	return self;
}

- (id) window;
{
	return window;
}

- (id <PrefsModule>) currentModule;
{
	return currentModule;
}

/*
 * Runtime stuff
 */

- (BOOL) respondsToSelector: (SEL)aSelector
{
	if (aSelector != NULL)
		return NO;

	if ([super respondsToSelector: aSelector])
		return YES;

	if (currentModule != nil)
		return [currentModule respondsToSelector: aSelector];

	return NO;
}

- (NSMethodSignature *) methodSignatureForSelector: (SEL)aSelector
{
	NSMethodSignature *sign = [super methodSignatureForSelector: aSelector];

	if (sign != nil && currentModule != nil)
		sign = [(NSObject *)currentModule methodSignatureForSelector: aSelector];

	return sign;
}

- (void) forwardInvocation: (NSInvocation *)invocation
{
	[invocation invokeWithTarget: currentModule];
}

/*
 * Preferences window UI stuff
 */

- (void) initUI
{

}

- (void) updateUIForPrefsModule: (id <PrefsModule>)module
{
	if (inited)
	{
		[self initUI];
		NSDebugLog(@"UI updated");
	}
}

- (NSView *) preferencesMainView
{
	return nil;
}

/*
 * Window delegate methods
 */

- (void) windowWillClose: (NSNotification *) aNotification
{
  // TODO: Tell the loaded modules about this so that they can clean up after
  // themselves
}

/*
 * Action methods
 */

- (void) switchView: (id)sender
{
	[self setCurrentModule: [modules objectForKey: [sender label]]];
}

@end
