#import <Foundation/NSObject.h>

@class NSMutableDictionary;
@class NSDictionary;

@protocol ETStyleTransformer
- (NSDictionary*)presentationAttributesForType: (id)aType;
@end

/**
 * The ETStyleBuilder class is used to construct a presentation style for a
 * specific region of text in the tree.  It is passed down from the root of the
 * tree to the leaf, collecting attributes from styles and from overrides as it
 * goes.
 */
@interface ETStyleBuilder : NSObject
{
	NSMutableDictionary *styleTransformers;
}
/**
 * The current style.  This can be modified externally if required.  It should
 * be reset to nil if you wish to reuse the style builder.  
 */
@property (nonatomic, retain) NSMutableDictionary *style;
/**
 * Registers a style transformer.  Style transformers are used to generate
 * presentation styles from semantic style information.
 *
 * Note: NOT YET IMPLEMENTED.
 */
- (void)registerTransformer: (id<ETStyleTransformer>)aTransformer
               forTypeNamed: (NSString*)styleName;
/**
 * Adds attributes from the specified style.  This method is empty in the
 * superclass.  Subclasses implementing different styling policies should
 * override this method.
 */
- (void)addAttributesForStyle: (id)style;
/**
 * Adds custom presentation attributes.
 */
- (void)addCustomAttributes: (NSDictionary*)attributes;
@end
