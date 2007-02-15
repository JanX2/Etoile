/*
	SCMouse.h
 
	SCMouse class to handle cursor device related preferences.
 
	Copyright (C) 2006,2007 Quentin Mathe, Guenther Noack
 
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
#import "SCConfig.h"


/**
 * Controls the mouse properties.
 * 
 * THRESHOLD AND ACCELERATION
 * 
 * Threshold and acceleration are used to control the mouse speed when
 * moving the pointer fast. When the number of pixels the pointer is moved
 * by in a short time exceeds the threshold, the pointer speed is multiplied
 * by acceleration.
 *
 * The semantics of threshold and acceleration are chosen to match the
 * semantics of threshold and acceleration in X11's xset utility.
 * 
 * DOUBLE CLICK INTERVAL
 * 
 * The double click interval is the maximum time in milliseconds that
 * is allowed to pass between two mouse clicks for them to be recognized
 * as double click.
 */
@interface SCMouse : SCConfigElement
{

}

/**
 * Returns the mouse acceleration. In case the setting of the mouse
 * acceleration is not supported, this method returns a value of 1.
 * 
 * Note that this is a "inconsistency" with many other SCConfig methods
 * which return -1 in this case. It's appropriate here because a system
 * that doesn't support mouse acceleration will keep the current mouse
 * speed when exceeding the threshold. This is equivalent to a
 * multiplication of the mouse speed with 1.
 */
- (float) acceleration;

/**
 * Sets the mouse acceleration. On failure, this method will send an
 * error to the delegate. 
 */
- (void) setAcceleration: (float)acceleration;

/**
 * Returns the threshold in pixels, which the mouse pointer needs to
 * be moved in a short time for the mouse to be accelerated.
 * 
 * If the mouse threshold is not supported or disabled, this method
 * returns -1.
 */
- (int) threshold;

/**
 * Sets the mouse acceleration threshold in pixels.
 * 
 * To disable mouse acceleration, set the threshold to a negative
 * value.
 * 
 * If a positive threshold value can't be applied, the method sends
 * an error to the delegate.
 */
- (void) setThreshold: (int)threshold;

/**
 * Returns the double click interval in milliseconds.
 * 
 * If reading the double click interval is not supported, -1 is
 * returned.
 */
- (int) doubleClickInterval;

/**
 * Sets the double click interval in milliseconds. The value must
 * be positive (excluding zero).
 * 
 * If setting of the double click interval is not supported, an error
 * is sent to the delegate.
 */
- (void) setDoubleClickInterval: (int)milliseconds;

@end

/* Trackpad dedicated support */
@interface SCMouse (SCTrackpad)
// FIXME: Proper methods should be added here.
@end

