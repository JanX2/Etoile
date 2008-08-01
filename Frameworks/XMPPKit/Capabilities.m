//
//  Capabilities.m
//  Jabber
//
//  Created by David Chisnall on 08/05/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "Capabilities.h"
#include "Macros.h"

@implementation DiscoIdentity
+ (DiscoIdentity*) identityWithCategory:(NSString*)aCategory
									type:(NSString*)aType
									name:(NSString*)aName
{
	return [[[DiscoIdentity alloc] initWithCategory:aCategory type:aType name:aName] autorelease];
}

- (DiscoIdentity*) initWithCategory:(NSString*)aCategory
								type:(NSString*)aType
								name:(NSString*)aName
{
	SELFINIT
	
	category = [aCategory retain];
	type = [aType retain];
	name = [aName retain];
	
	return self;
}

+ (DiscoIdentity*) identityWithXML:(ETXMLNode*)xml
{
	return [[[DiscoIdentity alloc] initWithXML:xml] autorelease];
}

- (DiscoIdentity*) initWithXML:(ETXMLNode*)xml
{
	if(![[xml getType] isEqualToString:@"identity"])
	{
		return nil;
	}
	type = [xml get:@"type"];
	name = [xml get:@"name"];
	category = [xml get:@"category"];
	if((type == nil) || (name == nil) || (category == nil))
	{
		return nil;
	}
	[type retain];
	[name retain];
	[category retain];
	return self;
}

- (NSString*) category
{
	return category;
}
- (NSString*) type
{
	return type;
}
- (NSString*) name
{
	return name;
}
- (ETXMLNode*) toXML
{
	return [ETXMLNode ETXMLNodeWithType:@"identity"
							 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
								 category, @"category",
								 type, @"type",
								 name, @"name",
								 nil]];
}
@end


@implementation DiscoNode

+ (DiscoNode*) discoNodeWithJID:(JID*)aJID
						   node:(NSString*)aNode
					 identities:(NSSet*)anIdentities
					   features:(NSSet*)aFeatures
{
	 return [[[DiscoNode alloc] initWithJID:aJID
									   node:aNode
								 identities:anIdentities
								   features:aFeatures] autorelease];
}
- (DiscoNode*) initWithJID:(JID*)aJID
					  node:(NSString*)aNode
				identities:(NSSet*)anIdentities
				  features:(NSSet*)aFeatures
{
	if((self = [self init]) == nil)
	{
		return nil;
	}

	jid = [aJID retain];
	node = [aNode retain];
	identities = [anIdentities retain];
	features = [aFeatures retain];
	
	return self;
}

+ (DiscoNode*) discoNodeFromXML:(ETXMLNode*)xml
{
	return [[[DiscoNode alloc] initFromXML:xml] autorelease];
}

- (DiscoNode*) initFromXML:(ETXMLNode*)xml
{
	if((self = [self init]) == nil)
	{
		return nil;
	}

	if([[xml getType] isEqualToString:@"iq"] && [[xml get:@"type"] isEqualToString:@"result"])
	{
		NSString * from = [xml get:@"from"];
		ETXMLNode * query = [[xml getChildrenWithName:@"query"] anyObject];
		//Check we are receiving a disco reply
		if([[query get:@"xmlns"] isEqualToString:@"http://jabber.org/protocol/disco#info"])
		{
			NSMutableSet * mutableFeatures = [[NSMutableSet alloc] init];
			NSMutableSet * mutableIdentities = [[NSMutableSet alloc] init];
			
			NSEnumerator * identityEnumerator = [[query getChildrenWithName:@"identity"] objectEnumerator];
			ETXMLNode * nextIdentity;
			while((nextIdentity = [identityEnumerator nextObject]))
			{
				[mutableIdentities addObject:[DiscoIdentity identityWithXML:nextIdentity]];
			}
			
			NSEnumerator * enumerator = [[query getChildrenWithName:@"feature"] objectEnumerator];
			ETXMLNode * nextFeature;
			while((nextFeature = [enumerator nextObject]))
			{
				[mutableFeatures addObject:[nextFeature get:@"var"]];
			}

			jid = [[JID jidWithString:from] retain];
			
			//In theory, I should make these into new NSSets, but it save a bit of time if I don't bother. 
			features = mutableFeatures;
			identities = mutableIdentities;
			
			return self;
		}
	}
	[self release];
	return nil;
	
}

