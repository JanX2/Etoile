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
	NSMutableSet *types;
}
/**
 * The structured text stored by this object.
 */
@property (nonatomic, retain) id<ETText> text;
/**
 * Returns a unique type object from a dictionary describing the type.  In the
 * current implementation, the returned object is a dictionary.  This is an
 * implementation detail and should not be relied upon.  Please use KVC for
 * accessing any of the attributes of the returned object.
 */
- (id)typeFromDictionary: (NSDictionary*)aDictionary;
@end
