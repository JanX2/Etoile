//
//  StanzaFactory.m
//  Jabber
//
//  Created by David Chisnall on 24/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "StanzaFactory.h"
#import "TRXMLNullHandler.h"
#import "../Macros.h"

@implementation StanzaFactory
+ (id) sharedStazaFactory
{
	return nil;
}

- (id) init
{
	SUPERINIT;
	tagHandlers = [[NSMutableDictionary alloc] init];
	namespacedTagHandlers = [[NSMutableDictionary alloc] init];
	tagValues = [[NSMutableDictionary alloc] init];
	namespacedTagValues = [[NSMutableDictionary alloc] init];
	return self;
}
- (void) addHandler:(Class)aHandler withValue:(NSString*)aValue forTag:(NSString*)aTag
{
	[self addHandler:aHandler forTag:aTag];
	[self addValue:aValue forTag:aTag];
}

- (void) addHandler:(Class)aHandler withValue:(NSString*)aValue forTag:(NSString*)aTag inNamespace:(NSString*)aNamespace
{
	[self addHandler:aHandler forTag:aTag inNamespace:aNamespace];
	[self addValue:aValue forTag:aTag inNamespace:aNamespace];
}

- (void) addHandler:(Class)aHandler forTag:(NSString*)aTag
{
	[tagHandlers setObject:aHandler forKey:aTag];
}

- (void) addHandler:(Class)aHandler forTag:(NSString*)aTag inNamespace:(NSString*)aNamespace
{
	NSMutableDictionary * handlers = [namespacedTagHandlers objectForKey:aTag];
	if(handlers == nil)
	{
		handlers  = [NSMutableDictionary dictionary];
	}
	[handlers setObject:aHandler forKey:aNamespace];
	[namespacedTagHandlers setObject:handlers forKey:aTag];
}

- (void) addValue:(NSString*)aValue forTag:(NSString*)aTag
{
	[tagValues setObject:aValue forKey:aTag];
}

- (void) addValue:(NSString*)aValue forTag:(NSString*)aTag inNamespace:(NSString*)aNamespace
{
	NSMutableDictionary * values = [namespacedTagValues objectForKey:aTag];
	if(values == nil)
	{
		values = [NSMutableDictionary dictionary];
	}
	[values setObject:aValue forKey:aNamespace];
	[namespacedTagValues setObject:values forKey:aTag];
}

- (id) parser
{
	return nil;
}

- (Class) handlerForTag:(NSString*)aTag
{
	return [tagHandlers objectForKey:aTag];
}
- (Class) handlerForTag:(NSString*)aTag inNamespace:(NSString*)aNamespace
{
	Class handler =  [[namespacedTagHandlers objectForKey:aTag] objectForKey:aNamespace];
	if(handler == Nil)
	{
		handler = [tagHandlers objectForKey:aTag];
	}
	if(handler == Nil)
	{
		handler = [TRXMLNullHandler class];
	}
	return handler;
}
- (NSString*) valueForTag:(NSString*)aTag
{
	NSString * value = [tagValues objectForKey:aTag];
	if(value != nil)
	{
		return value;
	}
	return aTag;
}
- (NSString*) valueForTag:(NSString*)aTag inNamespace:(NSString*)aNamespace
{
	NSString * value = [[namespacedTagValues objectForKey:aTag] objectForKey:aNamespace];
	if(value == nil)
	{
		value = [tagValues objectForKey:aTag];
	}
	if(value == nil)
	{
		value = aTag;
	}
	return value;
}
@end
