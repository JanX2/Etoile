#import "ETSerialiser.h"

@interface ETSerialiserBackendExample : NSObject<ETSerialiserBackend> {
	FILE * outFile;
	unsigned int indent;
	NSMutableDictionary * referenceCounts;
	int version;
}
@end
