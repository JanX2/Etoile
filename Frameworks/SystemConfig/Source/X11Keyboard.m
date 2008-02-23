/*
	X11Keyboard.m
 
	SCKeyboard implementation for X11.
 
	Copyright (C) 2007 N.H. Koh
 
	Author:  N.H. Koh <nyaphong AT gmail DOT com>
	Date:  November 2007
	
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

#import <X11/Xlib.h>
#import <X11/XKBlib.h>
#import "SCConfig+Private.h"
#import "X11Keyboard.h"

// Overwrite the default implementation
@interface SCKeyboard (X11Keyboard)
+(SCConfigElement*) sharedInstance;
@end

@implementation SCKeyboard (X11Keyboard)
+(SCConfigElement*) sharedInstance
{
	return AUTORELEASE([[X11Keyboard alloc] init]);
}
@end

@implementation X11Keyboard
- (id) init 
{	
	//compile time lib major version in, server major version out
	int major_in_out = XkbMajorVersion;
	
	//compile time lib minor version in, server minor version out
	int minor_in_out = XkbMinorVersion;
	//backfilled with the extension base event code
	int event_rtrn = 0;
	//backfilled with the extension base error code
	int error_rtrn = 0;
	//backfilled with a status code
	int reason_rtrn = 0;
	
	if ((self = [super init]) != nil)
	{
		// Or should use GNUstep function to return display? 
		display = XkbOpenDisplay(NULL, &event_rtrn, &error_rtrn, &major_in_out, &minor_in_out, &reason_rtrn);
		if (reason_rtrn != 0) 
		{
			// notify the error. TODO: returning the Xkb status code might be helpful. 
			[self notifyErrorCode: SCKeyboardXkbOpenDisplayFailure
		          	  description: _(@"X11 Keyboard open display failed.")];
		}
	}
	return self;
}


/* To control keyboard layout */

- (SCKeyboardModel *) keyboardModel
{
	return nil;
}

- (void) setKeyboardModel: (SCKeyboardModel *)model
{

}

/* Key repetition methods */

- (int) delayUntilKeyRepeat
{
	
	//Get the state of the keyboard.
	unsigned short delayInterval = -1;
    	XkbDescPtr xkb; 

	xkb = XkbGetMap(display, 0, XkbUseCoreKbd);
    	
	if (xkb == NULL)
      	{
		// notify the error. TODO: returning the Xkb status code might be helpful. 
		[self notifyErrorCode: SCKeyboardXkbOpenDisplayFailure
		          description:_(@"X11 Keyboard open display failed.")];
		return -1;	
	}

	if (Success == XkbGetControls(display,XkbRepeatKeysMask,xkb))
	{
		delayInterval =  xkb->ctrls->repeat_delay;
	}	

  	XkbFreeKeyboard(xkb,XkbRepeatKeysMask,True);
	return delayInterval;

}

- (void) setDelayUntilKeyRepeat: (int)time
{
	// initialize the delayInterval with the value passed in
	unsigned short delayInterval = time;
    	XkbDescPtr xkb; 


	xkb= XkbGetMap(display, 0, XkbUseCoreKbd);
    	
	if (xkb == NULL)
      	{
		// notify the error. TODO: returning the Xkb status code might be helpful. 
		[self notifyErrorCode: SCKeyboardXkbOpenDisplayFailure
		          description: _(@"X11 Keyboard open display failed.")];
		return;	
	}
	
	XkbGetControls(display,XkbRepeatKeysMask,xkb);
	xkb->ctrls->repeat_delay = delayInterval;

	if (Success !=  XkbSetControls(display,XkbRepeatKeysMask,xkb))
	{
	  // notify the error. TODO: returning the Xkb status code might be helpful. 
	  [self notifyErrorCode: SCKeyboardXkbSetControlsFailure
		    description: _(@"Key delay interval change failed.")];
	  return;	
	}
}

