/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "SHClient.h"
#import "GNUstep.h"
#import <netinet/in.h>
#import <arpa/inet.h>
#import <curl/curl.h>

NSString *SHClientDidResolveAddressNotification = @"SHClientDidResolveAddressNotification";

@interface SHClient (SHPrivate)
- (void) writeData: (void *) buffer length: (unsigned int) size;
@end

size_t curl_write_data(void *buffer, size_t size, size_t nmemb, void *userp)
{
	NSLog(@"Here");
	NSLog(@"curl_write_data %d %d", size, nmemb);
	SHClient *object = (SHClient *)userp;
	NSLog(@"%@", object);
	[object writeData: buffer length: size*nmemb];
	return size*nmemb;
}

@implementation SHClient
- (void) writeData: (void *) buffer length: (unsigned int) size
{
	NSLog(@"size %d", size);
	if (data == nil)
	{
		ASSIGN(data, [NSMutableData dataWithCapacity: size]);
	}
	[data appendBytes: (const void *) buffer length: size];
}

/* NSNetService delegate */
- (void) netServiceDidResolveAddress: (NSNetService *) ns 
{
	if (ns == netService)
	{
		NSData *address = [[netService addresses] objectAtIndex:0];
		struct sockaddr_in *address_sin = (struct sockaddr_in *)[address bytes];
		struct sockaddr_in6 *address_sin6 = (struct sockaddr_in6 *)[address bytes];
		const char *formatted;
		char buffer[1024];
		in_port_t p = 0;
		if (AF_INET == address_sin->sin_family)
		{
			formatted = inet_ntop(AF_INET, 
		                      &(address_sin->sin_addr), buffer, sizeof(buffer));
			p = ntohs(address_sin->sin_port);
		}
		else if (AF_INET6 == address_sin6->sin6_family)
		{
			formatted = inet_ntop(AF_INET6, &(address_sin6->sin6_addr), buffer, sizeof(buffer));
			p = ntohs(address_sin6->sin6_port);
		}
		else
		{
			/* Something is wrong */
			return;
		}
		[self setHost: [NSString stringWithUTF8String: formatted]];
		[self setPort: p];
		[[NSNotificationCenter defaultCenter] 
		        postNotificationName: SHClientDidResolveAddressNotification
		        object: self];
	}
}

- (void) netService: (NSNetService *) netService
         didNotResolve: (NSDictionary *) errorDict
{
    NSLog(@"%@: %@", NSStringFromSelector(_cmd), errorDict);
}

- (id) initWithProtocol: (NSString *) protocol name: (NSString *) name
{
	NSNetService *ns = [[NSNetService alloc] initWithDomain: @"local."
	           type: [NSString stringWithFormat: @"_%@._tcp", protocol]
	           name: name];
	return [self initWithService: AUTORELEASE(ns)];
}

- (id) initWithService: (NSNetService *) service
{
	self = [self init];

	ASSIGN(netService, service);
	[netService setDelegate: self];

	return self;
}

- (id) initWithHost: (NSString *) h port: (int) p
{
	self = [self init];
	[self setHost: h];
	[self setPort: p];
	return self;
}

- (id) init
{
	self = [super init];
	port = 0;
	host = nil;
	curl = curl_easy_init();
	if (curl == NULL)
	{
		NSLog(@"Cannot get curl instance");
		[self dealloc];
		return nil;
	}
	return self;
}

- (void) dealloc
{
	DESTROY(host);
	DESTROY(netService);
	if (curl)
		curl_easy_cleanup(curl);
	curl = NULL;
	[super dealloc];
}

- (id) propertyListForURLPath: (NSString *) path
{
	NSString *url = [NSString stringWithFormat: @"http://%@:%d%@", host, port, path];
	char error[1024];
	NSLog(@"url %s", [url UTF8String]);
	curl_easy_setopt(curl, CURLOPT_URL, [url UTF8String]);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curl_write_data);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, self);
	curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, error);
	if (data)
	{
		DESTROY(data);
	}
	NSLog(@"Ready to go");
	CURLcode code = curl_easy_perform(curl);
	NSLog(@"Done");
	switch(code)
	{
		case CURLE_OK:
			break;
		default:
			NSLog(@"Curl error %d: %s", code, error);
	}
	if (data)
	{
//		NSLog(@"%@", AUTORELEASE([[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]));
		NSString *error = nil;
		NSPropertyListFormat format = 0;
		id plist = [NSPropertyListSerialization propertyListFromData: data
		              mutabilityOption: NSPropertyListImmutable 
		              format: &format
		              errorDescription: &error];
		if (plist == nil)
		{
			NSLog(@"Cannot get plist from data: %@", error);
		}
		NSLog(@"Format %d", format);
		return plist;
	}
	else
	{
		NSLog(@"No data");
	}
	
	return nil;
}

- (void) resolveAddress
{
	if (netService)
	{
		[netService resolveWithTimeout: 5.0];
	}
}

- (BOOL) isAddressResolved
{
	if ((port == 0) || (host == nil))
		return NO;
	return YES;
}

- (void) setHost: (NSString *) h
{
	ASSIGN(host, h);
}

- (NSString *) host
{
	return host;
}

- (void) setPort: (int) p
{
	port = p;
}

- (int) port
{
	return port;
}

+ (void) initialize
{
	/* Initialize curl. Not way to do curl_global_cleanup() */
	curl_global_init(CURL_GLOBAL_ALL);
}

@end

