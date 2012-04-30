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
	__unsafe_unretained IBOutlet NSTextField * jid;
	__unsafe_unretained IBOutlet NSTextField * name;
	__unsafe_unretained IBOutlet NSTextField * group;
}
- (IBAction) addPerson:(id)_sender;
- (IBAction) cancel:(id)_sender;
- (IBAction) showWindow:(id)_sender;
@end
