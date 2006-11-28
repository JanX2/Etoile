/*
	IKIcon.h

	IKIcon is IconKit main class to represent icons.

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

#import <AppKit/AppKit.h>
#import <IconKit/IKIconIdentifier.h>
#import <IconKit/IKIconPositions.h>

// Notifications:
extern NSString *IKIconChangedNotification;  // Sent with the IKIcon as the object whenever update is called.

@interface IKIcon : NSObject
{
    NSImage *			_image;      // The actual icon image to display.
    IKIconIdentifier	_identifier; // If this is a standard icon, this is its identifier so we can re-load it on theme changes.
    NSRecursiveLock *	_lock;       // Thread lock to make sure IKIcons can be used from several threads.
}

// Convenience methods for alloc/init/autorelease:
+ (id) iconForFile: (NSString *)path;
+ (id) iconForURL: (NSURL *)path;
+ (id) iconWithIdentifier: (IKIconIdentifier)identifier;
+ (id) iconWithExtension: (NSString *)suffix mimeType: (NSString*)mime
	attributes: (NSDictionary *)dict; /* any param may be NIL */
+ (id) iconWithSize: (NSSize)size;
+ (id) iconWithImage: (NSImage *)image;

// Constructors:
- (id) initForFile: (NSString *)path;
- (id) initForURL: (NSURL *)path;
- (id) initWithIdentifier: (IKIconIdentifier)identifier;
- (id) initWithExtension: (NSString *)suffix mimeType: (NSString *)mime
	attributes: (NSDictionary *)dict; /* any param may be NIL */
- (id) initWithSize: (NSSize)size;
- (id) initWithImage: (NSImage *)image; // sets baseImage.
- (id) initWithDictionary: (NSDictionary *)plist;

- (NSSize) size;
- (NSImage *) image;

- (NSDictionary *) dictionaryRepresentation; // For passing to initWithDictionary:.

// Compositing:
- (IKIcon *) iconByAddingIcon: (IKIcon *)src toRect: (NSRect)pos;
- (IKIcon *) iconByAddingIcon: (IKIcon *)src toRect: (NSRect)pos
	operation: (NSCompositingOperation)op fraction: (float)delta;

- (NSRect) badgeRectForPosition: (IKBadgePosition)pos;

// For theme-switching:
- (void) update; // Reloads the icon, possibly from the new theme.

@end

/*
 * Prototypes
 */

NSString *
NSStringFromIconIdentifier(IKIconIdentifier ident);

IKIconIdentifier
IKIconIdentifierFromString(NSString *str);
