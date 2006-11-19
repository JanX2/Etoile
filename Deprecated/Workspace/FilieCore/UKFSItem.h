/* =============================================================================
    PROJECT:    Filie
    FILE:       UKFSItem.h
    
    COPYRIGHT:  (c) 2004 by M. Uli Kusterer, all rights reserved.
    
    AUTHORS:    M. Uli Kusterer - UK
    
    LICENSES:   GNU GPL
    
    REVISIONS:
        2004-04-16  UK  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#import <EtoileExtensions/EtoileCompatibility.h>

@protocol UKTest;

// -----------------------------------------------------------------------------
//  Forwards:
// -----------------------------------------------------------------------------

@class UKFSItem;
@class UKFileInfoPanel;

// -----------------------------------------------------------------------------
//  Protocols:
// -----------------------------------------------------------------------------

// Protocol our owning viewer has to respond to:
@protocol UKFSItemOwner

-(void)                 itemNeedsDisplay: (UKFSItem*)item;
-(void)                 loadItemIcon: (UKFSItem*)item;
-(BOOL)                 itemIsVisible: (UKFSItem*)item;
-(BOOL)                 showIconPreview;
-(NSSize)               iconSizeForItem: (UKFSItem*)item;
-(void)                 loadItemIcon: (UKFSItem*)item;
-(id)                   fsDataSource;

@end


// Protocol the various kinds of items must implement:
@protocol UKFSItem

-(id)			initWithURL: (NSURL*)furl isDirectory: (BOOL)n withAttributes: (NSDictionary*)attrs owner: (id<UKFSItemOwner>)viewer;

-(NSString *)	path;
-(void)			setPath: (NSString *)newPath;

-(NSImage*)		icon;
-(NSColor*)     labelColor;

-(NSSize)		iconSize;

-(NSString*)	displayName;

-(NSString*)    name;
-(void)         setName: (NSString*)nameStr;

-(void)         setPosition: (NSPoint)pos;
-(NSPoint)      position;

-(NSDictionary*)    attributes;
-(void)             setAttributes: (NSDictionary*)dict;
-(BOOL)             isDirectory;

#ifndef __ETOILE__
-(void)			openViewer: (id)sender;
#endif

-(void)			openInfoPanel: (id)sender;

@end


// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

// File system item class:
@interface UKFSItem : NSObject <UKFSItem,UKTest>
{
	NSString*				path;			// Path to the item we're associated with.
	NSString*				displayName;	// Name to display for this item.
	NSImage*				icon;			// Icon to display for this item.
	BOOL					isDirectory;	// Is this a directory or a file? (may be possible to get rid of this and always check attributes dictionary?)
	NSSize					iconSize;		// Size to scale icon to. (changed by the viewer as needed -- maybe we want to always query owner?)
    id <UKFSItemOwner>		owningViewer;   // Viewer we are owned by. Not retained, as it retains us and we don't want circles.
    NSDictionary*			attributes;     // File attributes dictionary.
    NSPoint					position;       // Position of this item in its distributed view.
    UKFileInfoPanel*		infoPanel;      // Information window for this object (NIL if none open).
	#ifdef __ETOILE__
	NSMutableDictionary*	locks;
	#endif
}

-(id)			initWithPath: (NSString*)fpath isDirectory: (BOOL)n withAttributes: (NSDictionary*)attrs owner: (id<UKFSItemOwner>)viewer;

-(NSString *)	path;
-(void)			setPath: (NSString *)newPath;

-(NSImage*)		icon;
-(NSColor*)     labelColor;

-(NSSize)		iconSize;
-(void)			setIconSize: (NSSize)newIconSize;

-(NSString*)	displayName;
-(void)			setDisplayName: (NSString *)newDisplayName;

-(NSString*)    name;
-(void)         setName: (NSString*)nameStr;

-(NSDictionary*)    attributes;
-(BOOL)             isDirectory;

-(void)         setPosition: (NSPoint)pos;
-(NSPoint)      position;

#ifndef __ETOILE__
-(void)			openViewer: (id)sender;
#endif

// Private:
-(void)			loadItemIcon: (id)sender;

@end
