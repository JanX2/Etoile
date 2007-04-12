/*
    Controller.h

    Interface declaration of the Controller class for the
    EtoileMenuServer application.

    Copyright (C) 2005  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>

@class NSNotification, MenuBarWindow;

extern MenuBarWindow * ServerMenuBarWindow;

@interface Controller : NSObject

+ (NSRect) menuBarWindowFrame;
+ (MenuBarWindow *) sharedMenuBarWindow;

- (void) applicationDidFinishLaunching: (NSNotification *) notif;

- (void) windowDidMove: (NSNotification *) notif;

- (void) logOut: sender;
- (void) sleep: sender;
- (void) reboot: sender;
- (void) shutDown: sender;

- (id) workspaceApp;

@end

@interface NSApplication (EtoileMenuBar)
- (NSRect) menuBarWindowFrame;
@end
