/*
    main.m
 
    Etoile System main
 
    Copyright (C) 2006 Quentin Mathe
 
    Author:  Quentin Mathe <qmathe@club-internet.fr>
    Date:  March 2006
 
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
#import "EtoileSystem.h"

int main(int argc, const char * argv[])
{
    NSRunLoop *runLoop = [[NSRunLoop alloc] init];
    NSPort *dummyPort;
    SCSystem *etoileSystem;

    CREATE_AUTORELEASE_POOL (pool);

    etoileSystem = [[SCSystem alloc] init];
	[SCSystem setUpServerInstance: etoileSystem];
    [etoileSystem run];

    /* Adding a dummy port avoids the run loop exits immediately */
    dummyPort = [NSPort port];
    [runLoop addPort: dummyPort forMode: NSDefaultRunLoopMode];
    NSLog(@"Starting Etoile system server run loop");
    [runLoop run];
    NSLog(@"Exiting Etoile system server run loop");

	DESTROY(runLoop);
	DESTROY(etoileSystem);
    DESTROY(pool);

    return 0;
}
