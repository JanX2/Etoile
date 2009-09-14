/*
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  September 2009
 License: Modified BSD (see COPYING)
 */

#import "ETMailMessage.h"


@implementation ETMailMessage

+ (ETMailMessage *)messageWithCWMessage: (CWMessage *)message
{
	return [[[ETMailMessage alloc] initWithCWMessage: message] autorelease];
}

- (id)initWithCWMessage: (CWMessage *)message
{
	SUPERINIT;
	ASSIGN(_message, message);
	return self;
}

- (NSString *) displayName
{
	NSLog(@" requested name of %@", [_message subject]);
	return [_message subject];
}

@end
