/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import "LocalDictionary.h"
#import "NSScanner+Base64Encoding.h"
#import "GNUstep.h"


/**
 * A class that just encapsulates two integer ranges.
 * Needed for storing ranges in a NSDictionary.
 */
@interface BigRange : NSObject
{
	int fromIndex;
	int length;
}

+ (id)rangeFrom: (int)aFromIndex length: (int)aToIndex;

- (int)fromIndex;
- (int)length;
@end


// ---------------------------

@implementation BigRange

+ (id) rangeFrom: (int) aFromIndex length: (int) aLength
{
	BigRange* instance = [[BigRange alloc] init];
	if (instance != nil) 
	{
		instance->fromIndex = aFromIndex;
		instance->length    = aLength;
	}
	return instance;
}

- (int) fromIndex
{
	return fromIndex;
}

- (int) length
{
	return length;
}

@end

// -----------------------------------

@interface LocalDictionary (Private)
/**
 * Returns a dictionary entry from the file as a string. If not present,
 * nil is returned.
 */
-(NSString*) _getEntryFor: (NSString*) aWord;
@end


@implementation LocalDictionary

// INITIALISATION

/**
 * Returns a dictionary with the specifiled Dict-server-style index and
 * dictionary database files.
 */
+ (id) dictionaryWithIndexAtPath: (NSString *) indexFileName
                dictionaryAtPath: (NSString *) fileName
{
	LocalDictionary *dict = [[LocalDictionary alloc] 
	                                    initWithIndexAtPath: indexFileName
		                                dictionaryAtPath: fileName];
	if (dict)
		return AUTORELEASE(dict);
	else
		return nil;
}

/**
 * Initialises the DictionaryHandle from the property list aPropertyList.
 */
- (id) initFromPropertyList: (NSDictionary *) aPropertyList
{
	// FIXME: Reports the failure in a more friendly way which lets the user
	// uses the application.
	NSAssert1([aPropertyList objectForKey: @"index file"] != nil,
	          @"Property list %@ lacking 'index file' key.", aPropertyList);
	NSAssert1([aPropertyList objectForKey: @"dict file"] != nil,
	          @"Property list %@ lacking 'index file' key.", aPropertyList);
    
	if ((self = [super initFromPropertyList: aPropertyList]) != nil) 
	{
		self = [self initWithIndexAtPath: [aPropertyList objectForKey: @"index file"]
		             dictionaryAtPath: [aPropertyList objectForKey: @"dict file"]];
        
		if (self)
			ASSIGN(fullName, [aPropertyList objectForKey: @"full name"]);
	}
    
	return self;
}

/**
 * Initialises the instance by expanding the given base name using
 * the .dict and .index postfixes and looking it up as resource.
 */
- (id) initWithResourceName: (NSString *) baseName
{
	NSBundle* mainBundle = [NSBundle mainBundle];
	NSString* anIndexFile;
	NSString* aDictFile;
  
	anIndexFile = [mainBundle pathForResource: baseName ofType: @"index"];
	aDictFile = [mainBundle pathForResource: baseName ofType: @"dict"];
#warning TODO Add support for gz compressed files here
  
	NSAssert1(anIndexFile != nil,
	    @"Index resource %@ not found",
	    baseName);
  
	NSAssert1(aDictFile != nil,
	    @"Dict resource %@ not found",
	    baseName);
  
	return [self initWithIndexAtPath: anIndexFile
	                dictionaryAtPath: aDictFile];
}

/**
 * Initialises the instance with the specified Dict-server-style index
 * and dictionary database files.
 */
