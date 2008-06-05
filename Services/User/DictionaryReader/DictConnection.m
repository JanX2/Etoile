/* -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "DictConnection.h"
#import "GNUstep.h"
#import "NSString+Clickable.h"
#import "NSString+DictLineParsing.h"

// easier logging
#define LOG(format, args...) \
	[self log: [NSString stringWithFormat: format, ##args]];

@interface DictConnection (Private)
- (void) sendClientString: (NSString *) clientName;
@end

@implementation DictConnection


/**
 * Initialises the DictionaryHandle from the property list aPropertyList.
 */
- (id) initFromPropertyList: (NSDictionary *) aPropertyList
{
	NSAssert1([aPropertyList objectForKey: @"host"] != nil,
	          @"No entry for 'host' key in NSDictionary %@", aPropertyList);
	NSAssert1([aPropertyList objectForKey: @"port"] != nil,
	          @"No entry for 'host' key in NSDictionary %@", aPropertyList);
    
	if ((self = [super initFromPropertyList: aPropertyList]) != nil) 
	{
		NSHost *ahost = [NSHost hostWithName: [aPropertyList objectForKey: @"host"]];
		self = [self initWithHost: ahost
		             port: [[aPropertyList objectForKey: @"port"] intValue]];
	}
    
	return self;
}

- (id) initWithHost: (NSHost *) aHost port: (int) aPort
{
	if ((self = [super init]) != nil) 
	{
		if (aHost == nil) 
		{
			[self dealloc];
			self = nil;
			return nil;
		}
    
		ASSIGN(host, aHost);
		port = aPort;
    
		reader = nil;
		writer = nil;
		inputStream = nil;
		outputStream = nil;
	}
  
	return self;
}

- (id) initWithHost: (NSHost *) aHost
{
	return [self initWithHost: aHost port: 2628];
}

- (id) initWithDefaultHost
{
	NSString *hostname = nil;
  
	hostname = [[NSUserDefaults standardUserDefaults] objectForKey: @"Dict Server"];
  
	if (hostname == nil)
		hostname = @"dict.org";
  
	return [self initWithHost: [NSHost hostWithName: hostname]];
}

- (void) dealloc
{
	// first close connection, if open
	[self close];
  
	// NOTE: inputStream, outputStream, reader and writer are released in -close
	DESTROY(host);
  
	[super dealloc];
}

/** To know whether two remote dictionaries are equal we check if they have the
	the same host. */
- (unsigned long) hash
{
	return [host hash] ^ port;
}

- (BOOL) isEqual: (id) object
{
	if ([object isKindOfClass: [self class]])
	{
		DictConnection *conn = (DictConnection *) object;
		if (([[self host] isEqualToHost: [conn host]]) &&
		    ([self port] == [conn port]))
		{
			return YES;
		}
	}

	return NO;
}

- (NSHost *) host
{
	return host;
}

- (int) port
{
	return port;
}

- (void) handleDescription
{
	[self showError: @"Retrieval of server descriptions not implemented yet."];
}
  
- (void) descriptionForDatabase: (NSString*) aDatabase
{
	[self showError: @"Database description retrieval not implemented yet."];
}

