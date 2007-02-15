/** <title>SCMonitor class to handle monitor related preferences</title>

	SCMonitor.m

	<abstract>Screen configuration class</abstract>

	Copyright (C) 2006 Quentin Mathe

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

#import "SCMonitor.h"
#import "SCConfig+Private.h"


/* Main implementation */

@implementation SCMonitor

- (NSSize) resolution
{
	return NSZeroSize;
}

- (void) setResolution: (NSSize)size
{
	[self notifyErrorCode: SCScreenResolutionChangeFailure
		description: @"Change of screen resolution not supported."];
}

- (int) colorDepth
{
	return -1;
}

- (void) setColorDepth: (int)colorDepth
{
	[self notifyErrorCode: SCScreenColorDepthChangeFailure
		description: @"Change of screen color depth not supported."];
}

- (int) contrast
{
	return -1;
}

- (void) setContrast: (int)contrast
{
	[self notifyErrorCode: SCScreenContrastChangeFailure
		description: @"Change of screen color depth not supported."];
}

- (int) brightness
{
	return -1;
}

- (void) setBrightness: (int)brightness
{
	[self notifyErrorCode: SCScreenBrightnessChangeFailure
		description: @"Change of screen color depth not supported."];
}

- (SCRefreshRate) refreshRate
{
	SCRefreshRate rate = {0, 0};
	
	return rate;
}

- (void) setRefreshRate: (SCRefreshRate)rate
{
	[self notifyErrorCode: SCScreenRefreshRateChangeFailure
		description: @"Change of screen color depth not supported."];
}

@end
