#import "XCBAtomCache.h"
#import "XCBConnection.h"
#import <EtoileFoundation/EtoileFoundation.h>

static XCBAtomCache *sharedInstance;
@implementation XCBAtomCache
- (id)init
{
	SUPERINIT;
	requestedAtoms = [NSMutableDictionary new];
	fetchedAtoms = [NSMutableDictionary new];
	return self;
}
- (void)dealloc
{
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
	const char *str = [aString UTF8String];
	// Request the cookie
	xcb_intern_atom_cookie_t cookie = 
		xcb_intern_atom([XCBConn connection], 0, strlen(str), str);
	// Store the sequence -> atom name mapping
	NSNumber * key = [NSNumber numberWithUnsignedInt: cookie.sequence];
	[requestedAtoms setObject: aString
	                   forKey: key];
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
	[requestedAtoms removeObjectForKey: key];
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
@end
