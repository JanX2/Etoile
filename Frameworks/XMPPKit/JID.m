//
//  JID.m
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "JID.h"


@implementation JID
+ (id) jidWithString:(NSString*)_jid
{
	return [[[JID alloc] initWithString:_jid] autorelease];
} 

+ (id) jidWithJID:(JID*)_jid
{
	return [[[JID alloc] initWithJID:_jid] autorelease];
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (NSString*) getJIDString
{
	switch(type)
	{
		case serverJID:
			return [NSString stringWithString:server];
		case serverResourceJID:
			return [NSString stringWithFormat:@"%@/%@",server,resource];
		case userJID:
			return [NSString stringWithFormat:@"%@@%@",user,server];
		case resourceJID:
			return [NSString stringWithFormat:@"%@@%@/%@",user,server,resource];
		case invalidJID:
			return nil;
	}
	return nil;
}

- (NSString*) getJIDStringWithNoResource
{
	switch(type)
	{
		case serverJID:
		case serverResourceJID:
			return [NSString stringWithString:server];
		case userJID:
		case resourceJID:
			return [NSString stringWithFormat:@"%@@%@",user,server];
		case invalidJID:
			return nil;
	}
	return nil;
}

- (id) initWithJID:(JID*)_jid
{
	self = [self init];
	if(self == nil)
	{
		return nil;
	}
	user = [[_jid node] retain];
	server = [[_jid domain] retain];
	resource = [[_jid resource] retain];
	type = resourceJID;
	if(resource == nil || [resource isEqualToString:@""])
	{
		type = userJID;
	}
	if(user == nil || [user isEqualToString:@""])
	{
		type = serverJID;
	}
	if(server == nil || [server isEqualToString:@""])
	{
		type = invalidJID;
	}
	stringRepresentation = [[self getJIDString] retain];
	stringRepresentationWithNoResource = [[self getJIDStringWithNoResource] retain];
	return self;
}

- (id) init
{
	self  = [super init];
	if(self == nil)
	{
		return nil;
	}
	user = nil;
	server = nil;
	resource = nil;
	stringRepresentation = nil;
	stringRepresentationWithNoResource = nil;
	type = invalidJID;
	return self;
}

- (id) initWithString:(NSString*)_jid
{
	[self init];
	//JID's are not case sensitive.  This is irritating, but what can you do?
	_jid = [_jid lowercaseString];
	
	NSRange at = [_jid rangeOfString:@"@"];
	NSRange slash = [_jid rangeOfString:@"/"];
	[server release];
	[user release];
	[resource release];
	[stringRepresentation release];
	[stringRepresentationWithNoResource release];
		
	if(at.location == NSNotFound)
	{
		type = serverJID;
		if(slash.location == NSNotFound)
		{
			type = serverJID;
			server = [_jid retain];
		}
		else
		{
			type = serverResourceJID;
			server = [[_jid substringToIndex:slash.location] retain];
			resource = [[_jid substringFromIndex:slash.location + 1] retain];
		}
	}
	else
	{
		user = [[_jid substringToIndex:at.location] retain];
		if(slash.location == NSNotFound)
		{
			type = userJID;
			server = [[_jid substringFromIndex:at.location + 1] retain];
		}
		else
		{
			type = resourceJID;
			at.location++;
			at.length = slash.location - at.location;
			server = [[_jid substringWithRange:at] retain];
			resource = [[_jid substringFromIndex:slash.location + 1] retain];
		}
	}
	stringRepresentation = [[self getJIDString] retain];
	stringRepresentationWithNoResource = [[self getJIDStringWithNoResource] retain];
	return self;
}

- (JIDType) type
{
	return type;
}

- (NSComparisonResult) compare:(JID*)_other
{
	return [stringRepresentation compare:[_other getJIDString]];
}

- (BOOL) isEqual:(id)anObject
{
	if([anObject isKindOfClass:[NSString class]])
	{
		return [stringRepresentation isEqualToString:(NSString*)anObject];
	}
	if([anObject isKindOfClass:[JID class]])
	{
		return [self isEqualToJID:(JID*)anObject];
	}
	
	return NO;
}
- (unsigned) hash
{
	return [stringRepresentation hash];
}

- (BOOL) isEqualToJID:(JID*)aJID
{
	//This ought not to work.
	if(type != aJID->type)
	{
		return NO;
	}
	return [stringRepresentation isEqualToString:aJID->stringRepresentation];
}

- (JID*) rootJID
{
	return [JID jidWithString:stringRepresentationWithNoResource];
}

- (NSComparisonResult) compareWithNoResource:(JID*)_other
{
	return [stringRepresentationWithNoResource compare:[_other getJIDStringWithNoResource]];
}

- (NSString*) jidString
{
	return stringRepresentation;
}
- (NSString*) jidStringWithNoResource
{
	return stringRepresentationWithNoResource;
}

- (NSString*) node
{
	return user;
}

- (NSString*) domain
{
	return server;
}

- (NSString*) resource
{
	return resource;
}

- (void) dealloc
{
	[user release];
	[server release];
	[resource release];
	[super dealloc];
}
@end
