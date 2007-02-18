//
//  GlobalPreferences.h
//  Jabber
//
//  Created by David Chisnall on 09/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface GlobalPreferences : NSObject {
	NSMutableDictionary * data;
	NSString * fileName;
}
+ (id) sharedPreferenceObject;
- (void) hidePresences:(unsigned char)_presence;
- (unsigned char) hiddenPresences;
- (BOOL) isExpanded:(NSString*)_groupName;
- (void) setExpanded:(NSString*)_groupName to:(BOOL)_value;
- (NSColor*) colourForPresence:(unsigned char)_presence;
- (void) setColour:(NSColor*)_colour forPresence:(unsigned char)_presence;
- (NSString*) customMessageNamed:(NSString*)_name;
- (unsigned char) customPresenceNamed:(NSString*)_name;
- (void) setCustomPresence:(unsigned char)_presence withMessage:(NSString*)_message named:(NSString*)name;
- (NSArray*) customPresences;
- (NSSound*) sound:(NSString*)_name;
- (NSSound*) onlineSound;
- (NSSound*) offlineSound;
- (NSSound*) messageSound;
- (NSString*) onlineSoundName;
- (NSString*) offlineSoundName;
- (NSString*) messageSoundName;
- (void) setOnlineSound:(NSString*)_path;
- (void) setOfflineSound:(NSString*)_path;
- (void) setMessageSound:(NSString*)_path;

@end

