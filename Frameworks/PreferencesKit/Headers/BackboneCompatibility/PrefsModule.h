/*
	Preferences.h

	Definitions for all Preferences modules

	Copyright (C) 2003 Dusk to Dawn Computing, Inc.

	Author: Jeff Teunissen <deek@d2dc.net>
	Date:	11 Nov 2001

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
#ifndef PrefsModule_PrefsModule_h
#define PrefsModule_PrefsModule_h

#include <Foundation/NSObject.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSString.h>

#include <AppKit/NSBox.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSView.h>
#include <AppKit/NSButtonCell.h>

// size of a Prefs view
#define PrefsRect NSMakeRect (0, 0, 400, 196)

/*
	This protocol defines the public interface that PrefsModules use to
	communicate with the application's preferences module controller.

	The app's PrefsController class formally adopts this protocol, so you
	can check for conformance if you're extra-paranoid.

	Special note: If the prefs controller gets a message it doesn't respond
	to, it will first check to see if the currently-displayed module
	responds to it, and in that case it will automatically forward the
	message. You can use this property to do special things like handle
	color and font selection, which turns out to be pretty neat. :)
*/
@protocol PrefsController <NSObject>

/*
	Register a prefs module with the application. The object sent *MUST*
	formally adopt the PrefsModule protocol, or it will not be registered.

	Returns YES on success, NO on failure.
*/
- (BOOL) registerPrefsModule: (id) aPrefsModule;

/*
	Returns the module currently be displayed, or nil if no module is
	currently being displayed.
*/
- (id) currentModule;

/*
	Tells the app to display aPrefsModule's view in its window's main view.

	Returns YES on success.

	The module must:
		be non-nil,
		have already been registered, and
		not return nil from its -view method
	or this method will return NO and do nothing.
*/
- (BOOL) setCurrentModule: (id) aPrefsModule;

@end

/*
	This protocol defines the interface to the application's controller.

	The controller class formally adopts this protocol, so you can check
	for conformance if you're extra-paranoid.
*/
@protocol PrefsApplication <NSObject>

/*
	This method is private, to be sent from the PrefsController to the
	application controller. If you send this, it will probably get annoyed
	and give you flatulence until the end of your days...and nobody wants
	that.

	Okay, I lied. It's safe to call, but it's only good for manually loading
	and setting up other preferences bundles, since the implementation is
	loaded with paranoia.
*/
- (void) moduleLoaded: (NSBundle *) aModule;

/*
	Returns a reference to the shared prefs controller.
*/
- (id) prefsController;

@end

@protocol PrefsModule <NSObject>

/*
	This method is called by the application when the bundle has been
	loaded successfully. You should call

	[[anOwner prefsController] registerPrefsModule: self]

	somewhere as part of the implementation of this method, or you will not
	get an icon in the interface.

	This message is only sent once, to the principal class of the bundle.
	If your bundle contains multiple PrefsModule classes (after all,
	there's no reason not to), you should resend this message to each of
	them so that they can register themselves with the PrefsController.

	The implementation should return self, but the return value may or may
	not be used.
*/
- (id) initWithOwner: (id <PrefsApplication>) anOwner;

/*
	The implementation should return a localized string that describes
	what the module controls. Be descriptive, but note that the caption
	will be displayed inside the application's title bar (so special
	characters may not be displayed correctly).
*/
- (NSString *) buttonCaption;

/*
	Implementations should return an NSImage no larger than 64x64 pixels
	in size. This image will be displayed as the module's icon in the
	interface, so please make it meaningful.
*/
- (NSImage *) buttonImage;

/*
	Implementations should return a selector. A message using this selector
	will be sent when the user selects "your" icon in the interface.
*/
- (SEL) buttonAction;

/*
	Implementations should return the view to display in the module display
	area of the interface.

	This method should never return nil. See the section on
	-setCurrentModule: to find out why.
*/
- (NSView *) view;

@end

#endif // PrefsModule_PrefsModule_h
