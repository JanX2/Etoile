/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "DictionaryHandle.h"

@interface LocalDictionary: DictionaryHandle
{
	@private
  
	// the handle for the dictionary file
	NSFileHandle* dictHandle;
  
	// the ranges of the articles
	NSDictionary* ranges;
  
	NSString* indexFile;
	NSString* dictFile;
	NSString* fullName;
  
	BOOL opened;
}

/**
 * Initialises the instance by expanding the given base name using
 * the .dict and .index postfixes and looking it up as resource.
 */
- (id) initWithResourceName: (NSString *) baseName;

/**
 * Initialises the instance with the specified Dict-server-style index
 * and dictionary database files.
 */
- (id) initWithIndexAtPath: (NSString *) indexFile
          dictionaryAtPath: (NSString *) dbFile;


/**
 * Returns a dictionary with the specifiled Dict-server-style index and
 * dictionary database files.
 */
+ (id) dictionaryWithIndexAtPath: (NSString *) indexFileName
                dictionaryAtPath: (NSString *) fileName;



// MAIN FUNCTIONALITY

- (NSString *) index;
- (NSString *) dictionary;
- (NSString*) fullName;

@end

