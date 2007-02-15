/*
	SCMouse.m
 
	SCMouse class to handle cursor device related preferences.
 
	Copyright (C) 2006 Quentin Mathe
	Copyright (C) 2007 Guenther Noack
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2006
 
	Author:  Guenther Noack <guenther@unix-ag.uni-kl.de>
	Date:  February 2007
	
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
#import "SCMouse.h"
#import "SCConfig+Private.h"

/*
 * This class contains default implementations for all SCMouse
 * methods. Override this class to provide your own implementation.
 */
@implementation SCMouse

- (float) acceleration
{
	// Factor of 1.0 => no acceleration
	return 1.0;
}

- (void) setAcceleration: (float)acceleration
{
	if (acceleration != 1.0) {
		[self notifyErrorCode: SCMouseAccelerationChangeFailure
		      description: @"Changing the mouse acceleration is "
		                   @"not supported."];
	}
}



- (int) threshold
{
	return -1;
}

- (void) setThreshold: (int)threshold
{
	if (threshold > 0) {
		[self notifyErrorCode: SCMouseThresholdChangeFailure
		      description: @"Changing the mouse threshold is not "
		                   @"supported."];
	}
}



- (int) doubleClickInterval
{
	return -1;
}

- (void) setDoubleClickInterval: (int)milliseconds
{
	NSParameterAssert(milliseconds > 0);
	
	[self notifyErrorCode: SCMouseDoubleClickIntervalChangeFailure
	      description: @"Changing the mouse double click interval "
	                   @"is not supported."];	
}

@end

/* Trackpad dedicated support */
@implementation SCMouse (SCTrackpad)
// FIXME: Proper methods should be added here.
@end

