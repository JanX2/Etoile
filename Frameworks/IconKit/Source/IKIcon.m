/*
 *  IKIcon.m
 *  
 *
 *  Created by Uli Kusterer on 31.12.04.
 *  Copyright 2004 M. Uli Kusterer. All rights reserved.
 *
 */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#include "IKIcon.h"


// -----------------------------------------------------------------------------
//  Constants:
// -----------------------------------------------------------------------------

// The values of the following should probably be the file names of the icon files:
//  However, the names I've chosen so far are the ones that
//  NSStringFromIconIdentifier() should return for each icon, so if you change
//  one of these, make sure you change that function to still return this string
//  for that icon identifier so apps that save icon identifiers to disk using
//  NSStringFromIconIdentifier() create the same files on OS X and GNUstep.

IKIconIdentifier    IKIconGenericDocument =     @"GenericFolder";
IKIconIdentifier    IKIconGenericApplication =  @"GenericApplication";
IKIconIdentifier    IKIconGenericPlugIn =       @"GenericPlugIn";
IKIconIdentifier    IKIconGenericFolder =       @"GenericFolder";
IKIconIdentifier    IKIconPrivateFolder =       @"PrivateFolder";
IKIconIdentifier    IKIconWriteOnlyFolder =     @"WriteOnlyFolder";
IKIconIdentifier    IKIconRecyclerFolder =      @"RecyclerFolder";
IKIconIdentifier    IKIconRecyclerFolderFull =  @"RecyclerFolderFull";
// ...
IKIconIdentifier    IKIconLinkBadge =       @"LinkBadge"
IKIconIdentifier    IKIconLockedBadge =     @"LockedBadge";
IKIconIdentifier    IKIconScriptBadge =     @"ScriptBadge";
IKIconIdentifier    IKIconReadOnlyBadge =   @"ReadOnlyBadge";
IKIconIdentifier    IKIconWriteOnlyBadge =  @"WriteOnlyBadge";

// System icons (not for files):
IKIconIdentifier    IKIconAlertNote =       @"AlertNote";
IKIconIdentifier    IKIconAlertWarning =    @"AlertWarning";
IKIconIdentifier    IKIconAlertFailure =    @"AlertFailure";

// Notifications:
NSString*            IKIconChangedNotification = @"IKIconChangedNotification";  // Sent with the IKIcon as the object whenever update is called.


// -----------------------------------------------------------------------------
//  Implementation:
// -----------------------------------------------------------------------------

@implementation IKIcon

// -----------------------------------------------------------------------------
//  Convenience Factory Methods:
// -----------------------------------------------------------------------------

+(id)       iconForFile: (NSString*)fpath
{
    return [[(IKIcon*)[self alloc] initForFile: fpath] autorelease];
}


+(id)       iconForURL: (NSURL*)fpath
{
    return [[(IKIcon*)[self alloc] initForURL: fpath] autorelease];
}


+(id)       iconWithIdentifier: (IKIconIdentifier)ident
{
    return [[(IKIcon*)[self alloc] initWithIdentifier: ident] autorelease];
}


+(id)       iconWithExtension: (NSString*)suffix mimeType: (NSString*)mime
                attributes: (NSDictionary*)dict
{
    return [[[self alloc] initWithExtension: suffix mimeType: mime attributes: dict] autorelease];
}


+(id)       iconWithSize: (NSSize)size
{
    return [[[self alloc] initWithSize: size] autorelease];
}

+(id)       iconWithImage: (NSImage*)image
{
    return [[[self alloc] initWithImage: image] autorelease];
}


// -----------------------------------------------------------------------------
//  Constructors:
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
//  initForFile:
//      Return an icon for a particular file. This may give you a cached
//      object instead of the one you alloced originally.
//
//      TODO: We could probably write a variant of this that takes a
//      fileAttributes dictionary. That would be faster
//      in cases where we're querying the attributes anyway.
//
//  REVISIONS:
//      2005-02-13  UK  Ripped out IconServices stuff to make this port to
//                      GNUstep.
//      2005-02-09  UK  Renamed to initForFile: to make clear it gets the icon
//                      *for* the file, not *from* it.
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(id)   initForFile: (NSString*)fpath
{
    self = [super init];
    if( !self )
        return nil;
    
    image = [[[NSWorkspace sharedWorkspace] iconForFile: fpath] retain];   // FIX ME! Causes endless recursion with NSWorkspace overrides. Change this to use Quentin's code so we can activate NSWorkspaceAdditions.
    lock = [[NSRecursiveLock alloc] init];
    
    return self;
}


// -----------------------------------------------------------------------------
//  initForURL:
//      Same as initForFile:, but takes an NSURL instead of an NSString path.
//  
//  REVISIONS:
//      2005-02-15  UK  Created.
// -----------------------------------------------------------------------------

