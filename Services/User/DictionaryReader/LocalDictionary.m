/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <Foundation/Foundation.h>

#import "LocalDictionary.h"
#import "NSScanner+Base64Encoding.h"



/**
 * A class that just encapsulates two integer ranges.
 * Needed for storing ranges in a NSDictionary.
 */
@interface BigRange : NSObject
{
  int fromIndex;
  int length;
}

+ (id)rangeFrom: (int)aFromIndex
	 length: (int)aToIndex;

- (int)fromIndex;
- (int)length;
@end


// ---------------------------

@implementation BigRange

+ (id)rangeFrom: (int)aFromIndex
	 length: (int)aLength
{
  BigRange* instance = [[BigRange alloc] init];
  if (instance != nil) {
    instance->fromIndex = aFromIndex;
    instance->length    = aLength;
  }
  return instance;
}

- (int)fromIndex
{
  return fromIndex;
}

- (int)length
{
  return length;
}

@end



// -----------------------------------

// FIXME: dealloc is missing
@implementation LocalDictionary

// INITIALISATION

/**
 * Initialises the instance by expanding the given base name using
 * the .dict and .index postfixes and looking it up as resource.
 */
-(id) initWithResourceName: (NSString*) baseName
{
  NSBundle* mainBundle = [NSBundle mainBundle];
  NSString* anIndexFile;
  NSString* aDictFile;
  
  anIndexFile = [mainBundle pathForResource: baseName ofType: @"index"];
  aDictFile = [mainBundle pathForResource: baseName ofType: @"dict"];
  
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
-(id) initWithIndexAtPath: (NSString*) anIndexFile
	 dictionaryAtPath: (NSString*) aDictFile
{
  if ((self = [super init]) != nil) {
    ASSIGN(indexFile, anIndexFile);
    ASSIGN(dictFile, aDictFile);
    opened = NO;
  }
  
  return self;
}

// MAIN FUNCTIONALITY

/**
 * Gives away the client identification string to the dictionary handle.
 */
-(void) sendClientString: (NSString*) clientName
{
  // ignored
}

/**
 * Lets the dictionary handle show handle information in the main window.
 * TODO: Rename to handleDescription!
 */
-(void) serverDescription;
{
  [NSString stringWithFormat: @"Local dictionary %@", dictFile];
}

/**
 * Lets the dictionary handle describe a specific database.
 */
-(void) descriptionForDatabase: (NSString*) aDatabase
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
-(void) definitionFor: (NSString*) aWord
{
  NSString* entry = [self _getEntryFor: aWord];
  
  if (entry != nil) {
    
    [defWriter writeHeadline:
		 [NSString stringWithFormat: @"From %@ (local):", fullName]];
    
    [defWriter writeLine: entry];
    
  } else {
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
-(void) definitionFor: (NSString*) aWord
	 inDictionary: (NSString*) aDict
{
  [self definitionFor: aWord];
}


/**
 * Returns a dictionary entry from the file as a string. If not present,
 * nil is returned.
 */
-(NSString*) _getEntryFor: (NSString*) aWord
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



// SETTING UP THE CONNECTION

/**
 * Opens the dictionary handle. Needs to be done before asking for
 * definitions.
 *
 * Reads the dictionary index from the file system and opens the
 * dictionary database file handle.
 */
-(void)open
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
  
  while ([indexScanner scanUpToString: @"\t" intoString: &word] == YES) {
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
  [scanner scanUpToString: @"\n"
	   intoString: &name];
  
  // assign it
  ASSIGN(fullName, name);
  
  
  // that's it, we've opened the database!
  opened = YES;
}

/**
 * Closes the dictionary handle. Implementing classes may close
 * network connections here.
 */
-(void)close
{
  [dictHandle closeFile];
  DESTROY(dictHandle);
  DESTROY(ranges);
}

/**
 * Provides the dictionary handle with a definition writer to write
 * its word definitions to.
 */
-(void) setDefinitionWriter: (id<DefinitionWriter>) aDefinitionWriter
{
  ASSIGN(defWriter, aDefinitionWriter);
}


-(NSString*) description
{
  if (fullName == nil) {
    return [NSString stringWithFormat: @"Local dictionary at %@", dictFile];
  } else {
    return fullName;
  }
}
@end
