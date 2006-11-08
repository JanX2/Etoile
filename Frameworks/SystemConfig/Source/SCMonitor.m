/** <title>SCMonitor class to handle monitor related preferences</title>

	SCMonitor.m

	<abstract></abstract>

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

#import "SCMonitor.h"


/* Main implementation */

@implementation SCMonitor

- (NSSize) resolution
{
	return NSZeroSize;
}

- (void) setResolution: (NSSize)size
{

}

- (int) colorDepth
{
	return -1;
}

- (void) setColorDepth: (int)colorDepth
{

}

- (int) contrast
{
	return -1;
}

- (void) setContrast
{

}

- (int) brightness
{
	return -1;
}

- (void) setBrightness: (int)brightness
{

}

- (SCRefreshRate) refreshRate
{
	SCRefreshRate rate = {0, 0};
	
	return rate;
}

- (void) setRefreshRate: (SCRefreshRate)rate
{

}

@end
