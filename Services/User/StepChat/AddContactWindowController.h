//
//  AddContactWindowController.h
//  Jabber
//
//  Created by David Chisnall on 07/12/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface AddContactWindowController : NSWindowController {
	IBOutlet NSTextField * jid;
	IBOutlet NSTextField * name;
	IBOutlet NSTextField * group;
}
- (IBAction) addPerson:(id)_sender;
- (IBAction) cancel:(id)_sender;
- (IBAction) showWindow:(id)_sender;
@end