- (id) initWithIndexAtPath: (NSString*) anIndexFile
          dictionaryAtPath: (NSString*) aDictFile
{
	NSAssert1([anIndexFile hasSuffix: @".index"],
            @"Index file \"%@\" has no .index suffix.",
            anIndexFile
	);

	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir = NO;
	if (([fm fileExistsAtPath: anIndexFile isDirectory: &isDir] == NO) ||
	    (isDir == YES))
	{
		[self dealloc];
		self = nil;
		return nil;
	}
	if (([fm fileExistsAtPath: aDictFile isDirectory: &isDir] == NO) ||
	    (isDir == YES))
	{
		[self dealloc];
		self = nil;
		return nil;
	}
  
	NSAssert1([aDictFile hasSuffix: @".dict"]
#ifdef GNUSTEP
	          // only GNUstep supports on-the-fly gunzipping right now
	          || [aDictFile hasSuffix: @".dz"]
#endif // GNUSTEP
	          , @"Dict file \"%@\" has a bad suffix (must be .dict"
#ifdef GNUSTEP
	          @" or .dz"
#endif // GNUSTEP
	          @").",
	          aDictFile
	);
  
	if ((self = [super init]) != nil) 
	{
		ASSIGN(indexFile, anIndexFile);
		ASSIGN(dictFile, aDictFile);
		opened = NO;
	}
  
	return self;
}

- (void) dealloc
{
	// first close connection, if open
	[self close];

	// NOTE: dictHandle and ranges are currently destroyed in -close, 
	// but it must be checked whether that makes sense or not.
	//DESTROY(dictHandle);
	//DESTROY(ranges);
	DESTROY(indexFile);
	DESTROY(dictFile);
	DESTROY(fullName);
  
	[super dealloc];
}

/** To know whether two local dictionaries are equal we check if they have the
	the same host. */
- (unsigned long) hash
{
	return [dictFile hash] ^ [indexFile hash];
}

- (BOOL) isEqual: (id) object
{
	if ([object isKindOfClass: [self class]])
	{
		LocalDictionary *dict = (LocalDictionary *) object;
		if ([[self index] isEqual: [dict index]] &&
		    [[self dictionary] isEqual: [dict dictionary]])
		{
			return YES;
		}
	}
	
	return NO;
}

// MAIN FUNCTIONALITY

- (NSString *) index
{
	return indexFile;
}

- (NSString *) dictionary
{
	return dictFile;
}

- (NSString *) fullName
{
	return fullName;
}

/**
 * Lets the dictionary handle show handle information in the main window.
 */
-(void) handleDescription;
{
	[NSString stringWithFormat: @"Local dictionary %@", dictFile];
}

/**
 * Lets the dictionary handle describe a specific database.
 */
- (void) descriptionForDatabase: (NSString *) aDatabase
{
	// we ignore the argument here
  
	[defWriter writeLine:
	       [NSString stringWithFormat: @"Index file %@", indexFile]];
	[defWriter writeLine:
	       [NSString stringWithFormat: @"Database file %@", dictFile]];
	[defWriter writeLine:
	       (opened)?@"Connection is opened":@"Connection is closed"];
  
	[defWriter writeLine: @"\nDatabase information"];
  
	[self definitionFor: @"00-database-info"];
}

/**
 * Lets the dictionary handle print all available definitions
 * for aWord in the main window.
 */
- (void) definitionFor: (NSString *) aWord
{
	NSString* entry = [self _getEntryFor: aWord];
  
	if (entry != nil) 
	{
		[defWriter writeHeadline:
		    [NSString stringWithFormat: @"From %@ (local):", fullName]];
    
		[defWriter writeLine: entry];
	}
	else 
	{
		[defWriter writeHeadline:
	        [NSString stringWithFormat: @"No results from %@", self]];
	}
}

/**
 * Lets the dictionary handle print the defintion for aWord
 * in a specific dictionary. (Note: The dictionary handle may
 * represent multiple dictionaries.)
 *
 * This implementation just calls definitionFor:.
 */
- (void) definitionFor: (NSString *) aWord inDictionary: (NSString*) aDict
{
	[self definitionFor: aWord];
}





// SETTING UP THE CONNECTION

/**
 * Opens the dictionary handle. Needs to be done before asking for
 * definitions.
 *
 * Reads the dictionary index from the file system and opens the
 * dictionary database file handle.
 */
