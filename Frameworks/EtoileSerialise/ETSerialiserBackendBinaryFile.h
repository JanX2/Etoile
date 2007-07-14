#import "ETSerialiser.h"

@interface ETSerialiserBackendBinaryFile : NSObject<ETSerialiserBackend> {
	unsigned int indent;
	FILE * blobFile;
	NSString * fileName;
	NSMapTable * offsets;
	NSMapTable * refCounts;
	int version;
}
- (void) setFile:(const char*)filename;
@end
