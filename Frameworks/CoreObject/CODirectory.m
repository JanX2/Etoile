/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "CODirectory.h"
#import "COFile.h"
#import "GNUstep.h"

#define FM [NSFileManager defaultManager]
#define FM_HANDLER [CODirectory delegate]
#define FSPATH(x) [[x URL] path]

@interface CODirectory (Private)
- (BOOL) addMovedObject: (id)object;
- (BOOL) addCopiedObject: (id)object;
- (BOOL) checkObjectToBeRemovedOrDeleted: (id)object;
@end

@implementation CODirectory

/** Returns the active trash directory.
	The returned directory may vary with the user. */
+ (CODirectory *) trashDirectory
{
	// FIXME: Use the real trash directory, as specified by Freedesktop, by 
	// using the implementation available in Outerspace.
	return [CODirectory objectWithURL: [NSURL fileURLWithPath: @"~"]];
}

static id fsServerDelegate = nil;

+ (id) delegate
{
	return fsServerDelegate;
}

+ (void) setDelegate: (id)delegate
{
	fsServerDelegate = delegate;
}

+ (void) initialize
{

}

- (id) init
{
	SUPERINIT;

	return self;
}

DEALLOC()

/** Tests equality by considering the type and URLs of the receiver and object. */
- (BOOL) isEqual: (id)object
{
	BOOL isSameType = ([object isKindOfClass: [self class]]);
	return (isSameType && [[self URL] isEqual: [object URL]]);
}

/** Checks whether the object can be hold by the recevier by checking type and 
	state. If it isn't thse case, mutation methods won't accept it. */
- (BOOL) isValidObject: (id)object
{
	// NOTE: May make sense to be less rigid...
	return [object isKindOfClass: [COFile class]];
}

/** Returns whether a directory exists at the receiver URL.
	Take note the method returns NO when a file exists at the URL instead of a
	directory. */
- (BOOL) exists
{
	BOOL isDir = NO;
	BOOL result = [FM fileExistsAtPath: FSPATH(self) isDirectory: &isDir];

	return (result && isDir);
}

/** Returns whether object belongs to the receiver directory by being stored 
	inside it. 
	Take note that	 this method returns NO if object points to a non-existent 
	file at a subpath of the receiver URL. */
- (BOOL) containsObject: (id)object
{
	return [[self objects] containsObject: object];
}

/** Will return NO and won't add the object if the represented directory doesn't 
	exist on the file system. */
- (BOOL) addObject: (id) object
{
	if ([self isValidObject: object])
		return NO;

	BOOL result = NO;

	if ([object isCopyPromise])
	{
		result = [self addCopiedObject: object];
	}
	else
	{
		result = [self addMovedObject: object];
	}
	[object didAddToGroup: self];

	return result;
}

/** Creates a symbolic link at the URL of the receiver with the name of object 
	and pointing to the URL of this object. */
- (BOOL) addSymbolicLink: (id)object
{
	if ([self isValidObject: object])
		return NO;
	if ([object isCopyPromise])
	{
		[NSException raise: NSInvalidArgumentException 
		            format: @"Symbolically linked object %@ cannot be a copy promise", object];
	}

	NSString *linkName = [FSPATH(object) lastPathComponent];
	NSString *linkPath = [FSPATH(self) appendPath: linkName];
	return [FM createSymbolicLinkAtPath: linkPath pathContent: FSPATH(object)];
}

/** Creates a hard link at the URL of the receiver with the name of object 
	and pointing to the URL of this object. */
- (BOOL) addHardLink: (id)object
{
	if ([self isValidObject: object])
		return NO;
	if ([object isCopyPromise])
	{
		[NSException raise: NSInvalidArgumentException 
		            format: @"Hard linked object %@ cannot be a copy promise", object];
	}

	return [FM removeFileAtPath: FSPATH(object) handler: FM_HANDLER];
}

- (BOOL) addMovedObject: (id)object
{
	// NOTE: If we cache the children objects/files at some point, we will have 
	// to remove the moved object from the existing CODirectory instance that 
	// represents the path of its parent. 
	// id parentDir = [CODirectory objectWithURL: [[object URL] parentURL]];
	// [parentDir removeCachedObject: object]; or [parentDir recache]; or 
	// [object didRemoveFromGroup: self];

	return [FM movePath: FSPATH(object) toPath: FSPATH(self) handler: FM_HANDLER];
}

- (BOOL) addCopiedObject: (id)object
{
	return [FM copyPath: FSPATH(object) toPath: FSPATH(self) handler: FM_HANDLER];
}

/** Create a directory when none exists at the receiver URL. */
- (BOOL) create
{
	return [FM createDirectoryAtPath: FSPATH(self) attributes: nil];
}

