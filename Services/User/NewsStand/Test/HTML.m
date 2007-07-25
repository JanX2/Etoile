#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import <TRXML/TRXMLNode.h>
#import <TRXML/TRXMLParserDelegate.h>

@interface HTML: NSObject <UKTest, TRXMLParserDelegate>
@end

@implementation HTML
- (void)characters:(NSString *)_chars
{
	NSLog(@"%@", _chars);
}

- (void)startElement:(NSString *)_Name
          attributes:(NSDictionary*)_attributes
{
}

- (void)endElement:(NSString *)_Name
{
}

- (void) setParser:(id) XMLParser
{
}

- (void) setParent:(id) newParent
{
}

- (void) testHTML
{
	NSData *data = [NSData dataWithContentsOfFile: @"html.xml"];
	NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];

	// READ
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: self];
	UKTrue([parser parseFromSource: string]);
}
@end
