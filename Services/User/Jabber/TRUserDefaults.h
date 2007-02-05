//
//  NSUserDefaultsWithColour.h
//  Jabber
//
//  Created by David Chisnall on 02/11/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface NSUserDefaults(TRJabberAdditions)
 //Sound should be set to a filename or a named system sound using setString: forKey:
- (NSSound*) soundForKey:(NSString*)_key;

- (unsigned char) presenceForKey:(NSString*)_key;
- (void) setPresence:(unsigned char)_presence forKey:(NSString *)_key;

- (void) setColour:(NSColor *)_color forKey:(NSString *)_key;
- (NSColor*) colourForKey:(NSString *)_key;

- (void) setColour:(NSColor *)_colour forPresence:(unsigned char)_presence;
- (NSColor*) colourForPresence:(unsigned char)_presence;

- (void) setExpanded:(NSString*)_group to:(BOOL)_expanded;
- (BOOL) expandedGroup:(NSString*)_group;

- (NSString*) customMessageNamed:(NSString*)_name;
- (unsigned char) customPresenceNamed:(NSString*)_name;
- (void) setCustomPresence:(unsigned char)_presence withMessage:(NSString*)_message named:(NSString*)_name;

//- (NSRect) locationOfWindowNamed:(NSString*)_name;

@end

