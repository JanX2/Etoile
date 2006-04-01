/*  -*-objc-*-
 *
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

#ifndef _DICTCONNECTION_H_
#define _DICTCONNECTION_H_

#import <Foundation/Foundation.h>
#import "StreamLineReader.h"
#import "StreamLineWriter.h"
#import "NSString+Convenience.h"

@protocol DefinitionWriter

-(void) clearResults;
-(void) writeBigHeadline: (NSString*) aString;
-(void) writeHeadline: (NSString*) aString;
-(void) writeLine: (NSString*) aString;
-(void) writeString: (NSString*) aString
	       link: (id) aClickable;

@end

@interface DictConnection : NSObject
{
  // Instance variables
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

-(id)init;

-(void)dealloc;

-(void) sendClientString: (NSString*) clientName;
-(void) serverDescription;
-(void) descriptionForDatabase: (NSString*) aDatabase;
-(void) definitionFor: (NSString*) aWord;
-(void) definitionFor: (NSString*) aWord
	 inDictionary: (NSString*) aDict;

-(void)open;
-(void)close;

-(void) log: (NSString*) aLogMsg;
-(void) showError: (NSString*) aString;

-(void) setDefinitionWriter: (id<DefinitionWriter>) aDefinitionWriter;

@end

#endif // _DICTCONNECTION_H_
