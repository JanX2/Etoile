//
//  XMPPError.h
//  Jabber
//
//  Created by David Chisnall on 26/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TRXMLNullHandler.h"

@interface XMPPError : TRXMLNullHandler {
	int code;
	NSString * type;
	NSString * message;
}
- (NSString*) errorMessage;
- (int) errorCode;
- (NSString*) errorType;
@end
