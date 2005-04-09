#ifndef __LUCENE_INDEX_COMPOUND_FILE_READER__
#define __LUCENE_INDEX_COMPOUND_FILE_READER__

#include "Store/LCDirectory.h"
#include <Foundation/Foundation.h>

#if 0
@interface LCFileEntry: NSObject
{
	long offset;
	long length;
}
- (long) offset;
- (long) length;
- (void) setOffset: (long) o;
- (void) setLength: (long) l;

@end
#endif

@class LCCompoundFileReader;

@interface LCCSIndexInput: LCIndexInput <NSCopying>
{
	LCCompoundFileReader *reader;
	LCIndexInput *base;
	long long fileOffset;
	long long length;
	long long filePointer;
}
- (id) initWithCompoundFileReader: (LCCompoundFileReader *) r
       indexInput: (LCIndexInput *) base offset: (long long) fileOffset
       length: (long long) length;
@end

@interface LCCompoundFileReader: NSObject <LCDirectory>
{
	id <LCDirectory> directory;
	NSString *fileName;
	LCIndexInput *stream;
	NSMutableDictionary *entries;
}
- (id) initWithDirectory: (id <LCDirectory>) dir
       name: (NSString *) name;
- (id <LCDirectory>) directory;
- (NSString *) name;
//- makeLock: (NSString *) name;

@end

#endif /* __LUCENE_INDEX_COMPOUND_FILE_READER__ */
