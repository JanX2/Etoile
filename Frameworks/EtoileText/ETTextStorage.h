#import "ETTextProtocols.h"
#import "AppKit/NSTextStorage.h"

@class ETStyleBuilder;
/** 
 * Façade class that wraps an ETText tree into something the OpenStep text
 * system can play with.
 */
@interface ETTextStorage : NSTextStorage
@property (nonatomic, retain) id<ETText>text;
@property (nonatomic, retain) ETStyleBuilder *style;
@end
