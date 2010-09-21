/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  September 2009
 License: Modified BSD (see COPYING)
 */
#import "InboxController.h"
#import "ETMailAccount.h"
#import "ETNewsFeed.h"
#import <EtoileUI/EtoileUI.h>

@implementation InboxController

- (void) applicationDidFinishLaunching: (id)notif
{
	ETLayoutItemFactory *factory = [ETLayoutItemFactory factory];
	
	ETMailAccount *account = [[ETMailAccount alloc] init];
	[account setValue: @"*****" forProperty: @"username"];
	[account setValue: @"*****" forProperty: @"password"];
	NSLog(@"---------Setting server");
	[account setValue: @"imap.gmail.com" forProperty: @"server"];
	NSLog(@"---------Account should be set up now");
	
	ETNewsFeed *feed = [[ETNewsFeed alloc] init];
	[feed setValue: @"http://rss.slashdot.org/Slashdot/slashdot" forProperty: @"URL"];
	
	main = [factory itemGroupWithRepresentedObject: A(account, feed)];
	[main setLayout: [ETOutlineLayout layout]];
	[main setSize: NSMakeSize(640, 480)];
	[main setSource: main];
	
	[[factory windowGroup] addItem: main];
	[main inspect: nil];
}

- (void) reload
{
	// hack to reload the mail/news groups
	NSLog(@"reloading...");
	[main reloadAndUpdateLayout];
}
@end
