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
	IBOutlet NSColorWell * chatColour;
	IBOutlet NSColorWell * onlineColour;
	IBOutlet NSColorWell * awayColour;
	IBOutlet NSColorWell * xaColour;
	IBOutlet NSColorWell * dndColour;
	IBOutlet NSColorWell * offlineColour;
	IBOutlet NSColorWell * unknownColour;
	IBOutlet NSComboBox * onlineSoundBox;
	IBOutlet NSComboBox * offlineSoundBox;
	IBOutlet NSComboBox * messageSoundBox;
}
- (IBAction) selectOnlineSound:(id)_sender;
- (IBAction) selectOfflineSound:(id)_sender;
- (IBAction) selectMessageSound:(id)_sender;
- (IBAction) playOnlineSound:(id)_sender;
- (IBAction) playOfflineSound:(id)_sender;
- (IBAction) playMessageSound:(id)_sender;
@end
