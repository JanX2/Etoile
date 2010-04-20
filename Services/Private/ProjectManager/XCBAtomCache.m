/**
 * Étoilé ProjectManager - XCBAtomCache.m
 *
 * Copyright (C) 2009 David Chisnall
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 **/
#import "XCBAtomCache.h"
#import "XCBConnection.h"
#import <EtoileFoundation/EtoileFoundation.h>

static XCBAtomCache *sharedInstance;

@interface XCBAtomRequestObserver : NSObject
{
	id notifyObject;
	SEL selector;
}
+ (XCBAtomRequestObserver*) requestObserverWithObject: (id)object
                                             selector: (SEL)selector;
- (id) notifyObject;
- (SEL) notifySelector;
@end

@implementation XCBAtomRequestObserver
- (id) initWithObject: (id)object selector: (SEL)sel
{
	SUPERINIT;
	notifyObject = object;
	selector = sel;
	return self;
}
+ (XCBAtomRequestObserver*) requestObserverWithObject: (id)object
                                             selector: (SEL)selector
{
	return [[[self alloc]
		initWithObject:object selector:selector]
		autorelease];
}

- (id) notifyObject
{
	return notifyObject;
}

- (SEL) notifySelector
{
	return selector;
}
@end

@implementation XCBAtomCache
- (id)init
{
	SUPERINIT;
	requestedAtoms = [NSMutableDictionary new];
	fetchedAtoms = [NSMutableDictionary new];
	inRequestAtoms = [NSMutableSet new];
	requestObservers = [NSMutableDictionary new];
	return self;
}
- (void)dealloc
{
	[inRequestAtoms release];
	[requestedAtoms release];
	[fetchedAtoms release];
	[requestObservers release];
	[super dealloc];
}
+ (XCBAtomCache*)sharedInstance
{
	if (nil == sharedInstance)
	{
		sharedInstance = [self new];
	}
	return sharedInstance;
}

- (void)cacheAtom: (NSString*)aString
{
	if ([inRequestAtoms containsObject:aString])
		return;
	const char *str = [aString UTF8String];
	// Request the cookie
	xcb_intern_atom_cookie_t cookie = 
		xcb_intern_atom([XCBConn connection], 0, strlen(str), str);
	// Store the sequence -> atom name mapping
	NSNumber * key = [NSNumber numberWithUnsignedInt: cookie.sequence];
	[requestedAtoms setObject: aString
	                   forKey: key];
	[inRequestAtoms addObject: aString];
	// Register the call-back for the cookie
	[XCBConn setHandler: self 
	           forReply: cookie.sequence 
               selector: @selector(handleAtomReply:)];
	xcb_flush([XCBConn connection]);
}
- (void)cacheAtoms: (NSArray*)atoms
{
	xcb_connection_t *connection = [XCBConn connection];
	FOREACH(atoms, atom, NSString*)
	{
		const char *str = [atom UTF8String];
		// Request the cookie
		xcb_intern_atom_cookie_t cookie = 
			xcb_intern_atom(connection, 0, strlen(str), str);
		// Store the sequence -> atom name mapping
		NSNumber * key = [NSNumber numberWithUnsignedInt: cookie.sequence];
		[requestedAtoms setObject: atom 
						   forKey: key];
		// Register the call-back for the cookie
		[XCBConn setHandler: self 
				   forReply: cookie.sequence 
				   selector: @selector(handleAtomReply:)];
	}
	xcb_flush([XCBConn connection]);
}
- (void)handleAtomReply: (xcb_intern_atom_reply_t*)reply
{
	NSNumber * key = [NSNumber numberWithUnsignedInt: reply->sequence];
	NSLog(@"Atom %d for %@", reply->atom, [requestedAtoms objectForKey: key]);
	NSNumber * atom = [NSNumber numberWithUnsignedInt: reply->atom];
	[fetchedAtoms setObject: atom
	                 forKey: [requestedAtoms objectForKey: key]];
	NSMutableArray *observers = [requestObservers objectForKey: key];
	if (nil != observers)
	{
		FOREACH(observers, observer, XCBAtomRequestObserver*)
		{
			[[observer notifyObject]
				performSelector: [observer notifySelector]
				     withObject: key
				     withObject: atom];
		}
		[requestObservers removeObjectForKey: key];
	}
	[requestedAtoms removeObjectForKey: key];
	[inRequestAtoms removeObject: key];
}
- (xcb_atom_t)atomNamed: (NSString*)aString
{
	NSNumber *atom = [fetchedAtoms objectForKey: aString];
	// Synchronously fetch the atom if it's not cached.
	if (nil == atom)
	{
		xcb_connection_t *connection = [XCBConn connection];
		const char *str = [aString UTF8String];
		xcb_intern_atom_cookie_t cookie = 
			xcb_intern_atom(connection, 0, strlen(str), str);
		xcb_intern_atom_reply_t *reply = 
			xcb_intern_atom_reply(connection, cookie, NULL);
		atom = [NSNumber numberWithUnsignedInt: reply->atom];
		[fetchedAtoms setObject: atom
						 forKey: aString];
	}
	return [atom unsignedIntValue];
}

- (void)atomNamed: (NSString*)name 
     notifyObject: (id)delegate
     withSelector: (SEL)selector
{
	NSNumber *fetchedAtom = [fetchedAtoms objectForKey: name];
	if (nil == fetchedAtom)
	{
		[self cacheAtom: name];
		NSMutableArray *observers = [requestObservers objectForKey: name];
		if (observers == nil)
		{
			observers = [NSMutableArray array];
			[requestObservers setObject: observers forKey: name];
		}
		[observers addObject: 
			[XCBAtomRequestObserver requestObserverWithObject: delegate
			                                     selector: selector]
			];
	}
	else
	{
		[delegate performSelector: selector withObject: name withObject: fetchedAtom];
	}
}

@end
