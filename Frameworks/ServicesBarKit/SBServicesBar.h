/* 
   SBServicesBar.h

   Core class for the services bar
   
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

@protocol UKTest;

@class NSMutableArray;
@class GSToolbar;
@class SBServicesBarItem;


@interface SBServicesBar : NSObject <UKTest>
{
	BOOL _vertical;
	float _thickness;
	NSMutableArray *_items;
	GSToolbar *_itemsToolbar;
	id _toolbarView;
	
	@public
	id _window;
}

+ (SBServicesBar *) sharedServicesBar;

- (void) addServicesBarItem: (SBServicesBarItem *)item;
- (void) insertServicesBarItem: (SBServicesBarItem *)item atIndex: (int)index;
- (void) removeServicesBarItem: (SBServicesBarItem *)item;

- (BOOL) isVertical;
- (float) thickness;

@end
