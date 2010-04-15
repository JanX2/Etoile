@protocol ETTextGroup;
@protocol ETTextVisitor;
@class ETStyleBuilder;

/**
 * The ETText protocol is implemented by all objects in a structured text tree.
 * It describes an abstract way of interacting with regions of structured text,
 * which or may not have children.
 */
@protocol ETText <NSObject>
/**
 * Returns the length of this text fragment including children.
 */
@property (readonly) NSUInteger length;
/**
 * The parent element in the tree.
 */
@property (nonatomic, assign) id<ETTextGroup> parent;
/**
 * Returns the character at the specified index in the text object.  This
 * method is NSString-compatible.  
 */
- (unichar)characterAtIndex: (NSUInteger)anIndex;
/**
 * Custom attributes applied to this object.  These will override presentation
 * attributes provided by the style.  If this object has children then they may
 * override these attributes either by specifying their own custom attributes
 * or via their style.
 */
@property (nonatomic, copy) NSDictionary *customAttributes;
/**
 * Returns the type of this object.  The type is used when constructing a style.
 */
@property (nonatomic, retain) id textType;
/**
 * Sets custom attributes for a specified range.  When sent to a leaf node, the
 * range must cover the entire node.  When sent to any other node, it will
 * transform the tree as required to modify the specified range.
 */
- (void)setCustomAttributes: (NSDictionary*)attributes 
                      range: (NSRange)aRange;
/**
 * Builds the style from the specified index in this text object.  Returns the
 * end of the range for which this style is valid.
 */
- (NSUInteger)buildStyleFromIndex: (NSUInteger)anIndex
                 withStyleBuilder: (ETStyleBuilder*)aBuilder;
/**
 * Replaces the characters in the specified range with a string.  This method
 * is compatible with the same method in NSString and will transform the tree
 * as required to support the modification.
 */
- (void)replaceCharactersInRange: (NSRange)aRange
                      withString: (NSString*)aString;
/**
 * Appends the string to the current text object.
 */
- (void)appendString: (NSString*)aString;
/**
 * Splits the receiver at the specified index.  The returned value is a new
 * text tree containing all of the text before the index.  The receiver
 * contains only the elements after.
 */
- (id<ETText>)splitAtIndex: (NSUInteger)anIndex;
/**
 * Visits the element and it's children using the specified visitor.
 */
- (void)visitWithVisitor: (id<ETTextVisitor>)aVisitor;
/**
 * Returns a string representing the receiver.
 */
- (NSString*)stringValue;
@end

/**
 * The ETTextGroup protocol is adopted by elements in an ETText tree that
 * contain children.
 */
@protocol ETTextGroup <ETText>
/**
 * Notify the object that one of its children changed.  This may invalidate
 * caches in the parent, or cause them to be regenerated.
 */
- (void)childDidChange: (id<ETText>)aChild;
@end

/**
 * The visitor protocol is adopted by objects that wish to visit the text tree
 * in character order.  It can be used for exporting or transforming the text
 * tree.
 */
@protocol ETTextVisitor
/**
 * Sent at the start of every visited node.
 */
- (void)startTextNode: (id<ETText>)aNode;
/**
 * Sent when visiting a leaf node in the tree.  
 */
- (void)visitTextNode: (id<ETText>)aNode;
/**
 * Sent after visiting a node and all of its children.
 */
- (void)endTextNode: (id<ETText>)aNode;
@end

