//
//  ChatLog.h
//  Jabber
//
//  Created by David Chisnall on 25/11/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "JID.h"
#import "Message.h"
#import "JabberPerson.h"
/*!
@header ChatLog.h
 This file contains the interface to the ChatLog class
*/

/*!
@class ChatLog
@abstract A class encapsulating the log of an XMPP chat.  
@discussion The ChatLog class supports two log formats; an XML format which stores the message in a form identical to that defined by XMPP, and a RTF format, which allows the messages to be easily used in NSText subclasses.
*/
@interface ChatLog : NSObject {
	BOOL isXML;
	id log;
	NSCalendarDate * today;
	JabberPerson * remoteEntity;
	NSString * logFileName;
	NSTimer * autoSaveTimer;
}

/*!
@method setLogBasePath:
 @abstract Sets the base path in which log files are created.  
 @discussion This method should not be called after the creation of any ChatLog objects.  The behaviour in this case is undefined.  
 @param _path The path in which log files are stored.  
*/
+ (void) setLogBasePath:(NSString*)_path;

/*!
@method chatLogWithPerson:withJid:
 @abstract Returns a ChatLog for the specified person.
 @discussion 
 @param _name The roster name of the remote entity.
 @param _jid The JID of the remote entity.
*/
+ (id) chatLogWithPerson:(JabberPerson*)person;
+ (id) chatLogWithPerson:(JabberPerson*)person useXMLFormatLog:(BOOL)_xml;
- (id) initWithPerson:(JabberPerson*)person;
- (id) initWithPerson:(JabberPerson*)person useXMLFormatLog:(BOOL)_xml;
- (id) logMessage:(Message*)_message;
+ (NSString*) logPath;
- (BOOL) isXML;
- (BOOL) save;
- (id) getLogForToday;
@end
