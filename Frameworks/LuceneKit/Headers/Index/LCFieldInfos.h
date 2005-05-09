#ifndef __LUCENE_INDEX_FIELD_INFOS__
#define __LUCENE_INDEX_FIELD_INFOS__

#include <Foundation/Foundation.h>
#include "Store/LCDirectory.h"
#include "Document/LCDocument.h"
#include "Index/LCFieldInfo.h"
#include "Store/LCIndexInput.h"

@interface LCFieldInfos: NSObject
{
	NSMutableArray *byNumber;
	NSMutableDictionary *byName;
}

- (id) initWithDirectory: (id <LCDirectory>) d name: (NSString *) name;
- (void) addDocument: (LCDocument *) doc;
- (void) addIndexedCollection: (NSArray *) names
			  storeTermVector: (BOOL) storeTermVectors
  storePositionWithTermVector: (BOOL) storePositionWithTermVector
	storeOffsetWithTermVector: (BOOL) storeOffsetWithTermVector;
- (void) addCollection: (NSArray *) names isIndexed: (BOOL) isIndexed;

- (void) addName: (NSString *) name isIndexed: (BOOL) isIndexed;
- (void) addName: (NSString *) name
	   isIndexed: (BOOL) isIndexed
         isTermVectorStored: (BOOL)isTermVectorStored;
- (void) addName: (NSString *) name
       isIndexed: (BOOL) isIndexed
       isTermVectorStored: (BOOL)isTermVectorStored
       isStorePositionWithTermVector: (BOOL) isStorePositionWithTermVector
       isStoreOffsetWithTermVector: (BOOL) isStoreOffsetWithTermVector;
- (int) fieldNumber: (NSString *) fieldName;
- (LCFieldInfo *) fieldInfo: (NSString *) name;
- (NSString *) fieldName: (int) fieldNumber;
- (LCFieldInfo *) fieldInfoWithNumber: (int) number;
- (int) size;
- (BOOL) hasVectors;
- (void) write: (id <LCDirectory>) d name: (NSString *) name;
- (void) write: (LCIndexOutput *) output;

@end

#endif /* __LUCENE_INDEX_FIELD_INFOS__ */
