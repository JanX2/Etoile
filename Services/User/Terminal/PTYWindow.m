/* -*- mode:objc -*- */
/* $Id: PTYWindow.m,v 1.8 2006/02/12 17:51:40 ujwal Exp $ */
/* Incorporated into iTerm.app by Ujwal S. Setlur */
/*
 **  PTYWindow.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian, Ujwal S. Setlur
 **	     Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: NSWindow subclass. Implements transparency.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */


#import <iTerm/PTYWindow.h>
#import <iTerm/PreferencePanel.h>

#define DEBUG_METHOD_TRACE	0
#define DEBUG_METHOD_ALLOC	0

@implementation PTYWindow

- (void) dealloc
{
#if DEBUG_METHOD_ALLOC
    NSLog(@"%s(%d):+[PTYWindow dealloc]",
          __FILE__, __LINE__);
#endif

    [super dealloc];
    
}

- initWithContentRect:(NSRect)contentRect
	    styleMask:(unsigned int)aStyle
	      backing:(NSBackingStoreType)bufferingType 
		defer:(BOOL)flag
{
#if DEBUG_METHOD_ALLOC
    NSLog(@"%s(%d):-[PTYWindow initWithContentRect]",
          __FILE__, __LINE__);
#endif

    if ((self = [super initWithContentRect:contentRect
				 styleMask:aStyle
				   backing:bufferingType 
				     defer:flag])
	!= nil) 
    {
		[self setAlphaValue:0.9999];
    }
    return self;
}

- (void)toggleToolbarShown:(id)sender
{
#if DEBUG_METHOD_TRACE
    NSLog(@"%s(%d):-[PTYWindow toggleToolbarShown]",
          __FILE__, __LINE__);
#endif
    id delegate = [self delegate];

    // Let our delegate know
    if([delegate conformsToProtocol: @protocol(PTYWindowDelegateProtocol)])
	[delegate windowWillToggleToolbarVisibility: self];
    
    [super toggleToolbarShown: sender];

    // Let our delegate know
    if([delegate conformsToProtocol: @protocol(PTYWindowDelegateProtocol)])
	[delegate windowDidToggleToolbarVisibility: self];    
    
}

- (NSDrawer *) drawer
{
	return (drawer);
}

- (void)sendEvent:(NSEvent *)event
{
	//NSLog(@"%s: 0x%x", __PRETTY_FUNCTION__, self);
	
	if([event type] == NSMouseEntered)
	{
		if([[PreferencePanel sharedInstance] focusFollowsMouse])
			[self makeKeyWindow];
	}
	else if([event type] == NSMouseExited)
	{
		// no-op
	}
	else	
		[super sendEvent:event];
}

@end
