//
//  TRXHTMLTest.m
//  Jabber
//
//  Created by David Chisnall on 27/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TRXHTMLTest.h"
#import "NSAttributedString+HTML.h"

@implementation TRXHTMLTest
- (IBAction) update:(id)sender;
{
	[[outHTML textStorage] setAttributedString:[NSAttributedString attributedStringWithHTML:[inHTML string]]];
}
@end
