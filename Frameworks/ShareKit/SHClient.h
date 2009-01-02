/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>
#import <curl/curl.h>

extern NSString *SHClientDidResolveAddressNotification;

/* SHClient wrap the curl to retrive property list from SHServer.
   It does not handle browsing. Use NSNetServiceBrowser instead. */
@interface SHClient: NSObject
{
	NSString *host;
	int port;
	NSNetService *netService;
	CURL *curl;

	NSMutableData *data;
}

- (id) initWithProtocol: (NSString *) protocol name: (NSString *) name;
- (id) initWithService: (NSNetService *) service;
- (id) initWithHost: (NSString *) host port: (int) port;

- (id) propertyListForURLPath: (NSString *) path;

/* Ask on-demand. Listen to SHClientDidResolveAddressNotification */
- (void) resolveAddress;
- (BOOL) isAddressResolved;

- (void) setHost: (NSString *) host;
- (NSString *) host;

- (void) setPort: (int) port;
- (int) port;

@end

