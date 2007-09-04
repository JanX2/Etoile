//
//  TRXHTMLTest.m
//  Jabber
//
//  Created by David Chisnall on 27/08/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TRXHTMLTest.h"
#import "ETXMLParser.h"
#import "ETXMLXHTML-IMParser.h"

@implementation TRXHTMLTest
- (void) addhtml:(NSAttributedString*)aString
{
	[[outHTML textStorage] setAttributedString:aString];
}

- (IBAction) update:(id)sender;
{
	id p = [[ETXMLParser alloc] init];
	[p setMode:PARSER_MODE_SGML];
	[[ETXMLXHTML_IMParser alloc] initWithXMLParser:p
											parent:self
											   key:@"html"];
	[p parseFromSource:[inHTML string]];
	[p release];
}
@end
