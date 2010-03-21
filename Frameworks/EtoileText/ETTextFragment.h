#import "ETTextProtocols.h"
#import <CoreObject/COObject.h>

/**
 * A text fragment is a leaf node in a structured text tree.  It contains a run
 * of characters, a style, and optionally some presentation attributes that
 * will override those assigned by the style.
 *
 * Note that a text fragment may contain the empty strings.  This may be used
 * by subclasses to store references to external resources and other things
 * that would require a special character in NSAttributedString.
 */
@interface ETTextFragment : COObject<ETText>
{
	NSMutableString *text;
}
/**
 * The parent object in the text tree.
 */
@property (nonatomic, assign) id<ETTextGroup> parent;
/**
 * Initializes the text fragment with a string.  
 */
- (id)initWithString: (NSString*)string;
@end
