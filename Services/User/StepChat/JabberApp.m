//
//  JabberApp.m
//  Jabber
//
//  Created by David Chisnall on Mon Apr 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "JabberApp.h"
#import "PasswordWindowController.h"
#import "JabberApp.h"

NSString * passwordForJID(JID * aJID)
{
#ifdef GNUSTEP
        return [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"XMPPPasswords"] objectForKey:[aJID jidString]];
#else
        UInt32 passwordLength;
        char * passwordData;

        //Get the password from the keychain
        OSStatus status = SecKeychainFindInternetPassword(NULL, 
                                                                        [[aJID domain] length],
                                                                        [[aJID domain] UTF8String],
                                                                        0,
                                                                        NULL,
                                                                        [[aJID node] length],
                                                                        [[aJID node] UTF8String],
                                                                        0,
                                                                        NULL,
                                                                        5222,
                                                                        kSecProtocolTypeTelnet, //This is wrong, but there seems to be no correct answer.
                                                                        kSecAuthenticationTypeDefault,
                                                                        &passwordLength,
                                                                        (void**)&passwordData,
                                                                        NULL);
        if(status == noErr)
        {
                NSString * password = [NSString stringWithCString:strdup(passwordData)
                                                              length:passwordLength];
                SecKeychainItemFreeContent(NULL,passwordData);
                return password;
        }
        return nil;
#endif
}


@implementation JabberApp

- (void) test:(id)timer
{
        NSLog(@"Idle timer fired");
}
- (NSTextView*) xmlLogBox
{
        return xmlLogBox;
}
- (void) getPassword:aJid
{
        PasswordWindowController * passwordWindow = [[PasswordWindowController alloc] initWithWindowNibName:@"PasswordBox" forJID:aJid];
        if([NSApp runModalForWindow:[passwordWindow window]] == 0)
        {
                //User entered a password.
        }
        else
        {
                //Do something sensible here.
        }
}

- (void) getAccountInfo
{
        accountWindow = [[AccountWindowController alloc] initWithWindowNibName:@"AccountBox"];
        if([NSApp runModalForWindow:[accountWindow window]] == 0)
        {
                //User entered an account.
        }
        else
        {
                //Do something sensible here.
        }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
        //TODO: Make this a user defaults thing.
#ifdef NDEBUG
        [[debugMenu menu] removeItem:debugMenu];
#endif
        SCAccountInfoManager *manager = [[SCAccountInfoManager alloc] init];
        while (nil == account)
        {
               /*ABMultiValue * jids = [[[ABAddressBook sharedAddressBook] me] valueForProperty:kABJabberInstantProperty];*/               
             NSString * jidString = nil;
             jidString = [manager readJIDFromFileAtPath:[manager filePath]];   
                 /*if ([jids count] > 0) 
                {
                        jidString = [jids valueAtIndex:0];
                }*/

             while (nil == jidString || [jidString isEqualToString:@"N"])
              {
                [self getAccountInfo];
                jidString = [manager readJIDFromFileAtPath:[manager filePath]];
                       /* jids = [[[ABAddressBook sharedAddressBook] me] valueForProperty:kABJabberInstantProperty];
                        if ([jids count] >0)
                        {
                                jidString = [jids valueAtIndex:0];
                        }*/

              }

                JID *tmpJid = [JID jidWithString:jidString];
                NSString *password = passwordForJID(tmpJid);

                while (nil == password)
                {
                        [self getPassword: tmpJid];
                        password = passwordForJID(tmpJid);
                }
                account = [[XMPPAccount alloc] initWithName:@"Default" 
                                                    withJid:tmpJid 
                                               withPassword:password];
        }
        rosterWindow = [[RosterController alloc] initWithNibName:@"RosterWindow"
                                                      forAccount:account
                                                      withRoster:[account roster]];
        [[account roster] setDelegate:rosterWindow];
        [[account connection] setPresenceDisplay:rosterWindow];
        [rosterWindow showWindow:self];
}

- (id) init
{
        return [super init];
}

- (void) reconnect
{
        account = [[XMPPAccount alloc] init];
}

- (void) redrawRosters
{
        [rosterWindow update:nil];
}

- (void) setPresence:(unsigned char)_presence withMessage:(NSString*)_message
{
        if(_presence == PRESENCE_OFFLINE)
        {
                [[account connection] disconnect];
                [[account roster] offline];
                [rosterWindow update:nil];
        }
        else
        {
                if(_message == nil)
                {
                        _message = [rosterWindow currentStatusMessage];
                }
                if ([[account connection] isConnected])
                {
                        [[account connection] setStatus:_presence withMessage:_message];
                }
                else
                {
                        [[account roster] setInitialStatus:_presence withMessage:_message];
                        if (![[account connection] isConnected])
                        {        
                                [account reconnect];
                        }
                }
        }
}

//Should not be called any longer...
- (void) connectionFailed:(XMPPAccount*)_account
{
        NSLog(@"Account: %@",_account);
        PasswordWindowController * passwordWindow = [[PasswordWindowController alloc] initWithWindowNibName:@"PasswordBox" forJID:[_account jid]];
        if([NSApp runModalForWindow:[passwordWindow window]] == 0)
        {
                [_account release];
                account = [[XMPPAccount alloc] init];
        }
        else
        {
                [_account release];
        }
}

- (IBAction) showRosterWindow:(id)_sender
{
        [rosterWindow showWindow:_sender];
}

- (void) setCustomPresence:(id) sender
{
        [customPresenceWindow showWindow:sender];
}

- (XMPPAccount*) account
{
        return account;
}

- (void) dealloc
{
        [account release];
        [super dealloc];
}
@end
