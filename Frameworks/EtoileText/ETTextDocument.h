#import <CoreObject/CoreObject.h>
#import "ETTextProtocols.h"

@class NSMutableSet;
@class NSMutableDictionary;
@class ETStyleTransformer;

/**
 * An ETTextDocument represents a text document.  This includes both structured
 * text and a set of types.
 */
@interface ETTextDocument : COObject 
{
	NSMutableDictionary *styleTransformers;
	NSMutableSet *types;
}
/**
 * The structured text stored by this object.
 */
@property (nonatomic, retain) id<ETText> text;
/**
 * Registers a style transformer.  Style transformers are used to generate
 * presentation styles from semantic style information.
 *
 * Note: NOT YET IMPLEMENTED.
 */
- (void)registerTransformer: (ETStyleTransformer*)aTransformer
              forStyleNamed: (NSString*)styleName;
/**
 * Returns a unique type object from a dictionary describing the type.  In the
 * current implementation, the returned object is a dictionary.  This is an
 * implementation detail and should not be relied upon.  Please use KVC for
 * accessing any of the attributes of the returned object.
 */
- (id)typeFromDictionary: (NSDictionary*)aDictionary;
@end
