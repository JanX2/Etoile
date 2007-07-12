#import "ETSerialiser.h"

@interface ETSerialiserBackendBinaryFile : NSObject<ETSerialiserBackend> {
	unsigned int indent;
	FILE * blobFile;
	FILE * indexFile;
	NSMapTable * offsets;
	NSMapTable * refCounts;
}
- (void) setFile:(char*)filename;
@end
