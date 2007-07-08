/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#ifndef _DICTIONARY_H_
#define _DICTIONARY_H_

#import <Foundation/Foundation.h>
#import "Definition.h"

/**
 * The dictionary handle class
 */
@interface DictionaryHandle: NSObject
{
	BOOL _active;
}

+ (id) dictionaryFromPropertyList: (NSDictionary *) aPropertyList;

/**
 * Initialises the DictionaryHandle from the property list aPropertyList.
 */
- (id) initFromPropertyList: (NSDictionary *) aPropertyList;

/**
 * Lets the dictionary handle show handle information in the main window.
 */
- (void) handleDescription;

/**
 * Lets the dictionary handle describe a specific database.
 */
- (void) descriptionForDatabase: (NSString *) aDatabase;

/**
 * Get definition (synchronized) or error
 */
- (NSArray *) definitionsFor: (NSString *) aWord error: (NSString **) error;

/**
 * Get definition (synchronized) or error
 * (Note: The dictionary handle may represent multiple dictionaries.)
 */
- (NSArray *) definitionsFor: (NSString *) aWord 
                inDictionary: (NSString *) aDict
                       error: (NSString **) error;

// SETTING UP THE CONNECTION

/**
 * Opens the dictionary handle. Needs to be done before asking for
 * definitions. Implementing classes may open network connections
 * here.
 */
- (void)open;

/**
 * Closes the dictionary handle. Implementing classes may close
 * network connections here.
 */
- (void)close;

/**
 * Returns a NSDictionary instance that shortly describes the dictionary so
 * that it can be restored again using the initFromPropertyList: method. The
 * key @"class" must be present and the corresponding object must be the class
 * name of the DictionaryHandle class.
 */
- (NSDictionary *) shortPropertyList;

/**
 * Returns YES if and only if the dictionary is active
 */
- (BOOL) isActive;

/**
 * Sets if the dictionary is active
 */
- (void) setActive: (BOOL) isActive;

/**
 * Show error on defition writer.
 */
- (void) showError: (NSString *) aString;

/**
 * Debug purpose.
 */
- (void) log: (NSString *) aString;
@end

#endif // _DICTIONARY_H_
