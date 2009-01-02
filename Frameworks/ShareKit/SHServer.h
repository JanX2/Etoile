/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>

@interface SHServer: NSObject
{
	int port;
	NSString *protocol;
	NSString *name;
	void *ctx; /* Hide shttpd structure */
	NSMutableDictionary *registry;
	NSTimer *timer;
	NSNetService *netService;

	NSNotificationCenter *nc;

	BOOL isRunning;
	BOOL inThread;
}

/* protocol is used for _protocol._tcp.local.
   Do not include underscore '_' for protocol. 
   It is appended automatically. */
- (id) initWithProtocol: (NSString *) protocol
               name: (NSString *) name
               port: (int) port;

/* Return YES for success, NO for failure.
   If using client and server in the same application (usually),
   run server in thread and be careful for delegate method. */
- (BOOL) startInThread: (BOOL) flag;
- (BOOL) stop;
- (BOOL) isRunning;

- (void) setPort: (int) port;
- (int) port;

- (void) setProtocol: (NSString *) protocol;
- (NSString *) protocol;

- (void) setName: (NSString *) name;
- (NSString *) name;

/* path starts with '/' */
- (void) addObserver: (id) observer URLPath: (NSString *) path;
- (void) removeObserver: (id) observer;
- (void) removeObserverForURLPath: (NSString *) path;
- (id) observerForURLPath: (NSString *) path;

@end

/* Called if registered */
@interface NSObject (SHServer)
/* Be careful of this if server is running in thread */
- (id) server: (SHServer *) server propertyListForURLPath: (NSString *) path;
@end