- (void) open
{
	NSString* indexStr;
	NSScanner* indexScanner;
  
	if (opened == YES)
		return;
  
	indexStr = [NSString stringWithContentsOfFile: indexFile];
  
	NSAssert1(indexStr != nil, @"Index file %@ could not be opened!", indexFile);
  
	indexScanner = [NSScanner scannerWithString: indexStr];
  
	NSString* word = nil;
	int fromLocation;
	int length;
	NSMutableDictionary* dict;
  
	dict = [NSMutableDictionary dictionary];
  
	while ([indexScanner scanUpToString: @"\t" intoString: &word] == YES) 
	{
		// wow, we scanned a word! :-)
    
		// consume first tab
		[indexScanner scanString: @"\t" intoString: NULL];
    
		// scan the start location of the dictionary entry
		[indexScanner scanBase64Int: &fromLocation];
    
		// consume second tab
		[indexScanner scanString: @"\t" intoString: NULL];
    
		// scan the length of the dictionary entry
		[indexScanner scanBase64Int: &length];
    
		// scan newline
		[indexScanner scanString: @"\n" intoString: NULL];
    
		// save entry in index -------------------------------------------
		[dict setObject: [BigRange rangeFrom: fromLocation length: length]
		         forKey: [word capitalizedString]];
	}
  
	ASSIGN(ranges, [NSDictionary dictionaryWithDictionary: dict]);
	NSAssert1(ranges != nil,
	          @"Couldn't generate dictionary index from %@", indexFile);
  
	ASSIGN(dictHandle, [NSFileHandle fileHandleForReadingAtPath: dictFile]);
	NSAssert1(dictHandle != nil,
	          @"Couldn't open the file handle for %@", dictFile);
#ifdef GNUSTEP
	// Enable on-the-fly Gunzipping if needed
	if ([dictFile hasSuffix: @".dz"]) 
	{
		NSAssert([dictHandle useCompression] == YES,
	             @"Using compression failed, please enable zlib support when compiling GNUstep!"
		);
	}
#endif // GNUSTEP
  
	// Retrieve full name of database! ------------
	NSString* name = [self _getEntryFor: @"00-database-short"];
	NSScanner* scanner = [NSScanner scannerWithString: name];
  
	// consume first line (don't need it, it reads 00-database-short. ;-))
	[scanner scanUpToString: @"\n" intoString: NULL];
  
	// consume newline
	[scanner scanString: @"\n" intoString: NULL];
  
	// consume first few whitespaces
	[scanner scanCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
	                    intoString: NULL];
  
	// get the name itself
	[scanner scanUpToString: @"\n" intoString: &name];
  
	// assign it
	ASSIGN(fullName, name);
  
	// that's it, we've opened the database!
	opened = YES;
}

/**
 * Closes the dictionary handle. Implementing classes may close
 * network connections here.
 */
- (void) close
{
	[dictHandle closeFile];
	DESTROY(dictHandle);
	DESTROY(ranges);
	opened = NO;
}

/**
 * Returns a short property list used for storing short information about this
 * dictionary handle.
 */
- (NSDictionary *) shortPropertyList
{
	NSMutableDictionary* result = [super shortPropertyList];
    
	[result setObject: indexFile forKey: @"index file"];
	[result setObject: dictFile forKey: @"dict file"];
    
	if (fullName != nil) 
	{
		[result setObject: fullName forKey: @"full name"];
	}
    
	return result;
}

- (NSString *) description
{
	if (fullName == nil) 
	{
		return [dictFile lastPathComponent]; // e.g. jargon.dict
	}
	else 
	{
		return fullName;
	}
}
@end

@implementation LocalDictionary (Private)

/**
 * Returns a dictionary entry from the file as a string. If not present,
 * nil is returned.
 */
- (NSString *) _getEntryFor: (NSString *) aWord
{
	NSAssert1(dictHandle != nil, @"Dictionary file %@ not opened!", dictFile);
  
	// get range of entry
	BigRange* range = [ranges objectForKey: [aWord capitalizedString]];
  
	if (range == nil)
		return nil;
  
	// seek there
	[dictHandle seekToFileOffset: [range fromIndex]];
  
	// retrieve entry as data
	NSData* data = [dictHandle readDataOfLength: [range length]];
  
	// convert it to a string
	// XXX: Which encoding are dict-server-like dictionaries stored in?!
	NSString* entry = [[NSString alloc] initWithData: data
	                                        encoding: NSASCIIStringEncoding];
  
	return AUTORELEASE(entry);
}

@end
