/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <AppKit/AppKit.h>

/**
 * The Grr main window sends notifications for special keystrokes.
 * Apart from the fact that notifications are used, the coupling is
 * pretty tight. There are no mechanisms to ensure that only one
 * plugin does an action when a key is pressed, but the names of the
 * notifications indicate which plugin shall listen to them.
 */

// --------------------------------------------------------------
//    the notifications sent by the extended window class
// --------------------------------------------------------------

extern NSString* ScrollArticleUpNotification;        // Page Up
extern NSString* ScrollArticleDownNotification;      // Page Down

extern NSString* SelectPreviousArticleNotification;  // Up Arrow
extern NSString* SelectNextArticleNotification;      // Down Arrow


// -----------------------------------------------------------------------
//    the extended window class which sends notifications on key presses.
// -----------------------------------------------------------------------
@interface ExtendedWindow : NSWindow
{
    // empty
}

-(void) keyDown: (NSEvent*)anEvent;

@end


