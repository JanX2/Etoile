/**
 * Étoilé ProjectManager - XCBAtomCache.m
 *
 * Copyright (C) 2009 David Chisnall
 * Copyright (C) 2010 Christopher Armstrong
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
+ (XCBAtomRequestObserver*)requestObserverWithObject: (id)object
                                            selector: (SEL)selector;
- (id)notifyObject;
- (SEL)notifySelector;
@end

@implementation XCBAtomRequestObserver
- (id)initWithObject: (id)object selector: (SEL)sel
{
	SELFINIT;
	notifyObject = object;
	selector = sel;
	return self;
}
+ (XCBAtomRequestObserver*)requestObserverWithObject: (id)object
                                            selector: (SEL)selector
{
	return [[[self alloc] initWithObject: object selector: selector]
		autorelease];
}

- (id)notifyObject
{
	return notifyObject;
}

- (SEL)notifySelector
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
	return self;
}
- (void)dealloc
{
	[inRequestAtoms release];
	[requestedAtoms release];
	[fetchedAtoms release];
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
	[XCBConn setNeedsFlush: YES];
}
- (void)cacheAtoms: (NSArray*)atoms
{
	xcb_connection_t *connection = [XCBConn connection];
	FOREACH(atoms, atomName, NSString*)
	{
		if ([fetchedAtoms objectForKey: atomName])
			continue;
		const char *str = [atomName UTF8String];
		// Request the cookie
		xcb_intern_atom_cookie_t cookie = 
			xcb_intern_atom(connection, 0, strlen(str), str);
		// Store the sequence -> atom name mapping
		NSNumber * key = [NSNumber numberWithUnsignedInt: cookie.sequence];
		[requestedAtoms setObject: atomName
		                   forKey: key];
		// Register the call-back for the cookie
		[XCBConn setHandler: self 
		           forReply: cookie.sequence 
		           selector: @selector(handleAtomReply:)];
	}
	[inRequestAtoms addObjectsFromArray: atoms];
	[XCBConn setNeedsFlush: YES];
}
- (void)handleAtomReply: (xcb_intern_atom_reply_t*)reply
{
	NSNumber * key = [NSNumber numberWithUnsignedInt: reply->sequence];
	NSLog(@"Atom %d for %@", reply->atom, [requestedAtoms objectForKey: key]);
	NSNumber * atom = [NSNumber numberWithUnsignedInt: reply->atom];
	NSString * atomString = [requestedAtoms objectForKey: key];
	[fetchedAtoms setObject: atom
	                 forKey: atomString];
	[requestedAtoms removeObjectForKey: key];
	[inRequestAtoms removeObject: atomString];
}
- (xcb_atom_t)atomNamed: (NSString*)aString
{
	NSNumber *atom = [fetchedAtoms objectForKey: aString];
	if (nil == atom)
	{
		const char *str = [aString UTF8String];
		// Request the cookie
		xcb_intern_atom_cookie_t cookie = 
			xcb_intern_atom([XCBConn connection], 0, strlen(str), str);
		xcb_intern_atom_reply_t* reply = 
			xcb_intern_atom_reply([XCBConn connection], cookie, NULL);
		
		atom = [NSNumber numberWithUnsignedInt: reply->atom];
		[fetchedAtoms setObject: atom
		                 forKey: aString];

		free(reply);
	}
	return [atom unsignedIntValue];
}
- (void)waitOnPendingAtomRequests
{
	FOREACH([requestedAtoms allKeys], sequence, NSNumber*)
	{
		NSString *atomName = [requestedAtoms objectForKey: sequence];
		NSNumber *atom;
		xcb_intern_atom_cookie_t cookie;
		cookie.sequence = [sequence unsignedIntValue];
		xcb_intern_atom_reply_t* reply =
			xcb_intern_atom_reply([XCBConn connection], 
			cookie,
			NULL);
		atom = [NSNumber numberWithUnsignedInt: reply->atom];
		[fetchedAtoms setObject: atom
		                 forKey: atomName];
	}
	[inRequestAtoms removeAllObjects];
	[requestedAtoms removeAllObjects];
}

@end
