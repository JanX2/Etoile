//
//  XMLLog.h
//  Jabber
//
//  Created by David Chisnall on 12/08/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XMLLog : NSObject {
}
+ (void) logIncomingXML:(NSString*)xml;
+ (void) logOutgoingXML:(NSString*)xml;
@end
