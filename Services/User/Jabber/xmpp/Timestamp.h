//
//  Timestamp.h
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRXMLNullHandler.h"

/**
 * The timestamp class encapsulates an XMPP timestamp of the kind found in the 
 * jabber:x:delay namespace.  This has a time, and a reason for the delay 
 * associated with it.  This class is used to parse such delays from the incoming
 * XML stream.
 */
@interface Timestamp : TRXMLNullHandler {
	NSMutableString * reason;
	NSCalendarDate * time;
}
/**
 * Create a new timestamp with the specified time and excuse.
 */
+ (id) timestampWithTime:(NSCalendarDate*)_time reason:(NSString*)_reason;
/**
 * Initialise a new timestamp with the specified time and excuse.
 */
- (id) initWithTime:(NSCalendarDate*)_time reason:(NSString*)_reason;
/**
 * Returns the time associated with this timestamp.
 */
- (NSCalendarDate*) time;
/**
 * Returns the reason given for the delay (undelayed XMPP items do not get 
 * timestamped; their arrival time is their timestamp).
 */
- (NSString*) reason;
/**
 * Returns a textual representation of the time.
 */
- (NSString*) stamp;
/**
 * Compare two timestamps by their time.
 */
- (NSComparisonResult) compare:(Timestamp*)_other;
@end
