/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "AppController.h"
#import "GNUstep.h"

static NSString *protocol = @"http";
static NSString *name = @"Cassia";

@implementation AppController
- (id) server: (SHServer *) server propertyListForURLPath: (NSString *) uri
{
	return [NSString stringWithFormat: @"Current Time: %@", [NSDate date]];
}

- (void) clientResolveAddress: (NSNotification *) not
{
	[goButton setEnabled: YES];
}

- (void) go: (id) sender
{
	if ([goButton isEnabled] == NO)
		return;

	NSString *s = [textField stringValue];
	if ((s == nil) || ([s length] == 0))
	{
		s = @"/";
	}
	if ([s hasPrefix: @"/"] == NO)
	{
		s = [NSString stringWithFormat: @"/%@", s];
	}
	id plist = [client propertyListForURLPath: s];
	if (plist)
		[textView setString: [plist description]];
	else
		[textView setString: [NSString stringWithFormat: @"Cannot get property list for %@", s]];
}

- (void) awakeFromNib
{
	/* Disable 'Go' button until we got the server */
	[goButton setEnabled: NO];
}

/* NSApplication */
- (void) applicationWillFinishLaunching: (NSNotification *) not
{
	server = [[SHServer alloc] initWithProtocol: protocol name: name port: 8880];
	[server addObserver: self URLPath: @"/"];
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
	[server startInThread: YES];
	client = [[SHClient alloc] initWithProtocol: protocol name: name];
	[[NSNotificationCenter defaultCenter]
		addObserver: self
		selector: @selector(clientResolveAddress:)
		name: SHClientDidResolveAddressNotification
		object: client];
	[client resolveAddress];
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) app
{
	[server stop];
	DESTROY(server);
	DESTROY(client);
	return NSTerminateNow;
}

- (id) init
{
	self = [super init];
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

@end

