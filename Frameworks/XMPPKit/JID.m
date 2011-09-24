//
//  JID.m
//  Jabber
//
//  Created by David Chisnall on Sun Apr 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "JID.h"


@implementation JID
+ (id) jidWithString:(NSString*)aJid
{
	return [[[JID alloc] initWithString:aJid] autorelease];
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

- (id) initWithString:(NSString*)aJid
{
	[self init];
	//JID's are not case sensitive.  This is irritating, but what can you do?
	aJid = [aJid lowercaseString];
	
	NSRange at = [aJid rangeOfString:@"@"];
	NSRange slash = [aJid rangeOfString:@"/"];
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
			server = [aJid retain];
		}
		else
		{
			type = serverResourceJID;
			server = [[aJid substringToIndex:slash.location] retain];
			resource = [[aJid substringFromIndex:slash.location + 1] retain];
		}
	}
	else
	{
		user = [[aJid substringToIndex:at.location] retain];
		if(slash.location == NSNotFound)
		{
			type = userJID;
			server = [[aJid substringFromIndex:at.location + 1] retain];
		}
		else
		{
			type = resourceJID;
			at.location++;
			at.length = slash.location - at.location;
			server = [[aJid substringWithRange:at] retain];
			resource = [[aJid substringFromIndex:slash.location + 1] retain];
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

- (NSComparisonResult) compare:(JID*)anAnotherJid
{
	return [stringRepresentation compare:[anAnotherJid getJIDString]];
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
- (NSUInteger) hash
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

- (NSComparisonResult) compareWithNoResource:(JID*)anAnotherJid
{
	return [stringRepresentationWithNoResource compare:[anAnotherJid getJIDStringWithNoResource]];
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
