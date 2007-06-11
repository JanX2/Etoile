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


@implementation DictConnection


/**
 * Initialises the DictionaryHandle from the property list aPropertyList.
 */
-(id) initFromPropertyList: (NSDictionary*) aPropertyList
{
  NSAssert1([aPropertyList objectForKey: @"host"] != nil,
            @"No entry for 'host' key in NSDictionary %@", aPropertyList);
  NSAssert1([aPropertyList objectForKey: @"port"] != nil,
            @"No entry for 'host' key in NSDictionary %@", aPropertyList);
    
  if ((self = [super initFromPropertyList: aPropertyList]) != nil) {
    NSHost *ahost = [NSHost hostWithName: [aPropertyList objectForKey: @"host"]];
    self = [self initWithHost: ahost
                         port: [[aPropertyList objectForKey: @"port"] intValue]];
  }
    
  return self;
}

-(id)initWithHost: (NSHost*) aHost
	     port: (int) aPort
{
  if (self = [super init]) {
    if (aHost == nil) {
        [self release];
        return nil;
    }
    
    ASSIGN(host, aHost);
    port = aPort;
    
    reader = nil;
    writer = nil;
    inputStream = nil;
    outputStream = nil;
    defWriter = nil;
  }
  
  return self;
}

- (id) initWithHost: (NSHost*) aHost
{
  return [self initWithHost: aHost port: 2628];
}

- (id) init
{
  NSString *hostname = nil;
  
  hostname = [[NSUserDefaults standardUserDefaults] objectForKey: @"Dict Server"];
  
  if (hostname == nil)
    hostname = @"dict.org";
  
  return [self initWithHost: [NSHost hostWithName: hostname]];
}

-(void)dealloc
{
  // first close connection, if open
  [self close];
  
  // NOTE: inputStream, outputStream, reader and writer are released in -close
  DESTROY(defWriter);
  DESTROY(host);
  
  [super dealloc];
}

-(void) sendClientString: (NSString*) clientName
{
  LOG(@"Sending client String: %@", clientName);
  
  [writer writeLine:
	    [NSString stringWithFormat: @"client \"%@\"\r\n",
		      clientName]];
  
  NSString* answer = [reader readLineAndRetry];
  
  if (![answer hasPrefix: @"250"]) {
    LOG(@"Answer not accepted?: %@", answer);
  }
}

-(void) handleDescription
{
  [self showError: @"Retrieval of server descriptions not implemented yet."];
}
  
-(void) descriptionForDatabase: (NSString*) aDatabase
{
  [self showError: @"Database description retrieval not implemented yet."];
}

-(void) definitionFor: (NSString*) aWord
         inDictionary: (NSString*) aDict
{
  NSMutableString* result = [NSMutableString stringWithCapacity: 100];
  
  [writer writeLine:
	    [NSString stringWithFormat: @"define %@ \"%@\"\r\n",
		      aDict, aWord]];
  
  
  NSString* answer = [reader readLineAndRetry];
  
  if ([answer hasPrefix: @"552"]) { // word not found
    [defWriter writeHeadline:
		 [NSString stringWithFormat: @"No results from %@", self]];
  } else if ([answer hasPrefix: @"550"]) {
    [self
      showError: [NSString stringWithFormat: @"Invalid database: %@", aDict]];
  } else if ([answer hasPrefix: @"150"]) { // got results
    BOOL lastDefinition = NO;
    do {
      answer = [reader readLineAndRetry];
      if ([answer hasPrefix: @"151"]) {
	[defWriter writeHeadline:
		     [NSString stringWithFormat: @"From %@:",
			       [answer dictLineComponent: 3]]
	 ];
	
	// TODO: Extract database information here!
	//[defWriter writeHeadline: [answer substringFromIndex: 4]];
	
	BOOL lastLine = NO;
	do {
	  answer = [reader readLineAndRetry];
	  if ([answer isEqualToString: @"."]) {
	    lastLine = YES;
	  } else { // wow, actual text! ^^
	    [defWriter writeLine: answer];
	  }
	} while (lastLine == NO);
      } else {
	lastDefinition = YES;
	if (![answer hasPrefix: @"250"]) {
	  [self showError: answer];
	}
      }
    } while (lastDefinition == NO);
  }
}

-(void) definitionFor: (NSString*) aWord
{
  return [self definitionFor: aWord
	       inDictionary: @"*"];
}

-(void)open
{
  [NSStream getStreamsToHost: host
	    port: port
	    inputStream: &inputStream
	    outputStream: &outputStream];

  // Streams are returned autoreleased
  RETAIN(inputStream);
  RETAIN(outputStream);
  
  if (inputStream == nil || outputStream == nil) {
    [self log: @"open failed: cannot create input and output stream"];
    return;
  }
  
  [inputStream open];
  [outputStream open];
  
  reader = [[StreamLineReader alloc] initWithInputStream: inputStream];
  writer = [[StreamLineWriter alloc] initWithOutputStream: outputStream];
  
  if (reader == nil || writer == nil) {
    [self log: @"open failed: cannot create reader and writer"];
    return;
  }
  
  // fetch server banner
  NSString* banner = [reader readLineAndRetry];
  
  
  // interprete server banner
  if ([banner hasPrefix: @"220"]) {
    LOG(@"Server banner: %@", banner);
  } else {
    if ([banner hasPrefix: @"530"]) {
      [self showError: @"Access to server denied."];
    } else if ([banner hasPrefix: @"420"]) {
      [self showError: @"Temporarily unavailable."];
    } else if ([banner hasPrefix: @"421"]) {
      [self showError: @"Server shutting down at operator request."];
    } else {
      LOG(@"Bad banner: %@", banner);
    }
  } 
}

#warning FIXME: Crashes sometimes?
-(void)close
{
  if ([inputStream streamStatus] != NSStreamStatusNotOpen
   && [inputStream streamStatus] != NSStreamStatusClosed)
  {
    [inputStream close];
  }
  DESTROY(inputStream);

  if ([outputStream streamStatus] != NSStreamStatusNotOpen
   && [outputStream streamStatus] != NSStreamStatusClosed)
  {
    [outputStream close];
  }
  DESTROY(outputStream);
  
  DESTROY(reader);
  DESTROY(writer);
}

-(void) log: (NSString*) aLogMsg
{
  NSLog(@"%@", aLogMsg);
}

-(void) showError: (NSString*) aString
{
  [defWriter writeBigHeadline: [NSString stringWithFormat: @"%@ Error", self]];
  [defWriter writeLine: aString];
}

-(void) setDefinitionWriter: (id<DefinitionWriter>) aDefinitionWriter
{
  NSAssert1(aDefinitionWriter != nil,
	    @"-setDefinitionWriter: parameter must not be nil in %@", self);
  ASSIGN(defWriter, aDefinitionWriter);
}

-(NSDictionary*) shortPropertyList
{
    NSMutableDictionary* result = [super shortPropertyList];
    
    [result setObject: [host name] forKey: @"host"];
    [result setObject: [NSNumber numberWithInt: port] forKey: @"port"];
    
    return result;
}

-(NSString*) description
{
  return [NSString stringWithFormat: @"Dictionary at %@", host];
}

@end

