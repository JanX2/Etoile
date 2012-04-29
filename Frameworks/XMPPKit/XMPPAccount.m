//
//  XMPPAccount.m
//  Jabber
//
//  Created by David Chisnall on 21/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#ifndef GNUSTEP
#include <Security/Security.h>
#endif

#import <AddressBook/AddressBook.h>
#import "XMPPAccount.h"
#import "XMPPRoster.h"
#import "JID.h"

//NOTE: These could probably be done more neatly with KVC
void setDefault(NSString * dictionary, id key, id value)
{
        NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:dictionary]];
        if(dict == nil)
        {
                dict = [NSMutableDictionary dictionary];
        }
        [dict setValue:value forKey:key];
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:dictionary];
}

id getDefault(NSString * dictionary, id key)
{
        NSDictionary * dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:dictionary];
        return [dict valueForKey:key];
        
}
@implementation XMPPAccount
+ (void) setDefaultJID:(JID*) aJID
{
        [self setDefaultJID:aJID withServer:[aJID domain]];
}
+ (void) setDefaultJID:(JID*) aJID withServer:(NSString*) aServer
{
        ABPerson * me =  [[ABAddressBook sharedAddressBook] me];
        if(me == nil)
        {
                me = [[ABPerson alloc] init];
                [[ABAddressBook sharedAddressBook] addRecord:me];                
                [[ABAddressBook sharedAddressBook] setMe:me];
        }
        ABMutableMultiValue * jids = [[me valueForProperty:kABJabberInstantProperty] mutableCopy];
        if(jids == nil)
        {
                jids = [[ABMutableMultiValue alloc] init];
        }
        NSString * defaultID = [jids primaryIdentifier];
        if(defaultID == nil)
        {
                //TODO: This could arguably be more sensible.
                defaultID = @"home";
        }
        [jids addValue:[aJID jidString] withLabel:defaultID];
        [me setValue:jids forProperty:kABJabberInstantProperty];
        [[ABAddressBook sharedAddressBook] save];
        setDefault(@"Servers", [aJID jidString], aServer);
}

- (id) initWithName:(NSString*)aName withJid:(JID*)aJid withPassword:(NSString*)aPassword
{
        self = [super init];
        if(self == nil)
        {
                return nil;
        }
        
        name = aName;
        roster = (XMPPRoster*)[[XMPPRoster alloc] initWithAccount:self];
        connection = (XMPPConnection*)[[XMPPConnection alloc] initWithAccount:self];
        [connection setPresenceDisplay:[roster delegate]];

        //Get user's Jabber ID from Address Book
        
        myJID = aJid;
        if(aPassword != nil)
        {
                NSString * server = getDefault(@"Servers", [myJID jidString]);
                [connection connectToJabberServer:server
                                          withJID:myJID
                                         password:aPassword];
                return self;
        }
        else
        {
                [[NSException exceptionWithName:XMPPNOPASSWORDEXCEPTION
                                                                 reason:@"Unable to find password for connection"
                                                               userInfo:[NSDictionary dictionaryWithObject:myJID
                                                                                                    forKey:@"JID"]] raise];
        }
        // Never reached; just used to eliminate a warning
        // from the compiler that doesn't know about exceptions
        return nil; 
}

- (void) reconnect
{
        [connection reconnectToJabberServer];
}

- (XMPPRoster*) roster
{
        return roster;
}

- (XMPPConnection*) connection
{
        return connection;
}

- (JID*) jid
{
        return myJID;
}
- (NSString*) name
{
        return name;
}
@end
