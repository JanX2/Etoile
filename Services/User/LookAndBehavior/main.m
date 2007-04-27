/*
    main.m

    Copyright (C) 2005 Quentin Mathe <qmathe@club-internet.fr>

    Author:  Quentin Mathe <qmathe@club-internet.fr>
    Date:  December 2005

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this program; see the file COPYING.LIB.
    If not, write to the Free Software Foundation,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <PaneKit/PaneKit.h>

// FIXME: Hack to workaround the fact Gorm doesn't support NSView as custom view
// class.
@interface CustomView : NSView { }
@end

@implementation CustomView
@end


int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}