// NOTE: keyRepeatRate could be a more appropriate choice.
- (int) keyRepeatInterval
{
	//Get the state of the keyboard.
	unsigned short repeatInterval = -1;
    	XkbDescPtr xkb; 

	xkb= XkbGetMap(display, 0, XkbUseCoreKbd);
    	
	if (xkb == NULL)
      	{
		// notify the error. TODO: returning the Xkb status code might be helpful. 
		[self notifyErrorCode: SCKeyboardXkbOpenDisplayFailure
		          description: _(@"X11 Keyboard open display failed.")];
		return -1;	
	}

	if (Success == XkbGetControls(display,XkbRepeatKeysMask,xkb))
	{
		repeatInterval =  xkb->ctrls->repeat_interval;
	}	

  	XkbFreeKeyboard(xkb,XkbRepeatKeysMask,True);
	return repeatInterval;
}

- (void) setKeyRepeatInterval: (int)time
{
	// initialize the repeatInterval with the value passed in
	unsigned short repeatInterval = time;
    	XkbDescPtr xkb; 


	xkb = XkbGetMap(display, 0, XkbUseCoreKbd);
    	
	if (xkb == NULL)
      	{
		// notify the error. TODO: returning the Xkb status code might be helpful. 
		[self notifyErrorCode: SCKeyboardXkbOpenDisplayFailure
		          description: _(@"X11 Keyboard open display failed.")];
		return;	
	}
	
	XkbGetControls(display,XkbRepeatKeysMask,xkb);
	xkb->ctrls->repeat_interval = repeatInterval;

	if (Success !=  XkbSetControls(display,XkbRepeatKeysMask,xkb))
	{
	  // notify the error. TODO: returning the Xkb status code might be helpful. 
	  [self notifyErrorCode: SCKeyboardXkbSetControlsFailure
		    description: _(@"Key repeat interval changed failed.")];
	  return;	
	}
}

-(BOOL) isRepeatKeyEnabled
{
	BOOL repeatKeyEnabled = NO;
	
	// Wrong implementation, kept for futher study as it might useful 
	//unsigned int timeout_rtrn;
	//unsigned int interval_rtrn;
	
	//repeatKeyEnabled = XkbGetAutoRepeatRate(display, XkbUseCoreKbd, &timeout_rtrn, &interval_rtrn);
	//NSLog(@"Timeout: %d, Interval: %d", timeout_rtrn, interval_rtrn);
	
	//BOOL detactableAutoRepeat = NO;
	//second try also failed
	//Bool d = True;
	//detactableAutoRepeat = d;
	//NSLog(@"%i, %i", detactableAutoRepeat, d );
		
	//XkbGetDetectableAutoRepeat(display, &d);
	// detactableAutoRepeat = d;
    	XkbDescPtr xkb; 
	xkb= XkbGetMap(display, 0, XkbUseCoreKbd);
    	
	if (xkb == NULL)
      	{
		// notify the error. TODO: returning the Xkb status code might be helpful. 
		[self notifyErrorCode: SCKeyboardXkbSetControlsFailure
		          description: _(@"X11 Keyboard open display failed.")];
		return NO;	
	}
	XkbGetControls(display, XkbControlsEnabledMask, xkb);

	// NSLog(@"Enabled: %i, RepeatKeyMask: %i", xkb->ctrls->enabled_ctrls, XkbRepeatKeysMask); 
 	if (XkbRepeatKeysMask == (xkb->ctrls->enabled_ctrls & XkbRepeatKeysMask))
	{
		repeatKeyEnabled = YES;
	}
	else
	{
		repeatKeyEnabled = NO;
	}

 	return repeatKeyEnabled;
}

-(void) enableRepeatKey:(BOOL)enabled
{
	int value = 0;
	if (enabled) 
	{
		value = 1;
	}
      	
	if (!XkbChangeEnabledControls(display, XkbUseCoreKbd, XkbRepeatKeysMask, value))
	{
		[self notifyErrorCode: SCKeyboardXkbSetControlsFailure
		          description: @"X11 Keyboard change repeat enabled mask failed."];
		return;	
	}
	  
} 

@end