- (ETXMLNode*) toXML
{
	ETXMLNode * iq = [[[ETXMLNode alloc] initWithType:@"iq"
										   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											   [jid jidString], @"from",
											   @"result", @"type",
											   nil]] autorelease];
	ETXMLNode * query = [[[ETXMLNode alloc] initWithType:@"query"
											  attributes:[NSDictionary dictionaryWithObject:@"http://jabber.org/protocol/disco#info" 
																					 forKey:@"xmlns"]] autorelease];
	
	//Add identities
	NSEnumerator * enumerator = [identities objectEnumerator];
	DiscoIdentity * identity;
	while((identity = [enumerator nextObject]))
	{
		[query addChild:[identity toXML]];
	}
	
	enumerator = [features objectEnumerator]; 
	NSString * feature;
	while((feature = [enumerator nextObject]))
	{
		ETXMLNode * featureNode = [[[ETXMLNode alloc] initWithType:@"feature"
														attributes:[NSDictionary dictionaryWithObject:feature
																							   forKey:@"var"]] autorelease];
		[query addChild:featureNode];
	}
	[iq addChild:query];
	return iq;
}


- (NSString*) name
{
	return name;
}

- (NSString*) node
{
	return node;
}

- (NSString*) type
{
	return type;
}

- (JID*) jid
{
	return jid;
}

- (BOOL) supportsFeature:(NSString*)feature
{
	if([features member:feature] != nil)
	{
		return YES;
	}
	return NO;
}

- (NSSet*) features
{
	return features;
}

- (void) dealloc
{
	[name release];
	[type release];
	[features release];
	[jid release];
	[super dealloc];
}
@end

@implementation DiscoNodeTree
+ (DiscoTreeNode*) discoTreeNodeWithJID:(JID*)aJID
								   name:(NSString*)aName
								   node:(NSString*)aNode
{
	return [[[DiscoTreeNode alloc] initWithJID:aJID
										  name:aName
										  node:aNode] autorelease];
}

- (DiscoTreeNode*) initWithJID:(JID*)aJID
						  name:(NSString*)aName
						  node:(NSString*)aNode
{
	if((self = [self init]) == nil)
	{
		return nil;
	}	
	jid = [aJID retain];
	name = [aName retain];
	node = [aNode retain];
	children = nil;
	return self;
}

- (void) addChildrenFromXML:(ETXMLNode*)xml
{
	[children release];
	children = [[NSMutableSet alloc] init];
	ETXMLNode * query = [[xml getChildrenWithName:@"query"] anyObject];
	ETXMLNode * child;
	NSEnumerator * enumerator = [[query children] objectEnumerator];
	while((child = [enumerator nextObject]))
	{
		if([[child getType] isEqualToString:@"item"])
		{
			[children addObject:[DiscoTreeNode discoTreeNodeWithJID:[JID jidWithString:[child get:@"jid"]]
															   name:[child get:@"name"]
															   node:[child get:@"node"]
														   children:nil]];
		}
	}
}

- (JID*) jid
{
	return jid;
}
- (NSString*) name
{
	return name;
}
- (NSString*) node
{
	return node;
}
- (NSSet*) children
{
	return children;
}

- (unsigned) hash
{
	return [[NSString stringWithFormat:@"%@ <@£$@^&> %@", [jid jidString], name] hash];
}
- (BOOL)isEqual:(id)anObject
{
	if(![anObject isKindOfClass:[DiscoTreeNode class]])
	{
		return NO;
	}
	return [jid isEqual:[anObject jid]] && [name isEqualToString:[anObject name]];
}

- (ETXMLNode*) toXML
{
	ETXMLNode * iq = [ETXMLNode ETXMLNodeWithType:@"iq"
									   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
										   [jid jidString], @"from",
										   @"result", @"type",
										   nil]];
	ETXMLNode * query = [ETXMLNode ETXMLNodeWithType:@"query"
										  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
											  @"http://jabber.org/protocol/disco#items", @"xmlns",
											  nil]];
	[iq addChild:query];
	NSEnumerator * enumerator = [children objectEnumerator];
	DiscoTreeNode * node;
	while((node = [enumerator nextObject]))
	{
		[query addChild:[node toXMLAsChild]];
	}
	return iq;
}

- (ETXMLNode*) toXMLAsChild
{
	if(node == nil)
	{
		return [ETXMLNode ETXMLNodeWithType:@"item"
								 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
									 [jid jidString], @"jid",
									 name, @"name",
									 nil]];			
	}
	return [ETXMLNode ETXMLNodeWithType:@"item"
							 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
								 [jid jidString], @"jid",
								 name, @"name",
								 node, @"node",
								 nil]];	
}
@end
