//
//  AccountWindowController.m
//  Jabber
//
//  Created by David Chisnall on 22/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AccountWindowController.h"
#import <XMPPKit/XMPPAccount.h>

@implementation AccountWindowController

- (IBAction) yes:(id)sender
{
        JID *myJID = [JID jidWithString:[jidBox stringValue]];
        NSString * myServer = [serverBox stringValue];
        if(myServer != nil && ![myServer isEqualToString:@""])
        {
                [XMPPAccount setDefaultJID:myJID withServer:myServer];
                SCAccountInfoManager *manager = [[SCAccountInfoManager alloc] init];
                [manager writeJIDToFile:myJID atPath:[manager filePath]];
        }
        else
        {
                [XMPPAccount setDefaultJID:myJID];
                SCAccountInfoManager *manager = [[SCAccountInfoManager alloc] init];
                [manager writeJIDToFile:myJID atPath:[manager filePath]];
        }
        [[self window] close];
        [NSApp stopModalWithCode:0];
}
- (IBAction) no:(id)sender
{
        [[self window] close];
        [NSApp stopModalWithCode:-1];
        [NSApp terminate:self];  //Slex
}
@end
