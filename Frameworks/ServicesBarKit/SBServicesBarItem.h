/* 
   SBServicesBarItem.h

   Core class for the services bar framework
   
   Copyright (C) 2004 Quentin Mathe

   Author: Quentin Mathe <qmathe@club-internet.fr>
   Date: November 2004
   
   This file is part of the Etoile desktop environment.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#import <UnitKit/UnitKit.h>

@class NSAttributedString;
@class NSImage;
@class NSMenu;
@class NSString;
@class NSToolbarItem;
@class NSView;
@class SBServicesBar;


@interface SBServicesBarItem : NSObject <UKTest>
{
	float _itemLength;
    NSView *_itemView;
	NSString *_title;
	NSAttributedString *_attTitle;
	NSImage *_image;
	NSImage *_altImage;
	NSMenu *_menu;
	BOOL _highlightMode;
	NSString *_toolTip;
	
	@public
	NSToolbarItem *_toolbarItem;
}

- (id) initWithTitle: (NSString *)title;

- (SBServicesBar *) servicesBar;

- (NSString *) title;
- (void) setTitle: (NSString *)title;
- (float) length;
- (void) setLength: (float)length;
- (NSView *) view;
- (void) setView: (NSView *)view;

@end

/*
 * Service bar item default implementation
 */

@interface SBServicesBarItem (Default)

- (void) sendActionOn: (int)mask;
- (void) popUpMenu: (NSMenu *)menu;

/*
 * Accessors
 */

- (SEL) action;
- (void) setAction: (SEL)action;
- (id) target;
- (void) setTarget: (id)target;
- (NSAttributedString *) attributedTitle;
- (void) setAttributedTitle: (NSAttributedString *)title;
- (NSImage *) image;
- (void) setImage:(NSImage *)image;
- (NSImage *) alternateImage;
- (void) setAlternateImage:(NSImage *)image;
- (NSMenu *) menu;
- (void) setMenu: (NSMenu*)menu;
- (BOOL) isEnabled;
- (void) setEnabled: (BOOL)enabled;
- (NSString *) toolTip;
- (void) setToolTip: (NSString *)toolTip;
- (void) setHighlightMode: (BOOL)highlightMode;
- (BOOL) highlightMode;

@end
