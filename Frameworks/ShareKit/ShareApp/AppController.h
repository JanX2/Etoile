/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <AppKit/AppKit.h>
#import <ShareKit/SHServer.h>
#import <ShareKit/SHClient.h>

@interface AppController: NSObject
{
	IBOutlet id window;
	IBOutlet id textView;
	IBOutlet id textField;
	IBOutlet id goButton;
	SHServer *server;
	SHClient *client;
}

- (IBAction) go: (id) sender;

@end

