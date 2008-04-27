/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "COObjectServer.h"
#import "NSObject+CoreObject.h"
#import "COMetadataServer.h"
#import "GNUstep.h"

#define DEFAULTS [NSUserDefaults standardUserDefaults]
#define FM [NSFileManager defaultManager]

/** Must be a string and not an NSURL object for NSUserDefaults needs. */
NSString *CODefaultObjectServerURL = nil;
NSString *COCoreObjectURLProtocol = @"coreobject";
NSString *COUUIDURLProtocol = @"uuid";
// NOTE: May use later...
//NSString *COStoreConfigurationFile = @"StoreConfiguration.plist";

static COObjectServer *localObjectServer = nil;


@implementation COObjectServer

/** Returns the local object server. */
+ (id) defaultServer
{
	if (localObjectServer == nil)
	{
		localObjectServer = [[self alloc] init];	
	}

	return localObjectServer;
}

/** <override-dummy />
	Returns the base URL of the default object store that must be defined by +localObjectServerClass
	The base URL can be defined in a subclass by overriding 
	+localObjectServerClass. */
+ (NSURL *) defaultSerializationURL;
{
	NSString *serializationDest = [DEFAULTS objectForKey: CODefaultObjectServerURL];
	NSURL *serializationURL = nil;

	if (serializationDest != nil)
	{
		serializationURL = [NSURL URLWithString: serializationDest];
	}
	else
	{
		serializationURL = [NSURL fileURLWithPath: @"~/CoreObjectStore"];
	}
	return serializationURL;
}

- (id) init
{
	return [self initWithMetadataServer: nil URL: nil];
}

/** <init />
	Instantiates an returns a new local object server instance that uses the 
	metadata server and the library passed in parameter. */
- (id) initWithMetadataServer: (id)metadataServer URL: (NSURL *)serializationURL
{
	SUPERINIT

	if (metadataServer != nil)
	{
		ASSIGN(_metadataServer, metadataServer);
	}
	else
	{
		ASSIGN(_metadataServer, [COMetadataServer defaultServer]);
	}

	if (serializationURL != nil)
	{
		ASSIGN(_serializationURL, serializationURL);
	}
	else
	{
		ASSIGN(_serializationURL, [[self class] defaultSerializationURL]);
	}

	_objectClasses = [[NSMutableDictionary alloc] init];
	_groupClasses = [[NSMutableDictionary alloc] init];
	_coreObjectTable = [[NSMutableDictionary alloc] init];

	return self;
}

- (void) dealloc
{
	DESTROY(_objectClasses);
	DESTROY(_groupClasses);
	DESTROY(_coreObjectTable);
	DESTROY(_metadataServer);
	DESTROY(_serializationURL);
	[super dealloc];
}

/* CoreObject Factory */

- (id) objectForURL: (NSURL *)url
{
	NSString *protocol = [url scheme];

	if ([protocol isEqualToString: COUUIDURLProtocol])
	{
		return [self managedObjectForURL: url];
	}
	else if ([protocol isEqualToString: COCoreObjectURLProtocol])
	{
		return [self distantObjectForURL: url];
	}
	else /* Usual case */
	{
		Class groupClass = [self groupClassForProtocolType: protocol];

		if ([groupClass isGroupAtURL: url])
		{
			return [groupClass objectWithURL: url];
		}
		else
		{
			return [[self objectClassForProtocolType: protocol] objectWithURL: url];
		}
	}
}

- (id) objectForUUID: (ETUUID *)uuid
{
	return nil; // FIXME: Implement
}

/** Only accepts URLs with scheme uuid:// */
- (id) managedObjectForURL: (NSURL *)url
{
	return nil; // FIXME: Implement
}

/** Returns a proxy object for the core object path of url.
	A core object path is a sequence of group names. The proxy is obtained from 
	a remote object server by using DO as a bridge. The remote object server is 
	easy to retrieve because it is registered under the name 'coreobject://' in 
	the DO daemon running on the host of url. */
- (id) distantObjectForURL: (NSURL *)url
{
	return nil; // FIXME: Implement
}

/* Registering CoreObject backend classes */

- (void) registerObjectClass: (Class)objectClass 
             forProtocolType: (NSString *)urlScheme
{
	[_objectClasses setObject: objectClass forKey: urlScheme];
}

- (Class) objectClassForProtocolType: (NSString *)urlScheme
{
	return [_objectClasses objectForKey: urlScheme];
}

- (void) registerGroupClass: (Class)groupClass 
            forProtocolType: (NSString *)urlScheme
{
	[_groupClasses setObject: groupClass forKey: urlScheme];
}

- (Class) groupClassForProtocolType: (NSString *)urlScheme
{
	return [_groupClasses objectForKey: urlScheme];
}

/* Verify if the object is a valid core object. */
- (void) checkObject: (id)object
{
	if ([object isCoreObject] == NO)
	{
		[NSException raise: NSInvalidArgumentException format: @"Object %@ "
			@" must be a core object", object];
	}
	if ([object UUID] == nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"UUID of "
			@"object %@ must not be nil", object];
	}
}

/** Adds an object to the local store of the receiver.
	This method is called by managed objects once they are initialized (before 
	returning self at the end of the designated initializer). */
- (void) addObject: (id)object 
{ 
	if ([object conformsToProtocol: @protocol(COManagedObject)])
	{
		[_coreObjectTable setObject: object forKey: [object UUID]];
	}
	else /* Basic core object */
	{
		[_coreObjectTable setObject: object forKey: [object URL]];
	}
}

/** Removes an object from the object store of the receiver. */
- (void) removeObject: (id)object 
{ 
	if ([object conformsToProtocol: @protocol(COManagedObject)])
	{
		[_coreObjectTable removeObjectForKey: [object UUID]];
	}
	else /* Basic core object */
	{
		[_coreObjectTable removeObjectForKey: [object URL]];
	}
}

- (NSURL *) serializationURL
{
	return _serializationURL;
}

/** Triggers the save of the object server state at the serialization URL 
	defined by -serializationURL. 
	The save only includes the serialization of the store/server 
	configuration. */
- (void) save 
{ 
	//[COSerialization serializeObject: self];
}

- (void) handleError: (NSError *)error
{
	//NSLog(@"Error: %@ (%@ %@)", error, self, [err methodName]);
	NSLog(@"Error: %@ (%@)", error, self);
	RELEASE(error);
}

@end
