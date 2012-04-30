//
//  PreferenceWindowController.h
//  Jabber
//
//  Created by David Chisnall on 19/10/2004.
//  Copyright 2004 David Chisnall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PreferenceWindowController : NSWindowController {
	__unsafe_unretained IBOutlet NSColorWell * chatColour;
	__unsafe_unretained IBOutlet NSColorWell * onlineColour;
	__unsafe_unretained IBOutlet NSColorWell * awayColour;
	__unsafe_unretained IBOutlet NSColorWell * xaColour;
	__unsafe_unretained IBOutlet NSColorWell * dndColour;
	__unsafe_unretained IBOutlet NSColorWell * offlineColour;
	__unsafe_unretained IBOutlet NSColorWell * unknownColour;
	__unsafe_unretained IBOutlet NSComboBox * onlineSoundBox;
	__unsafe_unretained IBOutlet NSComboBox * offlineSoundBox;
	__unsafe_unretained IBOutlet NSComboBox * messageSoundBox;
}
- (IBAction) selectOnlineSound:(id)_sender;
- (IBAction) selectOfflineSound:(id)_sender;
- (IBAction) selectMessageSound:(id)_sender;
- (IBAction) playOnlineSound:(id)_sender;
- (IBAction) playOfflineSound:(id)_sender;
- (IBAction) playMessageSound:(id)_sender;
@end
