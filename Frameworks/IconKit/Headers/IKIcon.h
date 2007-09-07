/*
	IKIcon.h

	IKIcon is IconKit main class to represent icons.

	Copyright (C) 2004 Uli Kusterer <contact@zathras.de>
	                   Quentin Mathe <qmathe@club-internet.fr>

	Author:   Uli Kusterer <contact@zathras.de>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2004

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <IconKit/IKIconIdentifier.h>
#import <IconKit/IKIconPositions.h>

/* Notifications */
/** Sent with the IKIcon as the object whenever -update is called. */
extern NSString *IKIconChangedNotification;


@interface IKIcon : NSObject
{
  NSImage *_image; /* The actual icon image to display. */
  /* If this is a standard icon, this is its identifier so we can reload it on
     theme changes. */
  IKIconIdentifier _identifier; 
  /* Thread lock to make sure IKIcons can be used from several threads. */
  NSRecursiveLock *_lock; 
}

/* Convenience methods for alloc/init/autorelease */
+ (id) iconForFile: (NSString *)path;
+ (id) iconForURL: (NSURL *)path;
+ (id) iconWithIdentifier: (IKIconIdentifier)identifier;
+ (id) iconWithExtension: (NSString *)suffix mimeType: (NSString *)mime
  attributes: (NSDictionary *)dict; /* any param may be NIL */
+ (id) iconWithSize: (NSSize)size;
+ (id) iconWithImage: (NSImage *)image;

/* Constructors */
- (id) initForFile: (NSString *)path;
- (id) initForURL: (NSURL *)path;
- (id) initWithIdentifier: (IKIconIdentifier)identifier;
- (id) initWithExtension: (NSString *)suffix mimeType: (NSString *)mime
  attributes: (NSDictionary *)dict; /* any param may be NIL */
- (id) initWithSize: (NSSize)size;
- (id) initWithImage: (NSImage *)image; /* sets baseImage */
- (id) initWithDictionary: (NSDictionary *)plist;

/* Accessors */
- (NSSize) size;
- (NSImage *) image;
/* For passing to initWithDictionary: */
- (NSDictionary *) dictionaryRepresentation;

/* Compositing */
- (IKIcon *) iconByAddingIcon: (IKIcon *)src toRect: (NSRect)pos;
- (IKIcon *) iconByAddingIcon: (IKIcon *)src toRect: (NSRect)pos
  operation: (NSCompositingOperation)op fraction: (float)delta;
- (NSRect) badgeRectForPosition: (IKBadgePosition)pos;

/* Theme-switching */
- (void) update; /* Reloads the icon, possibly from the new theme. */

@end

/* Prototypes */
NSString * NSStringFromIconIdentifier(IKIconIdentifier ident);
IKIconIdentifier IKIconIdentifierFromString(NSString *str);
