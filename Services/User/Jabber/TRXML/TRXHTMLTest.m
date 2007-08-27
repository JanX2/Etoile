//
//  TRXHTMLTest.m
//  Jabber
//
//  Created by David Chisnall on 27/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TRXHTMLTest.h"
#import "TRXMLParser.h"
#import "TRXMLXHTML-IMParser.h"

@implementation TRXHTMLTest
- (void) addhtml:(NSAttributedString*)aString
{
	[[outHTML textStorage] setAttributedString:aString];
}

- (IBAction) update:(id)sender;
{
	id p = [[TRXMLParser alloc] init];
	[[TRXMLXHTML_IMParser alloc] initWithXMLParser:p
											parent:self
											   key:@"html"];
	[p parseFromSource:[inHTML string]];
	[p release];
}
@end
