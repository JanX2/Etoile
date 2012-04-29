//
//  XMPPQueryRosterHandler.m
//  Jabber
//
//  Created by David Chisnall on 12/11/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "XMPPQueryRosterHandler.h"
#import "XMPPIdentity.h"
#import <EtoileFoundation/EtoileFoundation.h>

@implementation XMPPQueryRosterHandler
- (id) initWithXMLParser: (ETXMLParser*)aParser
                     key: (id) aKey
{
        self = [super initWithXMLParser: aParser
                                    key: aKey];
        if (nil == self)
        {
                return nil;
        }
        identities = [NSMutableArray new];
        value = identities;
        return self;
}

- (void)startElement:(NSString *)aName
                  attributes:(NSDictionary*)attributes
{
        if ([aName isEqualToString:@"item"])
        {
                [[[XMPPIdentity alloc] initWithXMLParser:parser                                                                             key:@"identity"] startElement:aName
                                                                                                                                  attributes:attributes];
        }
        else if ([aName isEqualToString:@"query"])
        {
                depth++;
        }
}

- (void) addidentity:(id)anIdentity
{
        [identities addObject:anIdentity];
}


@end