-(id)   initForURL: (NSURL*)fpath
{
    if( [fpath isFileURL] )
        return [self initForFile: [fpath path]];
    else
        return [self initWithIdentifier: IKIconGenericDocument];    // FIX ME! Should try to use extension and maybe find out whether it's a directory!
}


// -----------------------------------------------------------------------------
//  initWithIdentifier:
//      Return one of the standard system icons. This can also be used for
//      standard alert icons or whatever else you want.
//  
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

-(id)       initWithIdentifier: (IKIconIdentifier)ident
{
    self = [super init];
    if( !self )
        return nil;
    
    image = [[NSImage imageNamed: ident] retain];
    identifier = [ident retain];
    lock = [[NSRecursiveLock alloc] init];
    
    return self;
}


// -----------------------------------------------------------------------------
//  initWithExtension:mimeType:attributes:
//      Return an icon for a file with the specified characteristics. Any of
//      the parameters may be NIL, which will assume sensible defaults or try
//      to perform the lookup without taking into account the additional info.
//  
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

-(id)       initWithExtension: (NSString*)suffix mimeType: (NSString*)mime
                attributes: (NSDictionary*)dict
{
    self = [super init];
    if( !self )
        return nil;
    
    image = [[[NSWorkspace sharedWorkspace] iconForFileType: suffix] retain];   // FIX ME! Causes endless recursion with NSWorkspace overrides. Change this to use Quentin's code so we can activate NSWorkspaceAdditions.
    lock = [[NSRecursiveLock alloc] init];
    
    return self;
}


// -----------------------------------------------------------------------------
//  initWithSize:
//      Create a new, empty icon with the specified size.
//  
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

-(id)       initWithSize: (NSSize)size
{
    return [self initWithImage: [[[NSImage alloc] initWithSize: size] autorelease]];
}


// -----------------------------------------------------------------------------
//  initWithImage:
//      Create a new icon with the specified image.
//  
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

-(id)       initWithImage: (NSImage*)img
{
    self = [super init];
    if( !self )
        return nil;
    
    image = [img retain];
    lock = [[NSRecursiveLock alloc] init];
    
    return self;
}


// -----------------------------------------------------------------------------
//  initWithDictionary:
//      Return the final icon from the compositing sequence specified in this
//      property list. This is the counterpart to -dictionaryRepresentation.
//  
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

-(id)       initWithDictionary: (NSDictionary*)plist
{
    return nil;
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
    [lock lock];
        [image release];
        image = nil;
        [identifier release];
        identifier = nil;
        [lock release];
        lock = nil;
    [super dealloc];
}


// -----------------------------------------------------------------------------
//  size:
//      Return the size of this icon.
// -----------------------------------------------------------------------------

-(NSSize)   size
{
    [lock lock];
        NSSize sz = [image size];
    [lock unlock];
    
    return sz;
}


// -----------------------------------------------------------------------------
//  image:
//      Returns an NSImage of our icon ref. This NSImage contains an
//      IKIconRefImageRep, which calls drawRect: on this icon ref to take care
//      of nicely scaling the icon as needed.
//
//      We don't retain this NSImage because it would cause a circle where the
//      ImageRep retains us, and we retain it. And anyway, an iconRef image rep
//      is lightweight.
//
//  REVISIONS:
//      2005-02-11  UK  Changed to use IKIconRefImageRep instead of manually
//                      assembling an NSImage with several reps.
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

-(NSImage*) image
{
    [lock lock];
        NSImage* img = [[image retain] autorelease];
    [lock unlock];
    
    return img;
}


// -----------------------------------------------------------------------------
//  dictionaryRepresentation:
//      Return a dictionary corresponding to the sequence of compositing
//      operations that led to this icon. Counterpart to -initWithDictionary.
//  
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

-(NSDictionary*) dictionaryRepresentation
{
    return nil;
}


// -----------------------------------------------------------------------------
//  iconByAddingIcon:toRect:
//      Composite an icon into a particular rect onto this one. This will
//      create a new icon with the composition result.
//
//  REVISIONS:
//      2005-02-09  UK  Changed to return new object instead of changing
//                      current one.
// -----------------------------------------------------------------------------

-(IKIcon*)  iconByAddingIcon: (IKIcon*)src toRect: (NSRect)pos
{
    return [self iconByAddingIcon: src toRect: pos operation: NSCompositeSourceOver fraction: 1.0];
}


// -----------------------------------------------------------------------------
//  iconByAddingIcon:toRect:operation:fraction:
//      Composite an icon into a particular rect onto this one. This will
//      create a new icon with the composition result.
//
//  REVISIONS:
//      2005-02-09  UK  Changed to return new object instead of changing
//                      current one.
// -----------------------------------------------------------------------------

