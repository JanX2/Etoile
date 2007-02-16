//
//  Timestamp.h
//  Jabber
//
//  Created by David Chisnall on 20/08/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRXMLNullHandler.h"

@interface Timestamp : TRXMLNullHandler {
	NSMutableString * reason;
	NSCalendarDate * time;
}
+ (id) timestampWithTime:(NSCalendarDate*)_time reason:(NSString*)_reason;
- (id) initWithTime:(NSCalendarDate*)_time reason:(NSString*)_reason;
- (NSCalendarDate*) time;
- (NSString*) reason;
- (NSString*) stamp;
- (NSComparisonResult) compare:(Timestamp*)_other;
@end
