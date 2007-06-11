/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#ifndef _DICTCONNECTION_H_
#define _DICTCONNECTION_H_

#import <Foundation/Foundation.h>
#import "StreamLineReader.h"
#import "StreamLineWriter.h"
#import "NSString+Convenience.h"
#import "DefinitionWriter.h"
#import "DictionaryHandle.h"

/**
 * Instances of this class enable a connection to a dict protocol server.
 * You can look up words using the @see(definitionFor:) method.
 */
@interface DictConnection : DictionaryHandle
{
  NSInputStream* inputStream;
  NSOutputStream* outputStream;
  StreamLineReader* reader;
  StreamLineWriter* writer;
  NSHost* host;
  int port;
  
  id<DefinitionWriter> defWriter;
}

// Class methods


// Instance methods
-(id)initWithHost: (NSHost*) aHost
	     port: (int) aPort;

-(id)initWithHost: (NSHost*) aHost;

-(NSHost*) host;

-(void) sendClientString: (NSString*) clientName;
-(void) handleDescription;
-(void) descriptionForDatabase: (NSString*) aDatabase;
-(void) definitionFor: (NSString*) aWord;
-(void) definitionFor: (NSString*) aWord
	 inDictionary: (NSString*) aDict;

-(void)open;
-(void)close;

-(void) setDefinitionWriter: (id<DefinitionWriter>) aDefinitionWriter;

@end


@interface DictConnection (Private)

-(void) log: (NSString*) aLogMsg;
-(void) showError: (NSString*) aString;

@end

#endif // _DICTCONNECTION_H_
