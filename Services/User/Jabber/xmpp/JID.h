//
//  JID.h
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {invalidJID = 0, serverJID, serverResourceJID, userJID, resourceJID} JIDType;

@interface JID : NSObject {
	JIDType type;
	NSString * user;
	NSString * server;
	NSString * resource;
	NSString * stringRepresentation;
	NSString * stringRepresentationWithNoResource;
}
+ (id) jidWithString:(NSString*)_jid;
+ (id) jidWithJID:(JID*)_jid;
- (id) initWithJID:(JID*)_jid;
- (id) initWithString:(NSString*)_jid;
- (JIDType) type;
- (NSComparisonResult) compare:(JID*)_other;
- (NSComparisonResult) compareWithNoResource:(JID*)_other;
- (BOOL) isEqualToJID:(JID*)aJID;
- (JID*) rootJID;
- (NSString*) jidString;
- (NSString*) jidStringWithNoResource;
- (NSString*) node;
- (NSString*) domain;
- (NSString*) resource;
@end
