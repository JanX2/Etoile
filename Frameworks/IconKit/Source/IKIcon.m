/** <title>IKIcon</title>

	IKIcon.m

	<abstract>IKIcon is IconKit main class to represent icons.</abstract>

	Copyright (C) 2004 Uli Kusterer <contact@zathras.de>
	                   Quentin Mathe <qmathe@club-internet.fr>

	Author:   Uli Kusterer <contact@zathras.de>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2004

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import "IKIcon.h"
#import "IKIconTheme.h"

/* For truncf on Linux and other platforms probably...
   #import <math.h> doesn't work on many Linux systems since truncf is often 
   not part of this header currently. That's why we rely on GCC equivalent builtin 
   function. */
#define truncf(x)  __builtin_truncf(x)

/* The values of the following should probably be the file names of the icon 
   files... However, the names I've chosen so far are the ones that
   NSStringFromIconIdentifier() should return for each icon, so if you change
   one of these, make sure you change that function to still return this string
   for that icon identifier so apps that save icon identifiers to disk using
   NSStringFromIconIdentifier() create the same files on OS X and GNUstep. */

IKIconIdentifier    IKIconGenericDocument =     @"GenericFolder";
IKIconIdentifier    IKIconGenericApplication =  @"GenericApplication";
IKIconIdentifier    IKIconGenericPlugIn =       @"GenericPlugIn";
IKIconIdentifier    IKIconGenericFolder =       @"GenericFolder";
IKIconIdentifier    IKIconPrivateFolder =       @"PrivateFolder";
IKIconIdentifier    IKIconWriteOnlyFolder =     @"WriteOnlyFolder";
IKIconIdentifier    IKIconRecyclerFolder =      @"RecyclerFolder";
IKIconIdentifier    IKIconRecyclerFolderFull =  @"RecyclerFolderFull";
// ...
IKIconIdentifier    IKIconLinkBadge =       @"LinkBadge";
IKIconIdentifier    IKIconLockedBadge =     @"LockedBadge";
IKIconIdentifier    IKIconScriptBadge =     @"ScriptBadge";
IKIconIdentifier    IKIconReadOnlyBadge =   @"ReadOnlyBadge";
IKIconIdentifier    IKIconWriteOnlyBadge =  @"WriteOnlyBadge";

/* System icons (not for files) */
IKIconIdentifier    IKIconAlertNote =       @"AlertNote";
IKIconIdentifier    IKIconAlertWarning =    @"AlertWarning";
IKIconIdentifier    IKIconAlertFailure =    @"AlertFailure";

/* Notifications */
/** Sent with the IKIcon as the object whenever -update is called. */
NSString *IKIconChangedNotification = @"IKIconChangedNotification";


@implementation IKIcon

/*
 *  Factory methods
 */

+ (id) iconForFile: (NSString *)fpath
{
  return [[(IKIcon *)[self alloc] initForFile: fpath] autorelease];
}


+ (id) iconForURL: (NSURL *)fpath
{
  return [[(IKIcon *)[self alloc] initForURL: fpath] autorelease];
}


+ (id) iconWithIdentifier: (IKIconIdentifier)ident
{
  return [[(IKIcon *)[self alloc] initWithIdentifier: ident] autorelease];
}


+ (id) iconWithExtension: (NSString *)suffix mimeType: (NSString *)mime
              attributes: (NSDictionary *)dict
{
  return [[[self alloc] initWithExtension: suffix 
                                 mimeType: mime 
                               attributes: dict] autorelease];
}


+ (id) iconWithSize: (NSSize)size
{
  return [[[self alloc] initWithSize: size] autorelease];
}

+ (id) iconWithImage: (NSImage *)image
{
  return [[[self alloc] initWithImage: image] autorelease];
}

/*
 * Constructors
 */

//      TODO: We could probably write a variant of this that takes a
//      fileAttributes dictionary. That would be faster
//      in cases where we're querying the attributes anyway.
// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-13  UK  Ripped out IconServices stuff to make this port to
//                      GNUstep.
//      2005-02-09  UK  Renamed to initForFile: to make clear it gets the icon
//                      *for* the file, not *from* it.
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

/** Return an icon for a particular file. This may give you a cached object 
    instead of the one you alloced originally. */
- (id) initForFile: (NSString *)fpath
{
  self = [super init];
  if (self == nil)
    return nil;

  // FIX ME: Causes endless recursion with NSWorkspace overrides. Change this 
  // to use Quentin's code so we can activate NSWorkspaceAdditions.
  _image = [[[NSWorkspace sharedWorkspace] iconForFile: fpath] retain];
  _lock = [[NSRecursiveLock alloc] init];

  return self;
}


// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Created.
// -----------------------------------------------------------------------------

/** Same as initForFile:, but takes an NSURL instead of an NSString path. */
- (id) initForURL: (NSURL *)fpath
{
  if ([fpath isFileURL])
    {
      return [self initForFile: [fpath path]];
    }
  else
    {
      // FIX ME: Should try to use extension and maybe find out whether it's a
      // directory
      return [self initWithIdentifier: IKIconGenericDocument]; 
    }
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

/** Return one of the standard system icons. This can also be used for standard 
    alert icons or whatever else you want. */
- (id) initWithIdentifier: (IKIconIdentifier)ident
{
  NSString *iconPath = nil;

  self = [super init];
  if(self == nil)
    return nil;

  iconPath = [[IKIconTheme theme] iconPathForIdentifier: ident];
  if (iconPath != nil)
    {
      _image = [[NSImage alloc] initWithContentsOfFile: iconPath];
    }
  else
    {
      _image = [[NSImage imageNamed: ident] retain];
    }
  _identifier = [ident retain];
  _lock = [[NSRecursiveLock alloc] init];

  return self;
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

/** Return an icon for a file with the specified characteristics. Any of the 
    parameters may be NIL, which will assume sensible defaults or try to perform 
    the lookup without taking into account the additional info. */
- (id) initWithExtension: (NSString *)suffix mimeType: (NSString *)mime
  attributes: (NSDictionary *)dict
{
  self = [super init];
  if (self == nil)
    return nil;

   // FIX ME: Causes endless recursion with NSWorkspace overrides. Change this 
   // to use Quentin's code so we can activate NSWorkspaceAdditions.
  _image = [[[NSWorkspace sharedWorkspace] iconForFileType: suffix] retain];
  _lock = [[NSRecursiveLock alloc] init];

  return self;
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

/** Create a new, empty icon with the specified size. */
- (id) initWithSize: (NSSize)size
{
  return [self initWithImage: [[[NSImage alloc] initWithSize: size] autorelease]];
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

/** Create a new icon with the specified image. */
- (id) initWithImage: (NSImage *)img
{
  self = [super init];
  if (self == nil )
    return nil;

  _image = [img retain];
  _lock = [[NSRecursiveLock alloc] init];

  return self;
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

/** Return the final icon from the compositing sequence specified in this
    property list. This is the counterpart to -dictionaryRepresentation. */
- (id) initWithDictionary: (NSDictionary *)plist
{
  return nil;
}


// -----------------------------------------------------------------------------
//  REVISIONS:
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

- (void) dealloc
{
   [_lock lock];

   [_image release];
   _image = nil;
   [_identifier release];
   _identifier = nil;
   [_lock release];
   _lock = nil;

   [super dealloc];
}

/** Return the size of this icon. */
- (NSSize) size
{
  [_lock lock];
  NSSize sz = [_image size];
  [_lock unlock];

  return sz;
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-11  UK  Changed to use IKIconRefImageRep instead of manually
//                      assembling an NSImage with several reps.
//      2004-12-22  UK  Documented.
// -----------------------------------------------------------------------------

/** <p>Returns an NSImage of our icon ref. This NSImage contains an
    IKIconRefImageRep, which calls drawRect: on this icon ref to take care of
    nicely scaling the icon as needed.</p>
    <p>We don't retain this NSImage because it would cause a circle where the
    ImageRep retains us, and we retain it. And anyway, an iconRef image rep is
    lightweight.</p> */
- (NSImage *) image
{
  [_lock lock];
  NSImage* img = [[_image retain] autorelease];
  [_lock unlock];

  return img;
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

/** Return a dictionary corresponding to the sequence of compositing
    operations that led to this icon. Counterpart to -initWithDictionary. */
- (NSDictionary *) dictionaryRepresentation
{
    return nil;
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-09  UK  Changed to return new object instead of changing
//                      current one.
// -----------------------------------------------------------------------------

/** Composite an icon into a particular rect onto this one. This will
    create a new icon with the composition result. */
- (IKIcon *) iconByAddingIcon: (IKIcon *)src toRect: (NSRect)pos
{
  return [self iconByAddingIcon: src 
                         toRect: pos 
                      operation: NSCompositeSourceOver 
                       fraction: 1.0];
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-09  UK  Changed to return new object instead of changing
//                      current one.
// -----------------------------------------------------------------------------

/** Composite an icon into a particular rect onto this one. This will
    create a new icon with the composition result. */
- (IKIcon *) iconByAddingIcon: (IKIcon *)src toRect: (NSRect)pos
                    operation:(NSCompositingOperation)op fraction: (float)delta
{
  [_lock lock];

  NSSize      mySize = [self size];
  NSImage*    img = [[[NSImage alloc] initWithSize: mySize] autorelease];
  NSRect      srcBox = { {0,0}, {0,0} };

  [img lockFocus];

  srcBox.size = [src size];
  [_image dissolveToPoint: NSZeroPoint fraction: 1.0];
  // NOTE: -image already locks and retain/autoreleases the image it returns.
  [[src image] drawInRect: pos fromRect: srcBox operation: op fraction:delta];

  [img unlockFocus];

  [_lock unlock];

  //if( err == noErr )
      return [[[IKIcon alloc] initWithImage: img] autorelease];
  //else
  //    return nil;
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Changed SymLink to Link.
// -----------------------------------------------------------------------------

/** Return the rect in which a particular badge should be composited onto
    this icon. */
- (NSRect) badgeRectForPosition: (IKBadgePosition)pos
{
  NSRect box = { { 0,0 }, { 0,0 } };
  NSSize fullSize = [self size];
  
  /* If it's a special semantic position, change that into physical */
  if ((pos & IKBadgePositionFlagSemantic) == IKBadgePositionFlagSemantic)
    {
      switch (pos)
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
          case IKBadgePositionStandardDocumentSubIcon:
            // NOTE: There is no standard document sub-icon yet.
            pos = IKBadgePositionCenter;
            break;

          case IKBadgePositionPluginSubIcon:
          case IKBadgePositionStandardPluginSubIcon:
            // NOTE: There is no standard plugin sub-icon yet.
            pos = IKBadgePositionRight;
            break;

          // NOTE: this avoids compiler warning about non handled enumeration values
          default:
            break;
        }
    }

  /* No positioning, just slap on top of the other. */
  if (pos == IKBadgePositionNone)
    return NSMakeRect(0, 0, fullSize.width, fullSize.height);

  /* Now, make the icon quarter size and nudge it to the right position */
  box.size.width = truncf(fullSize.width / 2);
  box.size.height = truncf(fullSize.height / 2);

  /* Move to top? */
  if ((pos & IKBadgePositionFlagTop) == IKBadgePositionFlagTop)
      box.origin.y += fullSize.height -box.size.height;
  if ((pos & IKBadgePositionFlagRight) == IKBadgePositionFlagRight)  // Move to right?
      box.origin.x += fullSize.width -box.size.width;

  /* Horizontally centered? */
  if (pos == IKBadgePositionBottom 
    || pos == IKBadgePositionTop 
    || pos == IKBadgePositionCenter) 
      box.origin.x += truncf((fullSize.width -box.size.width) /2);

  /* Vertically centered? */
  if (pos == IKBadgePositionLeft 
   || pos == IKBadgePositionRight 
   || pos == IKBadgePositionCenter)
     box.origin.y += truncf((fullSize.height -box.size.height) /2);

  return box;
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Documented.
// -----------------------------------------------------------------------------

/** This method is called when the theme's been switched to reload the icon
    and, when needed, to recomposite it. */
- (void) update
{
  [_lock lock];

    if (_identifier)
      {
        NSString *iconPath = [[IKIconTheme theme] 
          iconPathForIdentifier: _identifier];

        /* In case image stays the same, we don't want it to be 
           unloaded/reloaded unnecessarily. */
        [_image autorelease];
        if (iconPath != nil)
          {
            _image = [[NSImage alloc] initWithContentsOfFile: iconPath];
          }
        else
          {
            _image = [[NSImage imageNamed: _identifier] retain];
          }

        [[NSNotificationCenter defaultCenter] 
          postNotificationName: IKIconChangedNotification object: self];
      }

  [_lock unlock];
}

@end

/*
 * Functions
 */

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Expanded documentation.
// -----------------------------------------------------------------------------

/** Return an NSString for saving to disk that corresponds to the specified
    icon identifier. Counterpart to IKIconIdentifierFromString(). */
NSString *NSStringFromIconIdentifier(IKIconIdentifier ident)
{
  return (NSString *)ident;
}

// -----------------------------------------------------------------------------
//  REVISIONS:
//      2005-02-15  UK  Created.
// -----------------------------------------------------------------------------

/** Return an IKIconIdentifier for passing to IconKit that corresponds to the
    specified string. Counterpart to NSStringFromIconIdentifier(). */
IKIconIdentifier IKIconIdentifierFromString(NSString *str)
{
  return (IKIconIdentifier)str;
}
