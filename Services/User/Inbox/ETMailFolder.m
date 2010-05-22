/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  September 2009
 License: Modified BSD (see COPYING)
 */

#import "ETMailFolder.h"
#import "ETMailMessage.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation ETMailFolder

+ (ETMailFolder *)folderWithName: (NSString *)name service: (CWService *)service;
{
	return [[[ETMailFolder alloc] initWithName: name service: service] autorelease];
}

- (id)initWithName: (NSString *)name service: (CWService *)service;
{
	SUPERINIT;
	ASSIGN(_name, name);
	_service = service; // Weak ref
	_folder = nil;
	_messages = [[NSArray alloc] init];
	return self;
}

- (NSString *)displayName
{
	return _name;
}

- (NSString *)name
{
	return _name;
}

- (void) loadContentsOfCWFolder: (CWFolder *)folder
{
	ASSIGN(_messages, [NSMutableArray arrayWithCapacity: [folder count]]);
	FOREACH([folder allMessages], message, CWMessage *)
	{
		NSLog(@"Folder has %@, name %@", message, [message subject]);
		[_messages addObject: [ETMailMessage messageWithCWMessage: message]];
	}
	
	_folder = folder; // Weak ref
}

/* ETCollection */

- (BOOL) isOrdered
{
	return YES;
}
- (BOOL) isEmpty
{
	return [[self contentArray] count] == 0;
}
- (id) content
{
	return [self contentArray];
}
- (NSArray *) contentArray
{
	NSLog(@"Requested contents of %@ in UI.", _name);
	// If we are not loaded yet, load (asynchronously.)
	if (nil == _folder)
	{
		NSLog(@"Prefetching %@...", _name);
		[[_service folderForName: _name] prefetch];
	}
	
	return _messages;
}
- (NSEnumerator *) objectEnumerator
{
	return [[self contentArray] objectEnumerator];
}
- (NSUInteger) count
{
	return [[self contentArray] count];
}


@end
