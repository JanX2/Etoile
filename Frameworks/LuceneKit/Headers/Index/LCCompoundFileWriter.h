#ifndef __LUCENE_COMPOUND_FILE_WRITER__
#define __LUCENE_COMPOUND_FILE_WRITER__

#include <Foundation/Foundation.h>
#include "LuceneKit/Store/LCDirectory.h"

@class LCIndexOutput;
@class LCWriterFileEntry;

@interface LCCompoundFileWriter: NSObject
{
	id <LCDirectory> directory;
	NSString *fileName;
	NSMutableSet *ids;
	NSMutableArray *entries;
	BOOL merged;
}

- (id) initWithDirectory: (id <LCDirectory>) dir name: (NSString *) name;
- (id <LCDirectory>) directory;
- (NSString *) name;
- (void) addFile: (NSString *) file;
- (void) close;
- (void) copyFile: (LCWriterFileEntry *) source 
      indexOutput: (LCIndexOutput *) os
             data: (NSMutableData *) buffer;

@end

#endif /* __LUCENE_COMPOUND_FILE_WRITER__ */
