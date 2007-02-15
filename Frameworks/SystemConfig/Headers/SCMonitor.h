/*
	SCMonitor.h
 
	SCMonitor class to handle monitor related preferences.
 
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

typedef struct _SCRefreshRate
{
	int vertical;
	int horizontal;
} SCRefreshRate;

// FIXME: This allows compilation until SCColorProfile is implemented
#define SCColorProfile NSString


/**
 * This class allows to configure the screen preferences.
 */
@interface SCMonitor : SCConfigElement
{

}

/**
 * Returns the current screen resolution. On error or if the method
 * is not implemented, it returns a resolution of 0,0 (NSZeroSize).
 * 
 * @return screen resolution as NSSize
 */
- (NSSize) resolution;

/**
 * Sets the screen resolution to the specified size. On error, the
 * delegate is notified using a configElement:preferenceModificationErrorOccured:
 * message.
 *
 * Many display systems will only allow a specific set of screen resolutions.
 * Typical values include 1024x768 and 1280x1024.
 *
 * @param size the desired screen resolution.
 */
- (void) setResolution: (NSSize)size;

/**
 * Returns the current color depth of the display. If the querying of
 * the color depth is not supported, -1 is returned. Typical values
 * are 16 and 24.
 * 
 * @return the color depth in bit
 */
- (int) colorDepth;

/**
 * Sets the color depth for the display. On error, the delegate
 * is notified using a configElement:preferenceModificationErrorOccured:
 * message.
 *
 * Typical depth values include 16 and 24. Setting the color depth
 * to 8 is possible on many displays, but is not very well supported
 * by GNUstep / Etoile.
 *
 * @param colorDepth the color depth in bit (e.g. for 2^16 colors, this would be 16)
 */
- (void) setColorDepth: (int)colorDepth;


// FIXME: Find out how contrast is used in X11 and other systems and document.
- (int) contrast;
- (void) setContrast: (int)contrast;

// FIXME: Find out how brightness is used in X11 and other systems and document.
- (int) brightness;
- (void) setBrightness: (int)brightness;

/**
 * Returns the current screen refresh rate.
 */
- (SCRefreshRate) refreshRate;

/**
 * Sets the screen refresh rate.
 */
- (void) setRefreshRate: (SCRefreshRate)rate;


/* Software related preferences */

// FIXME: Implement the following methods by relying on some CMS library
//- (SCColorProfile *) colorProfile;
//- (void) setColorProfile: (SCColorProfile *)profile;

@end