-(IKIcon*)  iconByAddingIcon: (IKIcon*)src toRect: (NSRect)pos
                    operation:(NSCompositingOperation)op fraction:(float)delta
{
    [lock lock];
        NSSize      mySize = [self size];
        
        NSImage*    img = [[[NSImage alloc] initWithSize: mySize] autorelease];
        NSRect      srcBox = { {0,0}, {0,0} };

        [img lockFocus];
            srcBox.size = [src size];
            [image dissolveToPoint: NSZeroPoint fraction: 1.0];
            [[src image] drawInRect: pos fromRect: srcBox operation: op fraction:delta];    // -image already locks and retain/autoreleases the image it returns.
        [img unlockFocus];
    [lock unlock];
    
    if( err == noErr )
        return [[[IKIcon alloc] initWithImage: img] autorelease];
    else
        return nil;
}


// -----------------------------------------------------------------------------
//  badgeRectForPosition:
//      Return the rect in which a particular badge should be composited onto
//      this icon.
//  
//  REVISIONS:
//      2005-02-15  UK  Changed SymLink to Link.
// -----------------------------------------------------------------------------

-(NSRect)       badgeRectForPosition: (IKBadgePosition)pos
{
    NSRect      box = { { 0,0 }, { 0,0 } };
    NSSize      fullSize = [self size];
    
    // If it's a special semantic position, change that into physical:
    if( (pos & IKBadgePositionFlagSemantic) == IKBadgePositionFlagSemantic )
      {
        switch( pos )
          {
            case IKBadgePositionLink:
            case IKBadgePositionStandardLink:
                pos = IKBadgePositionBottomLeft;
                break;

            case IKBadgePositionScript:
            case IKBadgePositionStandardScript:
                pos = IKBadgePositionBottomLeft;
                break;

            case IKBadgePositionLocked:
            case IKBadgePositionStandardLocked:
                pos = IKBadgePositionBottomLeft;
                break;

            case IKBadgePositionReadOnly:
            case IKBadgePositionWriteOnly:
            case IKBadgePositionStandardReadOnly:
            case IKBadgePositionStandardWriteOnly:
                pos = IKBadgePositionBottomRight;
                break;

            case IKBadgePositionDocumentSubIcon:
            case IKBadgePositionStandardDocumentSubIcon:    // There is no standard document sub-icon yet.
                pos = IKBadgePositionCenter;
                break;

            case IKBadgePositionPluginSubIcon:
            case IKBadgePositionStandardPluginSubIcon:      // There is no standard plugin sub-icon yet.
                pos = IKBadgePositionRight;
                break;
          }
      }
    
    if( pos == IKBadgePositionNone )  // No positioning, just slap on top of the other.
        return NSMakeRect( 0, 0, fullSize.width, fullSize.height );
    
    // Now, make the icon quarter size and nudge it to the right position:
    box.size.width = truncf(fullSize.width / 2);
    box.size.height = truncf(fullSize.height / 2);
    
    if( (pos & IKBadgePositionFlagTop) == IKBadgePositionFlagTop )      // Move to top?
        box.origin.y += fullSize.height -box.size.height;
    if( (pos & IKBadgePositionFlagRight) == IKBadgePositionFlagRight )  // Move to right?
        box.origin.x += fullSize.width -box.size.width;
    
    if( pos == IKBadgePositionBottom || pos == IKBadgePositionTop || pos == IKBadgePositionCenter )    // Horizontally centered?
        box.origin.x += truncf((fullSize.width -box.size.width) /2);
    if( pos == IKBadgePositionLeft || pos == IKBadgePositionRight || pos == IKBadgePositionCenter )    // Vertically centered?
        box.origin.y += truncf((fullSize.height -box.size.height) /2);
    
    return box;
}

// -----------------------------------------------------------------------------
//  update:
//      This method is called when the theme's been switched to reload the icon
//      and, when needed, to recomposite it.
//  
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

-(void)         update
{
    [lock lock];
        if( identifier )
          {
            [image autorelease];            // In case image stays the same, we don't want it to be unloaded/reloaded unnecessarily.
            image = [[NSImage imageNamed: identifier] retain];
            
            [[NSNotificationCenter defaultCenter] postNotificationName: IKIconChangedNotification object: self];
          }
    [lock unlock];
}

@end


// -----------------------------------------------------------------------------
//  NSStringFromIconIdentifier:
//      Return an NSString for saving to disk that corresponds to the specified
//      icon identifier. Counterpart to IKIconIdentifierFromString().
//  
//  REVISIONS:
//      2005-02-15  UK  Expanded documentation.
// -----------------------------------------------------------------------------

NSString*
NSStringFromIconIdentifier( IKIconIdentifier ident )
{
    return (NSString*)ident;
}


// -----------------------------------------------------------------------------
//  IKIconIdentifierFromString:
//      Return an IKIconIdentifier for passing to IconKit that corresponds to
//      the specified string. Counterpart to NSStringFromIconIdentifier().
//  
//  REVISIONS:
//      2005-02-15  UK  Created.
// -----------------------------------------------------------------------------

IKIconIdentifier
IKIconIdentifierFromString( NSString* str )
{
    return (IKIconIdentifier)str;
}
