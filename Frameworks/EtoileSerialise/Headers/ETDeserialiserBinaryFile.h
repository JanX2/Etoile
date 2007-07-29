#import "ETDeserialiser.h"

@interface ETDeserialiserBackendBinaryFile : NSObject <ETDeserialiserBackend>{
	NSData * data;
	NSMapTable * index;
	NSMapTable * refCounts;
	ETDeserialiser * deserialiser;
	CORef principalObjectRef;
}
@end
