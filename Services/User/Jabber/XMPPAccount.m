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
#else
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABMultiValue.h>
#import <AddressBook/ABPerson.h>
#endif
#include <Security/Security.h>

#import "XMPPAccount.h"
#import "JID.h"
#import "JabberApp.h"

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

	UInt32 passwordLength;
	char * passwordData;

	//Get the password from the keychain
	OSStatus status = SecKeychainFindInternetPassword(NULL, 
									[[myJID domain] length],
									[[myJID domain] UTF8String],
									0,
									NULL,
									[[myJID node] length],
									[[myJID node] UTF8String],
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
		NSString * password = [NSString stringWithCString:passwordData length:passwordLength];
		
		
		
		[connection connectToJabberServer:[myJID domain]
									 user:[myJID node]
								 password:password];
		
		SecKeychainItemFreeContent(NULL,passwordData);
		
		return self;
	}
	else
	{
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
