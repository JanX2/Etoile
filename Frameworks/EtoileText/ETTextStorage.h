#import "ETTextProtocols.h"
#import "AppKit/NSTextStorage.h"

@class ETStyleBuilder;
/** 
 * Façade class that wraps an ETText tree into something the OpenStep text
 * system can play with.
 */
@interface ETTextStorage : NSTextStorage
/**
 * The structured text presented by this object.
 */
@property (nonatomic, retain) id<ETText>text;
/**
 * The style builder used to map semantic attributes to presentation styles.
 */
@property (nonatomic, retain) ETStyleBuilder *style;
@end
