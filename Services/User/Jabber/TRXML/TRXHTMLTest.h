//
//  TRXHTMLTest.h
//  Jabber
//
//  Created by David Chisnall on 27/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ETXMLNullHandler.h"

@interface TRXHTMLTest : ETXMLNullHandler {
	IBOutlet NSTextView * inHTML;
	IBOutlet NSTextView * outHTML;	
}
- (IBAction) update:(id)sender;
@end
