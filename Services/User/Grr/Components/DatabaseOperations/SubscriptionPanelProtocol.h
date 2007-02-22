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

#import "DatabaseElement.h"

@protocol SubscriptionPanel

/**
 * This sets the reference element for the subscription. If this is
 * a Category, the newly subscribed feed will be placed in this
 * category. If it's not a category, the newly subscribed feed will
 * be placed right below this element.
 */
-(void) setReferenceElement: (id<DatabaseElement>) anElement;

/**
 * Displays the subscription panel
 */
-(void) show;

@end


