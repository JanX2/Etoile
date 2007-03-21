#import "ETSerialiser.h"

@interface ETSerialiserBackendBinaryFile : NSObject<ETSerialiserBackend> {
	unsigned int indent;
	FILE * blobFile;
	FILE * indexFile;
}
- (void) setFile:(char*)filename;
@end
