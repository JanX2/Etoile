/*
	SCConfig.m
 
	Utility code and SCConfigElement abstract class to represent any object 
	whose preferences can be modified.
 
	Copyright (C) 2006 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
    Date:  November 2006
 
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

#import <Foundation/Foundation.h>
#import "SCConfig.h"


@implementation SCConfigElement

// FIXME: Implement proxy/server instance mechanism to match documentation 
// below.
/** Returns a proxy of the desired class, any messages sent to it are handled
    by etoile_configServer daemon. */
+ (SCConfigElement *) sharedInstance
{
	id instance = [[self alloc] init];
	
	return AUTORELEASE(instance);
}

@end
