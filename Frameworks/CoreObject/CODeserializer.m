/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "CODeserializer.h"
#import "COUUID.h"
#import "NSObject+CoreObject.h"

/* CoreObject Deserializer */

/* The default CoreObject Deserializer, in future storage specific code could be 
   extracted in a subclass called COFSDeserializer. It would make possible to 
   write a deserializer like COZFSDeserializer. */
@implementation ETDeserializer (CODeserializer)

/** Handle the deserialization of the core object identified by anUUID. */
- (void) loadUUID: (char *)anUUID withName: (char *)aName
{
	NSLog(@"Load CoreObject %s to name %s", anUUID, aName);
}

@end
