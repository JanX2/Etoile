/*
 *  IKIcon.h
 *  
 *
 *  Created by Uli Kusterer on 31.12.04.
 *  Copyright 2004 M. Uli Kusterer. All rights reserved.
 *
 */

#ifndef ICONKIT_IKICON_H
#define ICONKIT_IKICON_H 1

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#include <AppKit/AppKit.h>
#include "IKIconIdentifier.h"
#include "IKIconPositions.h"


// -----------------------------------------------------------------------------
//  Constants:
// -----------------------------------------------------------------------------

// Notifications:
extern NSString*            IKIconChangedNotification;  // Sent with the IKIcon as the object whenever update is called.


// -----------------------------------------------------------------------------
//  Classes:
// -----------------------------------------------------------------------------

@interface IKIcon : NSObject
{
    NSImage*            image;      // The actual icon image to display.
    IKIconIdentifier    identifier; // If this is a standard icon, this is its identifier so we can re-load it on theme changes.
    NSRecursiveLock*    lock;       // Thread lock to make sure IKIcons can be used from several threads.
}

// Convenience methods for alloc/init/autorelease:
+(id)       iconForFile: (NSString*)path;
+(id)       iconForURL: (NSURL*)path;
+(id)       iconWithIdentifier: (IKIconIdentifier)identifier;
+(id)       iconWithExtension: (NSString*)suffix mimeType: (NSString*)mime
                attributes: (NSDictionary*)dict; /* any param may be NIL */
+(id)       iconWithSize: (NSSize)size;
+(id)       iconWithImage: (NSImage*)image;

// Constructors:
-(id)       initForFile: (NSString*)path;
-(id)       initForURL: (NSURL*)path;
-(id)       initWithIdentifier: (IKIconIdentifier)identifier;
-(id)       initWithExtension: (NSString*)suffix mimeType: (NSString*)mime
                attributes: (NSDictionary*)dict; /* any param may be NIL */
-(id)       initWithSize: (NSSize)size;
-(id)       initWithImage: (NSImage*)image;     // sets baseImage.
-(id)       initWithDictionary: (NSDictionary*)plist;

-(NSSize)   size;
-(NSImage*) image;

-(NSDictionary*) dictionaryRepresentation;   // For passing to initWithDictionary:.

// Compositing:
-(IKIcon*)      iconByAddingIcon: (IKIcon*)src toRect: (NSRect)pos;
-(IKIcon*)      iconByAddingIcon: (IKIcon*)src toRect: (NSRect)pos
                    operation:(NSCompositingOperation)op fraction:(float)delta;

-(NSRect)       badgeRectForPosition: (IKBadgePosition)pos;

// For theme-switching:
-(void)         update;             // Reloads the icon, possibly from the new theme.

@end


// -----------------------------------------------------------------------------
//  Prototypes:
// -----------------------------------------------------------------------------

NSString*
NSStringFromIconIdentifier( IKIconIdentifier ident );

IKIconIdentifier
IKIconIdentifierFromString( NSString* str );

#endif /*ICONKIT_IKICON_H*/