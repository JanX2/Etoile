/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class COObjectContext;

/** All classes whose instances can be managed by CoreObject must conform to 
	this protocol. An object becomes a managed core object when it gets 
	referenced by an UUID in the metadata server and CoreObject oversees its 
	persistency.
	CoreObject provides two classes that adopt this protocol COProxy and 
	COObject related subclasses.*/
@protocol COManagedObject
- (ETUUID *) UUID;
- (int) objectVersion;
- (COObjectContext *) objectContext;

// TODO: We need to discuss the terminology here and differentiate between 
// metadatas (or persistent properties) and metadatas to be indexed (or 
// indexable persistent properties). 
- (NSDictionary *) metadatas;
@end

/* NSObject extensions */

@interface NSObject (CoreObject)

- (BOOL) isCoreObject;
- (BOOL) isManagedCoreObject;
- (BOOL) isCoreObjectProxy;
- (BOOL) isFault;

@end

@interface ETUUID (CoreObject)
- (BOOL) isFault;
@end
