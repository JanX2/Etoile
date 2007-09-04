#import <Foundation/Foundation.h>
#import "ETXMLParser.h"

@interface ParserTest :NSObject <ETXMLParserDelegate>
@end
@implementation ParserTest
- (void)characters:(NSString *)_chars
{
	NSLog(@"CDATA: %@", _chars);
}
- (void)startElement:(NSString *)_Name
          attributes:(NSDictionary*)_attributes
{
	NSLog(@"Starting element %@ with attributes %@", _Name, _attributes);
}
- (void)endElement:(NSString *)_Name
{
	NSLog(@"Ending element %@", _Name);
}
- (void) setParser:(id) XMLParser {}
- (void) setParent:(id) newParent {}
@end

int main(int argc, char ** argv)
{
	[NSAutoreleasePool new];
	ETXMLParser * parser = [ETXMLParser parserWithContentHandler:[ParserTest new]];
	//Uncomment to test parser as an SGML parser.
	//[parser setMode:sgml];
	for(unsigned int i=1 ; i<argc ; i++)
	{
		[parser parseFromSource:[NSString stringWithCString:argv[i]]];
	}
	return 0;
}
