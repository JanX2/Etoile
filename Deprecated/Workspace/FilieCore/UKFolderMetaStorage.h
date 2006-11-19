/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFolderMetaStorage.h
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-11-30  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <EtoileExtensions/EtoileCompatibility.h>
#import <Cocoa/Cocoa.h>

@protocol UKTest;

// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

@interface UKFolderMetaStorage : NSObject <UKTest>
{
    NSMutableDictionary*    storage;        // Cached storage loaded from disk.
    NSURL*                  folderURL;      // Folder URL which we use to decide where to save our info.
}

+(id)                   storageForURL: (NSURL*)url;

-(id)                   initForURL: (NSURL*)url;

-(void)                 setObject: (id)obj forKey: (NSString*)key;
-(id)                   objectForKey: (NSString*)key;

-(NSMutableDictionary*) dictionaryForFile: (NSString*)filename;     // Returns nil if info dictionary doesn't exist.
-(NSMutableDictionary*) newDictionaryForFile: (NSString*)filename;  // Creates info dictionary if none exists.

-(void)                 setDisplayRect: (NSRect)box;
-(NSRect)               displayRect;

-(BOOL)                 synchronize;
-(void)                 clean;

-(NSURL*)               folderURL;
-(NSURL*)               storageFileURL;

-(BOOL)                 isEmpty;

@end
