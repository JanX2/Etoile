#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileXML/ETXMLParser.h>
#import <EtoileXML/ETXMLParserDelegate.h>
#import <EtoileXML/ETXMLNullHandler.h>

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

- (id) initWithXMLParser: (ETXMLParser*)aParser
				  parent: (id)parent
                     key: (id)aKey;

@end
