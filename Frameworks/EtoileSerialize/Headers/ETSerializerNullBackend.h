/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>
#import <EtoileSerialize/ETSerializerBackend.h>

/**
 * Trivial backend which ignores all serialize messages.  Used by ETSerializer
 * when determining the size of structures pointed to by a pointer instance
 * variable.
 */
@interface ETSerializerNullBackend : NSObject <ETSerializerBackend> {}
@end
