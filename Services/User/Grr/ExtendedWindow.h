/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

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


