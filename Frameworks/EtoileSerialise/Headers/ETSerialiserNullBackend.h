#import "ETSerialiser.h"

/**
 * Trivial backend which ignores all serialise messages.  Used by ETSerialiser
 * when determining the size of structures pointed to by a pointer instance
 * variable.
 */
@interface ETSerialiserNullBackend : NSObject <ETSerialiserBackend> {}
@end
