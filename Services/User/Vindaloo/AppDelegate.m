/*
 * Copyright (C) 2005  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AppDelegate.h"
#import <AppKit/NSApplication.h>

/**
 * Non-Public methods.
 */
@interface AppDelegate (Private)
@end


@implementation AppDelegate

- (id) init
{
   self = [super init];
   if (self)
   {
      // ...
   }
   return self;
}

- (void) applicationDidFinishLaunching: (NSNotification*)aNotification
{
   // ensure that a shared PDFRenderService exists and is started
   //TODO: [PDFRenderService sharedService];
}

- (void) applicationWillTerminate: (NSNotification*)aNotification
{
   // stop the shared PDFRenderService
   //TODO: [[PDFRenderService sharedService] stop];
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation AppDelegate (Private)
@end

