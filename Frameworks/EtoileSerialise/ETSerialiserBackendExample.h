#import "ETSerialiser.h"

@interface ETSerialiserBackendExample : NSObject<ETSerialiserBackend> {
	unsigned int indent;
	NSMutableDictionary * referenceCounts;
}
@end
