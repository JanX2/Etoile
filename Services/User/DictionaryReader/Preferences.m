/*
 *  DictionaryReader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <Preferences.h>

#import <Foundation/Foundation.h>

#import <DictConnection.h>
#import <LocalDictionary.h>
#import "GNUstep.h"

@implementation Preferences

// Singleton
+(id)shared {
    static Preferences* sharedPreferences = nil;
    
    if (sharedPreferences == nil) {
        sharedPreferences = [[Preferences alloc] init];
    }
    
    return sharedPreferences;
}


-(void)setDictionaries: (NSMutableArray*) dicts
{
  NSParameterAssert(dicts != nil);
  NSAssert(_dictionaries == nil || _dictionaries == dicts,
           @"You can't set the dictionary handle array twice and to different"
           @" values for the preferences panel.");
  
  int i;
  for (i=0; i<[dicts count]; i++) {
      NSAssert2([[dicts objectAtIndex: i] isKindOfClass: [DictionaryHandle class]],
               @"'%@' is not a Dictionary Handle object but a %@ object!",
               [dicts objectAtIndex: i],
               [dicts class]
      );
  }
  
  ASSIGN(_dictionaries, dicts);
  
  [_tableView reloadData];
}

-(void)rescanDictionaries: (id)sender
{
  NSAssert(_dictionaries != nil,
           @"The preference panel must be given a dictionary handle list!");

  // NOTE: Before releasing all dictionaries, take care to close all open 
  // connections to avoid a crash.

  /* Remove all dictionaries before rescan */
  [_dictionaries removeAllObjects];
  
  [self searchWithDictionaryStoreFile];
  [self searchInUsualPlaces];
  
  // default remote dictionary: dict.org
  DictConnection* dict =
     [[DictConnection alloc] init];
  [self foundDictionary: dict];
  [dict release];
  
  NSLog(@"recanned: %@", _dictionaries);
  
  [_tableView reloadData];
}


-(void)show {
    [_prefPanel orderFront: self];
}

-(void)hide {
    [_prefPanel setReleasedWhenClosed: NO];
    [_prefPanel close];
}
@end



@implementation Preferences (SearchForDictionaries)

-(NSString*) dictionaryStoreFile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [@"~/GNUstep/Library/DictionaryReader" stringByExpandingTildeInPath];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath: path isDirectory: &isDir] == NO)
    {
      /* Directory does not exist, create it */
      if ([fm createDirectoryAtPath: path attributes: nil] == NO)
      {
        /* Cannot create path */
        NSLog(@"Error: cannot create ~/GNUstep/Library/DictionaryReader/");
        return nil;
      }
    }
    else if (isDir == NO)
    {
      /* path exist, but not a directory */
      NSLog(@"Error: ~/GNUstep/Library/DictionaryReader is not a directory");
      return nil;
    }
    /* path exists, and is a directory. do nothing */

    return [path stringByAppendingPathComponent: @"dictionaries.plist"];
}

-(void) foundDictionary: (id)aDictionary
{
    if (aDictionary != nil && [_dictionaries containsObject: aDictionary] == NO) {
        [aDictionary setDefinitionWriter: [NSApp delegate]];
        [aDictionary setActive: YES];
        [_dictionaries addObject: aDictionary];
    }
}

- (void) searchWithDictionaryStoreFile
{
	NSString* dictStoreFile = [self dictionaryStoreFile];

	if ([[NSFileManager defaultManager] fileExistsAtPath: dictStoreFile]) {
	   NSArray* plist = [NSArray arrayWithContentsOfFile: [self dictionaryStoreFile]];
	   int i;
	   for (i=0; i<[plist count]; i++) {
	       DictionaryHandle* dict =
		   [DictionaryHandle dictionaryFromPropertyList: [plist objectAtIndex: i]];
	       [self foundDictionary: dict];
	       NSLog(@" *** Added %@", dict);
	   }
	   NSLog(@" *** result: %@", _dictionaries);
	}
}

