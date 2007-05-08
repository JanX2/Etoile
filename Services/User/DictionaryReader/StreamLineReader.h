/*  -*-objc-*-
 * 
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#ifndef _STREAMLINEREADER_H_
#define _STREAMLINEREADER_H_

#import <Foundation/Foundation.h>

@interface StreamLineReader : NSObject
{
  // Instance variables
  NSInputStream* inputStream;
  uint8_t* delim;
  unsigned delimSize;
  
  uint8_t* strBuf;
  unsigned strBufPos;
  unsigned strBufSize;
}

// Class methods



// Instance methods

-(id)init;
-(id)initWithInputStream: (NSInputStream*) anInputStream;
-(id)initWithInputStream: (NSInputStream*) anInputStream
            andDelimiter: (NSString*) aDelimiter;

-(void)dealloc;

-(NSString*)readLineAndRetry;
-(NSString*)readLine;

-(BOOL) getMoreCharacters;
-(NSString*) extractNextLine;
-(int) delimPosInBuffer;
-(BOOL) canExtractNextLine;


@end

#endif // _STREAMLINEREADER_H_
