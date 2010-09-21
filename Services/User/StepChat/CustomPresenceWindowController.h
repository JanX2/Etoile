//
//  CustomPresenceWindowController.h
//  Jabber
//
//  Created by David Chisnall on 10/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface CustomPresenceWindowController : NSWindowController {
	IBOutlet NSComboBox * name;
	IBOutlet NSComboBox * presence;
	IBOutlet NSTextView * message;
	NSArray * presences;
}
- (IBAction) okay:(id) sender;
- (IBAction) cancel:(id) sender;
@end
