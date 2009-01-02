/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "SHServer.h"
#import "GNUstep.h"
#import "shttpd/shttpd.h"

#define CTX (struct shttpd_ctx *)ctx

void shttpd_handler(struct shttpd_arg *arg)
{
    int n = 0; 
	SHServer *server = arg->user_data;
	id observer = nil, plist = nil;
#if 0
    int     *p = arg->user_data;    /* integer passed to us */
    FILE        *fp;
    const char  *value, *fname, *data, *host, *addr;

    /* Change the value of integer variable */
    if ((value = shttpd_get_var(arg, "name1")) != NULL)
        *p = atoi(value);
#endif
	NSString *uri = [NSString stringWithUTF8String: 
	                        shttpd_get_env(arg, "REQUEST_URI")];
	NSLog(@"Server uri: %@", uri);
	observer = [server observerForURLPath: uri];
	if ([observer respondsToSelector: @selector(server:propertyListForURLPath:)])
	{
		plist = [observer server: server propertyListForURLPath: uri];
	}
	if (plist)
	{
		NSString *string = nil, *error = nil;;
		NSData *data = [NSPropertyListSerialization dataFromPropertyList: plist
		                          format: NSPropertyListXMLFormat_v1_0
		                          errorDescription: &error];
		if (data)
		{
			string = [[NSString alloc] initWithData: data
			                           encoding: NSUTF8StringEncoding];
			AUTORELEASE(string);
		}
		else
		{
			NSLog(@"Cannot get data: %@", error);
		}
	    n += snprintf(arg->out.buf + n, arg->out.len - n, "%s",
	        "HTTP/1.1 200 OK\r\n"
	        "Content-Type: text/html\r\n\r\n");
		if (string)
		{
		    n += snprintf(arg->out.buf + n, arg->out.len - n, 
		              "%s", [string UTF8String]);
		}
		else if (plist)
		{
		    n += snprintf(arg->out.buf + n, arg->out.len - n, 
		              "<html><body><pre>%s</pre></body></html>", 
			          [[plist description] UTF8String]);
		}
// 	   n += snprintf(arg->out.buf + n, arg->out.len - n, "");
	}
	else
	{
	    n += snprintf(arg->out.buf + n, arg->out.len - n, "%s",
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/html\r\n\r\n<html><body>");
	    n += snprintf(arg->out.buf + n, arg->out.len - n, "<h1>Welcome to embedded"
        " example of SHTTPD v. %s </h1>", shttpd_version());
	    n += snprintf(arg->out.buf + n, arg->out.len - n, 
	     "<p>REQUEST_METHOD: %s </p>", 
	     shttpd_get_env(arg, "REQUEST_METHOD"));
	    n += snprintf(arg->out.buf + n, arg->out.len - n, 
	     "<p>REQUEST_URI: %s </p>", 
	     shttpd_get_env(arg, "REQUEST_URI"));
	    n += snprintf(arg->out.buf + n, arg->out.len - n, "</body></html>");
	}
	arg->out.num_bytes = n;
    
    arg->flags = SHTTPD_END_OF_OUTPUT;
}

@implementation SHServer

/* Not in thread */
- (void) shttpdPoll: (id) sender
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
	shttpd_poll(CTX, 100);
}

/* In thread */
- (void) startThread: (id) arg
{
	CREATE_AUTORELEASE_POOL(x);
	while (inThread)
	{
		shttpd_poll(CTX, 1000);
	}
	DESTROY(x);
}

- (void) addObserver: (id) observer URLPath: (NSString *) uri
{
	[registry setObject: observer forKey: uri];
}

- (void) removeObserver: (id) observer
{
	NSArray *array = AUTORELEASE([[registry allKeys] copy]);
	NSEnumerator *e = [array objectEnumerator];
	NSString *key = nil;
	while ((key = [e nextObject]))
	{
		id object = [registry objectForKey: key];
		if (observer == object)
		{
			[registry removeObjectForKey: key];
		}
	}
}

- (void) removeObserverForURLPath: (NSString *) uri
{
	[registry removeObjectForKey: uri];
}

- (id) observerForURLPath: (NSString *) uri
{
	return [registry objectForKey: uri];
}

- (id) init
{
	self = [super init];
	ctx = NULL;
	isRunning = NO;
	inThread = NO;
	registry = [[NSMutableDictionary alloc] init];
	nc = [NSNotificationCenter defaultCenter];
	return self;
}

- (id) initWithProtocol: (NSString *) s name: (NSString *) n port: (int) p

{
	self = [self init];
	ctx = shttpd_init(NULL, "listen_ports", "8880s", "ssl_certificate", "/Users/yjchen/koelr/ShareKit/shttpd/shttpd.pem", NULL);
	[self setPort: p];
	[self setProtocol: s];
	[self setName: n];
	netService = [[NSNetService alloc] initWithDomain: @"local."
                       type: [NSString stringWithFormat: @"_%@._tcp", protocol]
	                   name: name
	                   port: port];
	return self;
}

- (void) dealloc
{
	[self stop];
	if (CTX != NULL)
	{
		shttpd_fini(CTX);
		ctx = NULL;
	}
	DESTROY(registry);
	DESTROY(netService);
	DESTROY(protocol);
	DESTROY(name);
	[super dealloc];
}

/* Return YES for success, NO for failure */
- (BOOL) startInThread: (BOOL) flag
{
	int socket;

	/* No port */
	if (port == 0)
		return NO;

	/* register uri */
	NSEnumerator *e = [[registry allKeys] objectEnumerator];
	NSString *uri = nil;
	while ((uri = [e nextObject]))
	{
		shttpd_register_uri(CTX, [uri UTF8String], shttpd_handler, self);
	}

	socket = shttpd_listen(CTX, port, NO);
	if (socket == -1)
	{
		NSLog(@"Cannot open socket at %d", port);
	}

	if (flag == YES)
	{
		inThread = YES;
		[NSThread detachNewThreadSelector: @selector(startThread:)
		          toTarget: self
		          withObject: nil];
	}
	else
	{
		ASSIGN(timer, [NSTimer scheduledTimerWithTimeInterval: 1
	                       target: self
	                       selector: @selector(shttpdPoll:)
	                       userInfo: nil
	                       repeats: YES]);
	}

	[netService publish];

	isRunning = YES;
	return YES;
}

- (BOOL) stop;
{
	if (inThread == YES)
	{
		inThread = NO;
	}

	if (timer)
	{
		[timer invalidate];
		DESTROY(timer);
	}
	isRunning = NO;
	return YES;
}

- (BOOL) isRunning
{
	return isRunning;
}

- (void) setPort: (int) p
{
	port = p;
}

- (int) port
{
	return port;
}

- (void) setProtocol: (NSString *) s
{
	ASSIGN(protocol, s);
}

- (NSString *) protocol
{
	return protocol;
}

- (void) setName: (NSString *) n
{
	ASSIGN(name, n);
}

- (NSString *) name
{
	return name;
}

@end

