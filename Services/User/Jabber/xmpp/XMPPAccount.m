//
//  XMPPAccount.m
//  Jabber
//
//  Created by David Chisnall on 21/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#ifdef GNUSTEP
#import <AddressBook/ADAddressBook.h>
#import <AddressBook/ADMultiValue.h>
#import <AddressBook/ADPerson.h>
#define ABMultiValue ADMultiValue
#define ABAddressBook ADAddressBook
//TODO: Find out why this is needed when it wasn't previously
#define kABJabberInstantProperty @"JabberAddress"
#else
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABMultiValue.h>
#import <AddressBook/ABPerson.h>
#include <Security/Security.h>
#endif

#import "XMPPAccount.h"
#import "JID.h"
//TODO: Remove this:
#import "../JabberApp.h"

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

@implementation XMPPAccount
- (id) initWithName:(NSString*)_name
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	
	name = [_name retain];
	roster = [[Roster alloc] initWithAccount:self];
	connection = [[XMPPConnection alloc] initWithAccount:self];
	[connection setPresenceDisplay:[roster delegate]];

	//Get user's Jabber ID from Address Book
	ABMultiValue * jids = [[[ABAddressBook sharedAddressBook] me] valueForProperty:kABJabberInstantProperty];
	myJID = [JID jidWithString:[jids valueAtIndex:0]];

		
	NSString * password = passwordForJID(myJID);

	if(password != nil)
	{	
		[connection connectToJabberServer:[myJID domain]
									 user:[myJID node]
								 password:password];
		
		
		return self;
	}
	else
	{
		//TODO: Make this a notification with a reason
		[(JabberApp*)[NSApp delegate] connectionFailed:self];
		return nil;
	}
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

- (void) dealloc
{
	[name release];
	[myJID release];
	[roster release];
	[connection release];
	[super dealloc];
}
@end
