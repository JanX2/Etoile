/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFolderMetaStorage.m
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-11-30  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKFolderMetaStorage.h"


@implementation UKFolderMetaStorage

// -----------------------------------------------------------------------------
//  storageForURL:
//      Factory method that creates a storage object for an item (usually a
//      file) that has the specified URL. Calls initForURL:.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

+(id)                   storageForURL: (NSURL*)url
{
    return [[[[self class] alloc] initForURL: url] autorelease];
}


// -----------------------------------------------------------------------------
//  initForURL:
//      Constructor that creates a storage object for an item (usually a
//      file) that has the specified URL.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)                   initForURL: (NSURL*)url
{
    self = [super init];
    if( !self )
        return nil;
    
    folderURL = [url retain];
    
    NSURL*  storeURL = [self storageFileURL];
    NSData* data = [NSData dataWithContentsOfURL: storeURL];
    if( data )
    {
        NS_DURING
            storage = [[NSUnarchiver unarchiveObjectWithData: data] retain];
        NS_HANDLER
            NSLog(@"Error loading meta storage file %@",storeURL);
            storage = nil;
        NS_ENDHANDLER
    }
    if( !storage )
        storage = [[NSMutableDictionary alloc] init];
    
    return self;
}


// -----------------------------------------------------------------------------
//  dealloc:
//      Destructor.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void) dealloc
{
    [self synchronize];
    
    [storage release];
    [folderURL release];
    
    [super dealloc];
}


// -----------------------------------------------------------------------------
//  setObject:forKey:
//      Attach a property with the specified key/value combination to the
//      file/folder represented by this storage. Used to e.g. keep around the
//      dimensions of the window displayed for a folder.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)                 setObject: (id)obj forKey: (NSString*)key
{
    [storage setObject: obj forKey: key];
}


// -----------------------------------------------------------------------------
//  objectForKey:
//      Return a property of the storage's file based on its key. Counterpart
//      to setObject:forKey:.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)                   objectForKey: (NSString*)key
{
    return [storage objectForKey: key];
}


// -----------------------------------------------------------------------------
//  dictionaryForFile:
//      Return a dictionary of properties for a particular file in this storage,
//      specified by its name (not by its path). This usually only makes sense
//      if this storage is for a folder or smart folder which may contain other
//      files.
//
//      Returns NIL if there is no information for a file of that name in the
//      storage yet.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSMutableDictionary*) dictionaryForFile: (NSString*)filename
{
    NSMutableDictionary*    dict = [storage objectForKey: @"FileInfo"];
    
    return [dict objectForKey: filename];
}


// -----------------------------------------------------------------------------
//  newDictionaryForFile:
//      Like dictionaryForFile:, but this creates a dictionary and associates
//      it with the specified file name if there isn't one yet.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSMutableDictionary*) newDictionaryForFile: (NSString*)filename
{
    NSMutableDictionary*    dict = [storage objectForKey: @"FileInfo"];
    if( !dict )
    {
        dict = [NSMutableDictionary dictionary];
        [storage setObject: dict forKey: @"FileInfo"];
    }
    
    NSMutableDictionary*    info = [dict objectForKey: filename];
    
    if( !info )
    {
        info = [NSMutableDictionary dictionary];
        [dict setObject: info forKey: filename];
    }
    
    return info;
}


// -----------------------------------------------------------------------------
//  synchronize:
//      Write changes made to the storage to disk.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)                 synchronize
{
    NSURL*  storeURL = [self storageFileURL];
    NSData* data = [NSArchiver archivedDataWithRootObject: storage];
    
    return [data writeToURL: storeURL atomically: NO];
}


// -----------------------------------------------------------------------------
//  clean:
//      Remove any unused entries for files that no longer exist from the
//      storage. Not yet implemented. Should probably change to use the file
//      data source to find out whether a file exists.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)                 clean
{
    
}


// -----------------------------------------------------------------------------
//  setDisplayRect:
//      Shorthand for storing the @"DisplayRect" property in the storage. Used
//      for saving position and dimensions of the window.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(void)                 setDisplayRect: (NSRect)box
{
    [storage setObject: [NSValue valueWithRect: box] forKey: @"DisplayRect"];
}


// -----------------------------------------------------------------------------
//  displayRect:
//      Shorthand for getting the @"DisplayRect" property from the storage.
//      Counterpart to setDisplayRect:.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSRect)               displayRect
{
    NSValue*    val = [storage objectForKey: @"DisplayRect"];
    
    if( !val )
        return NSMakeRect(50,50,512,342);
    
    return [val rectValue];
}


// -----------------------------------------------------------------------------
//  folderURL:
//      Return the URL for which this storage was created. This is the URL
//      passed to initForURL.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSURL*)               folderURL
{
    return folderURL;
}


// -----------------------------------------------------------------------------
//  storageFileURL:
//      Return the URL for the on-disk file used for the storage. Used
//      internally to make it easy to change the scheme used.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSURL*)               storageFileURL
{
    NSString*   storageFolder = nil;
    NSString*   theName = nil;
    
    // Pre-generate some path stuff we may need:
    storageFolder = [@"~/Library/Application Support/Filie/" stringByExpandingTildeInPath];
    if( ![[NSFileManager defaultManager] fileExistsAtPath: storageFolder] )
        [[NSFileManager defaultManager] createDirectoryAtPath:storageFolder attributes:[NSDictionary dictionary]];
    
    storageFolder = [storageFolder stringByAppendingPathComponent: @"Meta Data"];
    if( ![[NSFileManager defaultManager] fileExistsAtPath: storageFolder] )
        [[NSFileManager defaultManager] createDirectoryAtPath:storageFolder attributes:[NSDictionary dictionary]];

    // Remote URL or so? Generate local storage file:
    if( ![folderURL isFileURL] )
    {
        theName = [[folderURL absoluteString] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
        return [NSURL fileURLWithPath: [storageFolder stringByAppendingPathComponent: theName]];
    }
    
    // Generate path for .Filie_Store file, if that isn't writable, generate local storage file:
    NSString*   storePath = [[folderURL path] stringByAppendingPathComponent: @".Filie_Store"];
    
    if( [[[NSFileManager defaultManager] fileSystemAttributesAtPath: storePath] fileIsImmutable] )
    {
        theName = [[folderURL absoluteString] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
        return [NSURL fileURLWithPath: [storageFolder stringByAppendingPathComponent: theName]];
    }
    else
        return [NSURL fileURLWithPath: storePath];
}


// -----------------------------------------------------------------------------
//  isEmpty:
//      Returns YES if this is a new, empty storage. You can use this to
//      optimize your code when a folder is initially loaded.
//
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)     isEmpty
{
    NSDictionary*   infos = [storage objectForKey: @"FileInfo"];
    
    return( !infos || [infos count] == 0 );
}


@end
