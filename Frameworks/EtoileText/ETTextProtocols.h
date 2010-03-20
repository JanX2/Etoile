@protocol ETTextGroup;
@protocol ETTextVisitor;
@class ETStyleBuilder;

@protocol ETText <NSObject>
/**
 * Returns the length of this text fragment including children.
 */
@property (readonly) NSUInteger length;
@property (nonatomic, assign) id<ETTextGroup> parent;
/**
 * Returns the character at the specified index in the text object.  This
 * method is NSString-compatible.  
 */
- (unichar)characterAtIndex: (NSUInteger)anIndex;
@property (nonatomic, copy) NSDictionary *customAttributes;
@property (nonatomic, retain) id type;
- (void)setCustomAttributes: (NSDictionary*)attributes 
                      range: (NSRange)aRange;
/**
 * Builds the style from the specified index in this text object.  Returns the
 * end of the range for which this style is valid.
 */
- (NSUInteger)buildStyleFromIndex: (NSUInteger)anIndex
                 withStyleBuilder: (ETStyleBuilder*)aBuilder;
- (void)replaceCharactersInRange: (NSRange)aRange
                      withString: (NSString*)aString;
- (id<ETText>)splitAtIndex: (NSUInteger)anIndex;
- (void)visitWithVisitor: (id<ETTextVisitor>)aVisitor;
- (NSString*)stringValue;
@end

@protocol ETTextGroup
- (void)childDidChange: (id<ETText>)aChild;
@end

@protocol ETTextVisitor
- (void)startTextNode: (id<ETText>)aNode;
- (void)visitTextNode: (id<ETText>)aNode;
- (void)endTextNode: (id<ETText>)aNode;
@end

