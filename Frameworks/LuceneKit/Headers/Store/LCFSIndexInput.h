#ifndef __LUCENE_STORE_FSINDEX_INPUT__
#define __LUCENE_STORE_FSINDEX_INPUT__

#include <LuceneKit/Store/LCIndexInput.h>

@interface LCFSIndexInput: LCIndexInput
{
	NSFileHandle *handle;
	NSString *path;
	unsigned long long length;
}

- (id) initWithFile: (NSString *) absolutePath;
@end
#endif /* __LUCENE_STORE_FSINDEX_INPUT__ */
