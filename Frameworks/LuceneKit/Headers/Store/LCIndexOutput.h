#ifndef __LUCENE_STORE_INDEX_OUTPUT__
#define __LUCENE_STORE_INDEX_OUTPUT__

#include <Foundation/Foundation.h>

@interface LCIndexOutput: NSObject

- (void) writeInt: (long) i;
- (void) writeVInt: (long) i;
- (void) writeLong: (long long) i;
- (void) writeVLong: (long long) i;
- (void) writeString: (NSString *) s;
- (void) writeChars: (NSString *) s start: (int) start length: (int) length;
/* Override by subclass */
- (void) writeByte: (char) b;
- (void) writeBytes: (NSData *)b length: (int) len;
- (void) flush;
- (void) close;
- (unsigned long long) filePointer;
- (void) seek: (unsigned long long) pos;
- (unsigned long long) length;

@end

#endif /* __LUCENE_STORE_INDEX_OUTPUT__ */