- (NSArray *) definitionsFor: (NSString*) aWord 
                inDictionary: (NSString*) aDict
                       error: (NSString **) error
{
	[writer writeLine: [NSString stringWithFormat: @"define %@ \"%@\"\r\n",
		      aDict, aWord]];
  
	NSString *answer = [reader readLineAndRetry];
  
	if ([answer hasPrefix: @"552"]) 
	{ // word not found
		if (error)
			*error = [NSString stringWithFormat: @"No results from %@", self];
		return nil;
	}
	else if ([answer hasPrefix: @"550"]) 
	{
		if (error)
			*error = [NSString stringWithFormat: @"Invalid database: %@", aDict];
		return nil;
	}
	else if ([answer hasPrefix: @"150"]) 
	{ // got results
		BOOL lastDefinition = NO;
		NSMutableArray *result = [[NSMutableArray alloc] init];
		do {
			answer = [reader readLineAndRetry];
			if ([answer hasPrefix: @"151"]) 
			{
				Definition *def = [[Definition alloc] init];
				[def setDatabase: 
					[NSString stringWithFormat: @"From %@:",
						[answer dictLineComponent: 3]]
				];
	
				// TODO: Extract database information here!
				//[defWriter writeHeadline: [answer substringFromIndex: 4]];
	
				BOOL lastLine = NO;
				NSMutableString *ms = [[NSMutableString alloc] init];
				do {
					answer = [reader readLineAndRetry];
					if ([answer isEqualToString: @"."]) 
					{
						lastLine = YES;
					}
					else
					{ // wow, actual text! ^^
						[ms appendString: answer];
						[ms appendString: @"\n"];
					}
				} while (lastLine == NO);
				[def setDefinition: ms];
				[result addObject: def];
				DESTROY(ms);
				DESTROY(def);
			}
			else 
			{
				lastDefinition = YES;
				if (![answer hasPrefix: @"250"]) 
				{
					if (error)
						*error = answer;
					return nil;
				}
			}
		} while (lastDefinition == NO);
		return AUTORELEASE(result);
	}
	return nil;
}

- (NSArray *) definitionsFor: (NSString *) aWord error: (NSString **) error
{
	return [self definitionsFor: aWord inDictionary: @"*" error: error];
}

- (void) open
{
	[NSStream getStreamsToHost: host port: port
	               inputStream: &inputStream outputStream: &outputStream];

	// Streams are returned autoreleased
	RETAIN(inputStream);
	RETAIN(outputStream);
  
	if (inputStream == nil || outputStream == nil) 
	{
		[self log: @"open failed: cannot create input and output stream"];
		return;
	}
  
	[inputStream open];
	[outputStream open];
  
	reader = [[StreamLineReader alloc] initWithInputStream: inputStream];
	writer = [[StreamLineWriter alloc] initWithOutputStream: outputStream];
  
	if (reader == nil || writer == nil) 
	{
		[self log: @"open failed: cannot create reader and writer"];
		return;
	}
  
	// fetch server banner
	NSString* banner = [reader readLineAndRetry];
  
	// interprete server banner
	if ([banner hasPrefix: @"220"]) 
	{
		LOG(@"Server banner: %@", banner);
	}
	else 
	{
		if ([banner hasPrefix: @"530"]) 
		{
			[self showError: @"Access to server denied."];
		}
		else if ([banner hasPrefix: @"420"]) 
		{
			[self showError: @"Temporarily unavailable."];
		}
		else if ([banner hasPrefix: @"421"]) 
		{
			[self showError: @"Server shutting down at operator request."];
		}
		else 
		{
			LOG(@"Bad banner: %@", banner);
		}
	} 
	[self sendClientString: @"GNUstep DictionaryReader.app"];
}

// Probably not true anymore now we check the connection status...
#warning FIXME: Crashes sometimes?
- (void) close
{
	if ((inputStream != nil) &&
	    ([inputStream streamStatus] != NSStreamStatusNotOpen) &&
	    ([inputStream streamStatus] != NSStreamStatusClosed))
	{
		[inputStream close];
	}
	DESTROY(inputStream);

	if ((outputStream != nil) &&
	    ([outputStream streamStatus] != NSStreamStatusNotOpen) &&
	    ([outputStream streamStatus] != NSStreamStatusClosed))
	{
		[outputStream close];
	}
	DESTROY(outputStream);
  
	DESTROY(reader);
	DESTROY(writer);
}

- (NSDictionary *) shortPropertyList
{
	NSMutableDictionary* result = [[super shortPropertyList] mutableCopy];

	[result setObject: [host name] forKey: @"host"];
	[result setObject: [NSNumber numberWithInt: port] forKey: @"port"];
    
	return result;
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"Dictionary at %@", [host name]];
}

@end

@implementation DictConnection (Private)
- (void) sendClientString: (NSString *) clientName
{
	LOG(@"Sending client String: %@", clientName);
  
	[writer writeLine: [NSString stringWithFormat: @"client \"%@\"\r\n", clientName]];
  
	NSString* answer = [reader readLineAndRetry];
  
	if (![answer hasPrefix: @"250"]) 
	{
		LOG(@"Answer not accepted?: %@", answer);
	}
}
@end

