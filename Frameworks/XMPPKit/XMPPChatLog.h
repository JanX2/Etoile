//
//  XMPPChatLog.h
//  Jabber
//
//  Created by David Chisnall on 25/11/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "JID.h"
#import "XMPPMessage.h"
#import "XMPPPerson.h"
/**
 * A class encapsulating the log of an XMPP chat.  The current implementation
 * logs to a series of RTF files (one per day per user) in a directory structure
 * that mimics the roster.
 *
*/
@interface XMPPChatLog : NSObject {
	BOOL isXML;
	id log;
	NSCalendarDate * today;
	XMPPPerson * remoteEntity;
	NSString * logFileName;
	NSTimer * autoSaveTimer;
}

/**
 * Sets the base path in which log files are created.  
 * This method should not be called after the creation of any 
 * XMPPChatLog objects.  The behaviour in this case is undefined.  
*/
+ (void) setLogBasePath:(NSString*)aPath;

/**
 * Returns a XMPPChatLog for the specified person.
 */
+ (id) chatLogWithPerson:(XMPPPerson*)aPerson;
/**
 * Initialises the chat log for a specific person.
 */
- (id) initWithPerson:(XMPPPerson*)aPerson;
/**
 * Logs the given message.
 */
- (id) logMessage:(XMPPMessage*) aMessage;
/**
 * Returns the root path from which all logs will be stored.
 */
+ (NSString*) logPath;
/**
 * Forces the log to be flushed to disk.  If not called, the log will be flushed
 * periodically.
 */
- (BOOL) save;
/**
 * Returns a copy of the log for today.  Used typically for a client to re-load 
 * previous conversations from the same day after exiting.
 */
- (id) getLogForToday;
@end
