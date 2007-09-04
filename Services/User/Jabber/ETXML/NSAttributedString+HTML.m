//
//  NSAttributedString+HTML.m
//  Jabber
//
//  Created by David Chisnall on 04/09/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSAttributedString+HTML.h"
#import "ETXMLParser.h"
#import "ETXMLXHTML-IMParser.h"
#import "ETXMLNullHandler.h"

@interface XHTMLCollector : ETXMLNullHandler {
@public
	NSAttributedString * html;
}
@end
@implementation XHTMLCollector
- (void) addhtml:(NSAttributedString*)aString
{
	html = aString;
}
@end

@implementation NSAttributedString (HTML)
+ (NSAttributedString*) attributedStringWithHTML:(NSString*)aString
{
	ETXMLParser * p = [[ETXMLParser alloc] init];
	XHTMLCollector * c = [[XHTMLCollector alloc] init];
	[p setMode:PARSER_MODE_SGML];
	[[ETXMLXHTML_IMParser alloc] initWithXMLParser:p
											parent:c
											   key:@"html"];
	[p parseFromSource:aString];
	[p release];
	NSAttributedString * html = c->html;
	[c release];
	return html;
}
@end
