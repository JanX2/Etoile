#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import <ETXML/ETXMLNode.h>
#import <ETXML/ETXMLParserDelegate.h>

@interface HTML: NSObject <UKTest, ETXMLParserDelegate>
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
	ETXMLParser *parser = [ETXMLParser parserWithContentHandler: self];
	UKTrue([parser parseFromSource: string]);
}
@end
