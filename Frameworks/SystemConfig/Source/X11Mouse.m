/*
	X11Mouse.m
 
	SCMouse implementation for X11.
 
	Copyright (C) 2007 Guenther Noack
 
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

#import <GNUstepGUI/GSDisplayServer.h>

#import "SCConfig+Private.h"
#import "X11Mouse.h"

// ----------------------------------------------------------
//    Make sure a X11Mouse instance is returned when
//    requesting a SCMouse instance.
// ----------------------------------------------------------

@interface SCMouse (X11Mouse)
+(SCConfigElement*) sharedInstance;
@end

@implementation SCMouse (X11Mouse)
+(SCConfigElement*) sharedInstance
{
	return AUTORELEASE([[X11Mouse alloc] init]);
}
@end



// ----------------------------------------------------------
//    The X11Mouse class
// ----------------------------------------------------------
@interface X11Mouse (Private)
-(void) readX11AccelAndThreshold;
@end


@implementation X11Mouse

// ----------------------------------------------------------
//    init
// ----------------------------------------------------------
-(id) init
{
	if ((self = [super init]) != nil) {
		// Find current X11 display
		display = (Display*)[GSCurrentServer() serverDevice];
		
		if (display == NULL) {
			DESTROY(self);
		}
	}
	
	return self;
}

// ----------------------------------------------------------
//    Loading and storing mouse accel and threshold
// ----------------------------------------------------------

-(void) readX11AccelAndThreshold
{
	XGetPointerControl( display, &accel_numerator, &accel_denominator, &threshold );
	
	if (accel_numerator == accel_denominator && accel_denominator != 0) {
		do_accel = do_threshold = True;
	} else {
		do_accel = do_threshold = False;
	}
}

-(BOOL) writeX11AccelAndThreshold
{
	XChangePointerControl (
		display,
		do_accel, do_threshold,
		accel_numerator, accel_denominator,
		threshold
	);
	
	return YES;
}

// ----------------------------------------------------------
//    SCMouse protocol
// ----------------------------------------------------------

- (float) acceleration
{
	[self readX11AccelAndThreshold];
	
	if (do_accel) {
		return ((float)accel_numerator) / ((float)accel_denominator);
	} else {
		return 1.0;
	}
}

- (void) setAcceleration: (float)acceleration
{
	// A 1/16 resolution should be enough.
	accel_numerator = (int) (acceleration * (float)16.0);
	accel_denominator = 16;
	
	if (accel_numerator != 16) {
		do_accel = True;
	}
	
	if ([self writeX11AccelAndThreshold] == NO) {
		[self notifyErrorCode: SCMouseAccelerationChangeFailure
		          description: @"X11 Mouse acceleration change failed."];
	}
}

- (int) threshold
{
	[self readX11AccelAndThreshold];
	
	if (do_threshold) {
		return threshold;
	} else {
		return -1;
	}
}

- (void) setThreshold: (int)aThreshold
{
	if (aThreshold >= 0) {
		do_threshold = True;
		threshold = aThreshold;
	} else {
		do_threshold = False;
		threshold = 0; // XXX: Hope that works.
	}
	
	if ([self writeX11AccelAndThreshold] == NO) {
		[self notifyErrorCode: SCMouseThresholdChangeFailure
		          description: @"X11 Mouse threshold change failed."];
	}
}


@end


