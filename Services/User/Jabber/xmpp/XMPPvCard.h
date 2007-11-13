//
//  XMPPvCard.h
//  Jabber
//
//  Created by David Chisnall on 12/11/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>
#import "ETXMLNullHandler.h"

@interface XMPPvCard : ETXMLNullHandler {
	ABPerson * person;
}

@end
