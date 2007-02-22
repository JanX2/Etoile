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

/*
 * The extended window class sends notifications to plugins on special keystrokes.
 */

#import "ExtendedWindow.h"


// ----------------------------------------------------------------------------
//    extended window keystroke notifications
// ----------------------------------------------------------------------------
NSString* ScrollArticleUpNotification = @"ScrollArticleUpNotification";
NSString* ScrollArticleDownNotification = @"ScrollArticleDownNotification";

NSString* SelectPreviousArticleNotification = @"SelectPreviousArticleNotification";
NSString* SelectNextArticleNotification = @"SelectNextArticleNotification";


// ----------------------------------------------------------------------------
//    the extended window class
// ----------------------------------------------------------------------------
@implementation ExtendedWindow

-(void) keyDown: (NSEvent*)anEvent
{
    NSString* characters = [anEvent characters];
    
    if ([characters length] > 0) {
        unichar character = [characters characterAtIndex: 0];
        NSString* notifName = nil;
        
        switch (character) {
            case NSUpArrowFunctionKey:
                notifName = SelectPreviousArticleNotification;
                break;
                
            case NSDownArrowFunctionKey:
                notifName = SelectNextArticleNotification;
                break;
                
            case NSPageUpFunctionKey:
                notifName = ScrollArticleUpNotification;
                break;
                
            case NSPageDownFunctionKey:
                notifName = ScrollArticleDownNotification;
                break;
                
            default:
                notifName = nil;
                break;
        }
        
        if (notifName != nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName: notifName
                                                                object: self
                                                              userInfo: nil];
        }
    }
}

@end
