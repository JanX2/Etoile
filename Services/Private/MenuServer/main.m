/*
    main.m

    Main application entry point for the EtoileMenuServer application.

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

#import <AppKit/NSApplication.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>

#import "Controller.h"

int main(int argc, const char * argv[])
{
  Controller * delegate;

  CREATE_AUTORELEASE_POOL (pool);

  // we never show the app icon
  [[NSUserDefaults standardUserDefaults]
    setObject: [NSNumber numberWithBool: YES] forKey: @"GSDontShowAppIcon"];

  delegate = [Controller new];
  [NSApplication sharedApplication];

  [NSApp setDelegate: delegate];

  DESTROY (pool);

  return NSApplicationMain(argc, argv);
}
