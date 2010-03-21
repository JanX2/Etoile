#import <EtoileFoundation/EtoileFoundation.h>

@class ETTextDocument;
/**
 * The ETXMLTextParser class is a delegate for ETXMLParser which generates a
 * structured text tree from an XML document.  
 */
@interface ETXMLTextParser : ETXMLNullHandler <ETXMLParserDelegate>
{
	id style;
	NSDictionary *customAttributes;
	NSMutableArray *children;
	NSMutableString *text;
}
/**
 * The document used to accumulate the styles types while parsing.
 */
@property (nonatomic, assign) ETTextDocument *document;
@end