-(void) searchInUsualPlaces
{
    NSArray* searchPaths = [NSArray arrayWithObjects:
        @"~/GNUstep/Library/DictionaryReader/Dictionaries",  // user home
#warning TODO Please add the default dictionary location for your operating system here (and comment appropriately!)
        nil
    ];
    
    int i;
    for (i=0; i<[searchPaths count]; i++) {
        [self searchInDirectory:
            [[searchPaths objectAtIndex: i] stringByExpandingTildeInPath]];
    }
}

-(void) searchInDirectory: (NSString*) dirName;
{
    NSFileManager* manager = [NSFileManager defaultManager];
    NSArray* files = [manager directoryContentsAtPath: dirName];
    
    if (files == nil)
        return; // directory not present
    
    if ([files count] == 0)
        return; // directory empty
    
    int i;
    for (i=0; i<[files count]; i++) {
        NSString* fileName = [files objectAtIndex: i];
        NSString* pathExtension = [fileName pathExtension];
        NSString* indexFileName;
        
        if ([pathExtension isEqualToString: @"dict"]
#ifdef GNUSTEP
            || [pathExtension isEqualToString: @"dz"]
#endif // GNUSTEP
           ) {
            // Find out the index file name by cutting all path extensions, then adding .index!
            indexFileName = fileName;
            do {
                indexFileName = [indexFileName stringByDeletingPathExtension];
            } while ([[indexFileName pathExtension] isEqualToString: @""] == NO);
            indexFileName = [indexFileName stringByAppendingPathExtension: @"index"];
            
            if ([files containsObject: indexFileName]) {
                indexFileName = [dirName stringByAppendingPathComponent: indexFileName];
                fileName      = [dirName stringByAppendingPathComponent: fileName];
                
                LocalDictionary* dict =
                  [LocalDictionary dictionaryWithIndexAtPath: indexFileName
                                            dictionaryAtPath: fileName];
                
                [self foundDictionary: dict];
            }
        }
    }
}

@end



/**
 * Responding to TableView delegate messages
 */
@implementation Preferences (DictionarySelectionDataSource)

/**
 * Returns the number of rows in the dictionary selection table.
 */
- (int) numberOfRowsInTableView: (NSTableView *)aTableView
{
    return [_dictionaries count];
}

/**
 * This is called when the object value for a table cell changes.
 * This is where the dictionary selection gets changed.
 */
-(void) tableView: (NSTableView*) aTableView
   setObjectValue: (id) anObj
   forTableColumn: (NSTableColumn*) aTableColumn
	      row: (int) rowIndex
{
  if ([[aTableColumn identifier] isEqualToString: @"active"]) {
      [[_dictionaries objectAtIndex: rowIndex] setActive: [anObj intValue]];
      
      [[NSNotificationCenter defaultCenter] postNotificationName: DRActiveDictsChangedNotification
                                                          object: _dictionaries];
  }
}

/**
 * Returns the value of a table cell.
 */
- (id) tableView: (NSTableView *)aTableView
objectValueForTableColumn: (NSTableColumn *)aTableColumn
             row: (int)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString: @"active"]) {
      return [NSNumber numberWithBool: [[_dictionaries objectAtIndex: rowIndex] isActive]];
    } else {
      NSAssert1(
          [[aTableColumn identifier] isEqualToString: @"name"],
          @"Unknown column identifier '%@'",
          [aTableColumn identifier]
      );
      
      return [[_dictionaries objectAtIndex: rowIndex] description];
    }
}

- (void) awakeFromNib
{
    NSButtonCell* cell = [[_tableView tableColumnWithIdentifier: @"active"] dataCell];
    [cell setEditable: YES];
    [cell setEnabled: YES];
    [cell setSelectable: YES];
    [cell setTitle: @""];
    
    [cell setButtonType: NSSwitchButton];
}

@end

