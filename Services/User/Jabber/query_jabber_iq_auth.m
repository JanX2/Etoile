//
//  query_jabber_iq_auth.m
//  Jabber
//
//  Created by David Chisnall on Thu Apr 22 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

// NOTE:  This class is quite untidy.

//NOTE: This class is not used in newer versions, which support SASL auth.  Anyone wishing to re-add non-SASL auth support should use this as a starting point.

#import "query_jabber_iq_auth.h"
#include <openssl/sha.h>

@implementation query_jabber_iq_auth
+ (id) queryWithUsername: (NSString*) username password:(NSString*) password resource: (NSString*) resource
{
	return [[[self alloc] initWithUsername:username password:password resource:resource] autorelease];
}

- (id) initWithUsername: (NSString*) username password:(NSString*) password resource: (NSString*) resource
{
	user = [username retain];
	pass = [password retain];
	res = [resource retain];
	return [self init];
}

- (id) init
{
	nodeType = @"query";
	return [super init];
}

- (NSString*) toXML:(NSDictionary *)flags
{
	if([[flags valueForKey:@"authtype"] isEqualToString:@"plain"])
	{
		NSString * XML;
		XML = [NSString stringWithFormat:@"\t<query xmlns=\"jabber:iq:auth\">\n\t\t<username>%@</username>\n\t\t<password>%@</password>\n\t\t<resource>%@</resource>\n\t</query>\n",user,pass,res];
		return XML;		
	}
	else
	{
		NSString * sessionPassword = [sessionID stringByAppendingString:pass];
		NSString * XML;
		NSString * digest;
		unsigned char hash[20];

		SHA1((unsigned char*)[sessionPassword UTF8String], [sessionPassword length], hash);
		digest = [NSString stringWithFormat:@"%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x",
				hash[0],
				hash[1],
				hash[2],
				hash[3],
				hash[4],
				hash[5],
				hash[6],
				hash[7],
				hash[8],
				hash[9],
				hash[10],
				hash[11],
				hash[12],
				hash[13],
				hash[14],
				hash[15],
				hash[16],
				hash[17],
				hash[18],
				hash[19]];		
		XML = [NSString stringWithFormat:@"\t<query xmlns=\"jabber:iq:auth\">\n\t\t<username>%@</username>\n\t\t<digest>%@</digest>\n\t\t<resource>%@</resource>\n\t</query>\n",user,digest,res];
		return XML;		
	}
}

- (void) setSessionID:(NSString*) streamID
{
	[sessionID release];
	sessionID = [streamID retain];
}

- (void) dealloc
{
	[user release];
	[pass release];
	[res release];
	[sessionID release];
	[super dealloc];
}

@end
