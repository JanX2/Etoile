/*
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "DictConnection.h"
#import "GNUstep.h"

#import "NSString+Clickable.h"


@implementation DictConnection

-(id)initWithHost: (NSHost*) aHost
	     port: (int) aPort
{
  if (self = [super init]) {
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

-(id)initWithHost: (NSHost*) aHost
{
  return [self initWithHost: aHost
	       port: 2628];
}

-(id)init
{
  return [self initWithHost: [NSHost hostWithName: @"dict.org"]];
}

-(void)dealloc
{
  // first close connection, if open
  [self close];
  
  [reader release];
  [writer release];
  [inputStream release];
  [outputStream release];
  [host release];
  
  [super dealloc];
}

-(void) sendClientString: (NSString*) clientName
{
  [self log: @"Sending client String:"];
  [self log: clientName];
  
  [writer writeLine:
	    [NSString stringWithFormat: @"client \"%@\"\r\n",
		      clientName]];
  
  NSString* answer = [reader readLineAndRetry];
  
  if (![answer startsWith: @"250"]) {
    [self log: @"Answer not accepted?:"];
    [self log: answer];
  }
}

-(void) serverDescription
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
  
  if ([answer startsWith: @"552"]) { // word not found
    [defWriter clearResults];
    [defWriter writeHeadline: @"No results"];
  } else if ([answer startsWith: @"550"]) {
    [self
      showError: [NSString stringWithFormat: @"Invalid database: %@", aDict]];
  } else if ([answer startsWith: @"150"]) { // got results
    [defWriter clearResults];
    BOOL lastDefinition = NO;
    do {
      answer = [reader readLineAndRetry];
      if ([answer startsWith: @"151"]) {
	// TODO: Extract database information here!
	[defWriter writeHeadline: answer];
	
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
	if (![answer startsWith: @"250"]) {
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
  if ([banner startsWith: @"220"]) {
    [self log: banner];
  } else {
    if ([banner startsWith: @"530"]) {
      [self showError: @"Access to server denied."];
    } else if ([banner startsWith: @"420"]) {
      [self showError: @"Temporarily unavailable."];
    } else if ([banner startsWith: @"421"]) {
      [self showError: @"Server shutting down at operator request."];
    } else {
      [self log: @"Bad banner:"];
      [self log: banner];
    }
  } 
}

-(void)close
{
  [inputStream close];
  RELEASE(inputStream); inputStream = nil;
  
  [outputStream close];
  RELEASE(outputStream); outputStream = nil;
  
  RELEASE(reader); reader = nil;
  RELEASE(writer); writer = nil;
}

-(void) log: (NSString*) aLogMsg
{
  NSLog(@"%@", aLogMsg);
}

-(void) showError: (NSString*) aString
{
  [defWriter clearResults];
  [defWriter writeBigHeadline: @"Error"];
  [defWriter writeLine: aString];
}

-(void) setDefinitionWriter: (id<DefinitionWriter>) aDefinitionWriter
{
  ASSIGN(defWriter, aDefinitionWriter);
}

@end
