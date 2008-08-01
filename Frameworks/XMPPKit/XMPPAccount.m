//
//  XMPPAccount.m
//  Jabber
//
//  Created by David Chisnall on 21/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#ifndef GNUSTEP
#include <Security/Security.h>
#endif

#import <AddressBook/AddressBook.h>
#import "XMPPAccount.h"
#import "Roster.h"
#import "JID.h"

NSString * passwordForJID(JID * aJID)
{
#ifdef GNUSTEP
	return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"XMPPPasswords"] objectForKey:[aJID jidString]];
#else
	UInt32 passwordLength;
	char * passwordData;

	//Get the password from the keychain
	OSStatus status = SecKeychainFindInternetPassword(NULL, 
									[[aJID domain] length],
									[[aJID domain] UTF8String],
									0,
									NULL,
									[[aJID node] length],
									[[aJID node] UTF8String],
									0,
									NULL,
									5222,
									kSecProtocolTypeTelnet, //This is wrong, but there seems to be no correct answer.
									kSecAuthenticationTypeDefault,
									&passwordLength,
									(void**)&passwordData,
									NULL);
	if(status == noErr)
	{
		NSString * password = [NSString stringWithCString:strdup(passwordData)
	   	                                           length:passwordLength];
		SecKeychainItemFreeContent(NULL,passwordData);
		return password;
	}
	return nil;
#endif
}

//NOTE: These could probably be done more neatly with KVC
void setDefault(NSString * dictionary, id key, id value)
{
	NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:dictionary]];
	if(dict == nil)
	{
		dict = [NSMutableDictionary dictionary];
	}
	[dict setValue:value forKey:key];
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:dictionary];
}

id getDefault(NSString * dictionary, id key)
{
	NSDictionary * dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:dictionary];
	return [dict valueForKey:key];
	
}
@implementation XMPPAccount
+ (void) setDefaultJID:(JID*) aJID
{
	[self setDefaultJID:aJID withServer:[aJID domain]];
}
+ (void) setDefaultJID:(JID*) aJID withServer:(NSString*) aServer
{
	ABPerson * me =  [[ABAddressBook sharedAddressBook] me];
	if(me == nil)
	{
		me = [[[ABPerson alloc] init] autorelease];
		[[ABAddressBook sharedAddressBook] addRecord:me];		
		[[ABAddressBook sharedAddressBook] setMe:me];
	}
	ABMutableMultiValue * jids = [[me valueForProperty:kABJabberInstantProperty] mutableCopy];
	if(jids == nil)
	{
		jids = [[[ABMutableMultiValue alloc] init] autorelease];
	}
	NSString * defaultID = [jids primaryIdentifier];
	if(defaultID == nil)
	{
		//TODO: This could arguably be more sensible.
		defaultID = @"home";
	}
	[jids addValue:[aJID jidString] withLabel:defaultID];
	[me setValue:jids forProperty:kABJabberInstantProperty];
	[[ABAddressBook sharedAddressBook] save];
	setDefault(@"Servers", [aJID jidString], aServer);
}

- (id) initWithName:(NSString*)_name
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	
	name = [_name retain];
	roster = (Roster*)[[Roster alloc] initWithAccount:self];
	connection = (XMPPConnection*)[[XMPPConnection alloc] initWithAccount:self];
	[connection setPresenceDisplay:[roster delegate]];

	//Get user's Jabber ID from Address Book
	ABMultiValue * jids = [[[ABAddressBook sharedAddressBook] me] valueForProperty:kABJabberInstantProperty];
	NSString * jidString = [jids valueAtIndex:0];
	if(jidString == nil)
	{
		[[NSException exceptionWithName:XMPPNOJIDEXCEPTION
								 reason:@"Unable to find JID for connection"
		                       userInfo:nil] raise];
	}
	myJID = [[JID jidWithString:jidString] retain];
		
	NSString * password = passwordForJID(myJID);
	
	if(password != nil)
	{
		NSString * server = getDefault(@"Servers", [myJID jidString]);
		[connection connectToJabberServer:server
		                          withJID:myJID
		                         password:password];
		
		
		return self;
	}
	else
	{
		[[NSException exceptionWithName:XMPPNOPASSWORDEXCEPTION
								 reason:@"Unable to find password for connection"
							   userInfo:[NSDictionary dictionaryWithObject:myJID
							                                        forKey:@"JID"]] raise];
	}
	// Never reached; just used to eliminate a warning
	// from the compiler that doesn't know about exceptions
	return nil; 
}

- (void) reconnect
{
	[connection reconnectToJabberServer];
}

- (id) init
{
	return [self initWithName:@"Default"];
}

- (Roster*) roster
{
	return roster;
}

- (XMPPConnection*) connection
{
	return connection;
}

- (JID*) jid
{
	return myJID;
}
- (NSString*) name
{
	return name;
}
- (void) dealloc
{
	[name release];
	[myJID release];
	[roster release];
	[connection release];
	[super dealloc];
}
@end