- (BOOL) checkObjectToBeRemovedOrDeleted: (id)object
{
	if ([self isValidObject: object])
		return NO;
	if ([object isCopyPromise])
	{
		[NSException raise: NSInvalidArgumentException 
		            format: @"Removed or deleted object %@ cannot be a copy "
		                    @"promise", object];
	}
	if ([self containsObject: object] == NO)
	{
		[NSException raise: NSInvalidArgumentException 
		            format: @"Object %@ to be removed or deleted cannot be "
		                    @"found inside the directory %@", object, self];
	}	
	return YES;
}

/** Removes the file instance from the receiver, but defers the deletion of the 
	represented file inside the directory until object is released/deallocated. 
	This lazy behavior for the delete filesystem operation makes possible to 
	move files accross directories (or other kind of CoreObject groups) in the 
	following way:
	[artDirectory removeObject: myPoemFile];
	[poetryDirectory addObject: myPoemFile]; */
- (BOOL) removeObject: (id) object
{
	if ([self checkObjectToBeRemovedOrDeleted: object])
		return NO;

	BOOL result = [[CODirectory trashDirectory] addObject: object];
	[object didRemoveFromGroup: self];

	return result;
}

/** Deletes the file pointed by object if it is located inside the receiver 
	directory.
	After calling this method, -exists will return NO for object. */
- (BOOL) deleteObject: (id)object
{
	if ([self checkObjectToBeRemovedOrDeleted: object])
		return NO;


	// NOTE: If we cache the children objects/files at some point, we will have 
	// to remove the moved object from the existing CODirectory instance that 
	// represents the path of its parent. 

	return [FM removeFileAtPath: FSPATH(object) handler: FM_HANDLER];
}

/** Returns all files and directories located in the receiver directory. 
	This excludes files and directories inside subdirectories. */
- (NSArray *) objects
{
	NSMutableArray *files = [NSMutableArray array];
	NSString *dirPath = FSPATH(self);
	// FIXME: Either I don't understand NSDirectoryEnumerator or GNUstep 
	// implementation is broken ;-)
	//NSDirectoryEnumerator *e = [FM enumeratorAtPath: dirPath];
	NSEnumerator *e = [[FM directoryContentsAtPath: dirPath] objectEnumerator];
	NSString *fileName = nil;


	// TODO: Optimize (NSDirectoryEnumerator seems a bit dumb or like a misuse 
	// in the following code).
	while ((fileName = [e nextObject]) != nil)
	{
		NSString *path = [dirPath appendPath: fileName];
		id object = nil;
		BOOL isDir = NO;

		ETLog(@"Enumerate file %@", path);

		if ([FM fileExistsAtPath: path isDirectory: &isDir])
		{
			if (isDir)
			{
				object = [CODirectory objectWithURL: [NSURL fileURLWithPath: path]];
				//[e skipDescendents];
			}
			else
			{
				object = [COFile objectWithURL: [NSURL fileURLWithPath: path]];
			}
			[files addObject: object];
		}
		else
		{
			ETLog(@"WARNING: Enumerated a non-existent file at path %@", path);
		}
	}

	return files;
}

- (BOOL) isGroup
{
	return YES;
}

/** See -addObject:. */
- (BOOL) addGroup: (id <COGroup>)subgroup
{
	return [self addObject: subgroup];
}

/** See -removeObject:. */
- (BOOL) removeGroup: (id <COGroup>)subgroup
{
	return [self removeObject: subgroup];
}

// FIXME: Implement
- (NSArray *) groups
{
	return nil;
}

// FIXME: Implement
- (NSArray *) allObjects
{
	return nil;
}

// FIXME: Implement
- (NSArray *) allGroups
{
	return nil;
}

- (BOOL) isOpaque
{
	return NO;
}

- (BOOL) isOrdered
{
	return NO;
}

- (BOOL) isEmpty
{
	return ([[self objects] count] == 0);
}

- (id) content
{
	return [self objects];
}

- (NSArray *) contentArray
{
	return [self content];
}

- (void) insertObject: (id)object atIndex: (unsigned int)index
{
	[self addObject: object];
}

@end

#if 0

- (BOOL) addObject: (id) object
{
	if ([self isValidObject: object])
		return NO;

	id parentDir = [CODirectory objectWithURL: [[object URL] parentURL]]
	BOOL result = NO;

#ifdef HARD_LINK_MUTATION
	/* Handles file move by creating a hard link at destination and removing the 
	   hard link at source */
	result = [self addHardLink: object];
	if (result)
	{
		[object willAddToGroup: self];
		result = [parentDir removeObject: object]; /* Delete the previous hard link */
	}
#else
	/* Handles file move with a normal move operation */
	result = [parentDir removeObject: object];
	if (result)
	{
		/* Eventually cancel any pending removal now that a group holds it */
		[object willAddToGroup: self];
		result = [self addMovedObject: object];
	}
#endif

	return result;
}

#endif

