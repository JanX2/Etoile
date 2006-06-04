/* 
    SBServicesBar.h

    Core class for the services bar
   
    Copyright (C) 2004 Quentin Mathe

    Author:  Quentin Mathe <qmathe@club-internet.fr>
    Date:  November 2004
   
    This file is part of the Etoile desktop environment.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/  

@protocol UKTest;

@class NSMutableArray;
@class GSToolbar;
@class SBServicesBarItem;


@interface SBServicesBar : NSObject <UKTest>
{
	NSMutableArray *_items;
	GSToolbar *_itemToolbar;
	GSToolbarView *_toolbarView;
	BOOL _vertical;
	float _thickness;

#ifdef HAVE_UKTEST
	@public
	NSWindow *_window;
#endif
}

+ (id) systemServicesBar;

// FIXME: the next method to be used needs to be passed a serialized item 
// entirely built on the client side (that means to support NSCoding protocol 
// with NSServicesBarItem)
- (void) addServicesBarItem: (SBServicesBarItem *)item;

- (void) insertServicesBarItem: (SBServicesBarItem *)item atIndex: (int)index;
- (void) removeServicesBarItem: (SBServicesBarItem *)item;

- (BOOL) isVertical;
- (float) thickness;

@end
