#import <EtoileFoundation/EtoileFoundation.h>

@class ETTextDocument;

@interface ETXMLTextParser : ETXMLNullHandler <ETXMLParserDelegate>
{
	id style;
	NSDictionary *customAttributes;
	NSMutableArray *children;
	NSMutableString *text;
}
@property (nonatomic, assign) ETTextDocument *document;
@end
