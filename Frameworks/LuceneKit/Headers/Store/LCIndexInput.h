#ifndef __LUCENE_STORE_INDEX_INPUT__
#define __LUCENE_STORE_INDEX_INPUT__

#include <Foundation/Foundation.h>

@interface LCIndexInput: NSObject <NSCopying>
{
}

- (long) readInt; // four-bytes
- (long) readVInt; // four-bytes
- (long long) readLong; // eight-bytes
- (long long) readVLong; // eight-bytes
- (NSString *) readString;
- (void) readChars: (NSMutableString *) buffer 
             start: (int) start 
	    length: (int) length;

/* override by subclass */
- (char) readByte;
- (void) readBytes: (NSMutableData *) b 
            offset: (int) offset 
	    length: (int) len;
- (void) close;
- (unsigned long long) filePointer;
- (void) seek: (unsigned long long) pos;
- (unsigned long long) length;

@end

#endif /* __LUCENE_STORE_INDEX_INPUT__ */
