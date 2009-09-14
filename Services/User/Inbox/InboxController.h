/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  September 2009
 License: Modified BSD (see COPYING)
 */

#import <EtoileUI/EtoileUI.h>


@interface InboxController : NSObject
{
	ETLayoutItemGroup *main;
	ETLayoutItemGroup *mail;
	ETLayoutItemGroup *news;
}

- (void) applicationDidFinishLaunching: (id)notif;

@end
