//
//  Iq.h
//  Jabber
//
//  Created by David Chisnall on 30/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TRXMLNullHandler.h"
#import "JID.h"

typedef enum {IQ_TYPE_SET,IQ_TYPE_GET,IQ_TYPE_RESULT,IQ_TYPE_ERROR} iq_type_t;
@interface Iq : TRXMLNullHandler {
	iq_type_t type;
	NSString * sequenceID;
	JID * jid;
	NSMutableDictionary * children;
}
- (iq_type_t) type;
- (NSString*) sequenceID;
- (iq_type_t) type;
- (NSDictionary*) children;
- (JID*) jid;
@end
