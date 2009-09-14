/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  September 2009
 License: Modified BSD (see COPYING)
 */

#import "ETMailAccount.h"
#import "ETMailFolder.h"
#import "ETMailMessage.h"

@implementation ETMailAccount

- (id) init
{
	SUPERINIT;
	_properties = [[NSMutableDictionary alloc] init];
	_folders = [[NSMutableDictionary alloc] init];
	return self;
}

- (NSString *)displayName
{
	return [NSString stringWithFormat: @"Mail Account %@@%@",
			[_properties valueForKey: @"username"],
			[_properties valueForKey: @"server"]];
}

DEALLOC(DESTROY(_properties);DESTROY(_folders);)

- (void) reconnect
{
	[_service release];

	if (nil == [self valueForProperty: @"server"])
	{
		return;
	}
	
	// TODO: Guess the server type (pop/imap), and retry if incorrect

	NSLog(@"Creating a service connection to %@", [self valueForProperty: @"server"]);
	
	_service = [[CWIMAPStore alloc] initWithName: [self valueForProperty: @"server"]
											port: 993];
	
	[_service setDelegate: self];
	[_service connectInBackgroundAndNotify];
	NSLog(@"Told %@ to connect. del %@", _service, [_service delegate] );
}

/* Pantomime delegate methods */

- (void) connectionEstablished: (NSNotification *) theNotification
{
	NSLog(@"Connected!");
	
	NSLog(@"Now starting SSL...");
	[(CWTCPConnection *)[_service connection] startSSL];
}

- (void) connectionLost: (NSNotification *) theNotification
{
	NSLog(@"Connection lost");
}

- (void) connectionTimedOut: (NSNotification *) theNotification
{
	NSLog(@"timeout");
}

- (void) connectionTerminated: (NSNotification *) theNotification
{
	NSLog(@"Connection closed.");
	RELEASE(_service);
}

- (void) serviceInitialized: (NSNotification *) theNotification
{
	NSLog(@"SSL handshaking completed.");
	
	NSLog(@"Available authentication mechanisms: %@", [_service supportedMechanisms]);
	[_service authenticate: [self valueForProperty: @"username"]
				  password: [self valueForProperty: @"password"]
				 mechanism: @""];
}

- (void) authenticationFailed: (NSNotification *) theNotification
{
	NSLog(@"Authentication failed! Closing the connection...");
	[_service close];
}

- (void) authenticationCompleted: (NSNotification *) theNotification
{
	NSLog(@"Authentication completed! Enumerating folders...");
	
	// This will return nil and later trigger folderListCompleted:
	[_service folderEnumerator];
}

- (void) folderPrefetchCompleted: (NSNotification *) theNotification
{
	NSLog(@"Folder prefetch complete (%@)", theNotification );
	
	CWFolder *folder = [[theNotification userInfo] valueForKey: @"Folder"];
	
	NSLog(@"Folder %@, contents: %@", folder, [folder allMessages]);
	
	ETMailFolder *mailFolder = [_folders valueForKey: [folder name]];
	[mailFolder loadContentsOfCWFolder: folder];
	
	[[NSApp delegate] reload];
}

- (void) messagePrefetchCompleted: (NSNotification *) theNotification
{
	NSLog(@"Message prefetch complete (%@)", theNotification);
}

- (void) service: (CWService *) theService  receivedData: (NSData *) theData
{
	//NSLog(@" Got %@", theData);
}

- (void) service: (CWService *) theService  sentData: (NSData *) theData
{
//	NSLog(@"sent %@", theData);
}

- (void) requestCancelled: (NSNotification *) theNotification
{
	NSLog(@"req cancelled. %@", theNotification);
}

- (void) serviceReconnected: (NSNotification *) theNotification
{
	NSLog(@"Service reconnected.");
}

- (void) folderListCompleted: (NSNotification *) theNotification
{
	NSLog(@"Folder list completed. Reloading..");
	
	NSEnumerator *enumerator = [_service folderEnumerator];
	NSLog(@"Got folder enumerator: %@", enumerator);
	
	FOREACHE(nil, folderName, NSString *, enumerator)
	{
		NSLog(@"found folder %@", folderName);
		[_folders setObject: [ETMailFolder folderWithName: folderName service: _service]
					 forKey: folderName];
	}
	
	[[NSApp delegate] reload];
}


/* ETPropertyValueCoding */

- (NSArray *) properties
{
	return [A(@"username", @"password", @"server")
			arrayByAddingObjectsFromArray: [super properties]];
}
- (id) valueForProperty: (NSString *)key
{
	if ([A(@"username", @"password", @"server") containsObject: key])
	{
		return [_properties valueForKey: key];
	}
	else
	{
		return [super valueForProperty: key];
	}
}
- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	if ([A(@"username", @"password", @"server") containsObject: key])
	{
		[_properties setValue: value forKey: key];
		[self reconnect];
		return YES;
	}
	else
	{
		return [super setValue: value forProperty: key];
	}
}

/* ETCollection */

- (BOOL) isOrdered
{
	return YES;
}
- (BOOL) isEmpty
{
	return [_folders count] == 0;
}
- (id) content
{
	return [_folders allValues];
}
- (NSArray *) contentArray
{
	return [self content];
}
- (NSEnumerator *) objectEnumerator
{
	return [[self content] objectEnumerator];
}
- (unsigned int) count
{
	return [_folders count];
}

@end
