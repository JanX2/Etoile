#ifndef __LUCENE_DOCUMENT_FIELD__
#define __LUCENE_DOCUMENT_FIELD__

#include <Foundation/Foundation.h>
#include <LuceneKit/Java/LCReader.h>

typedef enum _LCStore_Type {
	LCStore_Compress,
	LCStore_YES,
	LCStore_NO
} LCStore_Type;

typedef enum _LCIndex_Type {
	LCIndex_NO,
	LCIndex_Tokenized,
	LCIndex_Untokenized
} LCIndex_Type;

typedef enum _LCTermVector_Type {
	LCTermVector_NO,
	LCTermVector_YES,
	LCTermVector_WithPositions,
	LCTermVector_WithOffsets,
	LCTermVector_WithPositionsAndOffsets
} LCTermVector_Type;

@interface LCField: NSObject
{
	NSString *name;
	id fieldsData;
	BOOL storeTermVector;
	BOOL storeOffsetWithTermVector;
	BOOL storePositionWithTermVector;
	BOOL isStored, isIndexed, isTokenized;
	BOOL isBinary, isCompressed;
	float boost;
}

- (void) setBoost: (float) boost;
- (float) boost;
- (NSString *) name;
- (NSString *) stringValue;
- (id <LCReader>) readerValue;
- (NSData *) binaryValue;
- (LCField *) initWithName: (NSString *) name
					string: (NSString *) string
					 store: (LCStore_Type) store
					 index: (LCIndex_Type) index;
- (LCField *) initWithName: (NSString *) name
					string: (NSString *) string
					 store: (LCStore_Type) store
					 index: (LCIndex_Type) index
				termVector: (LCTermVector_Type) tv;
- (LCField *) initWithName: (NSString *) name
					reader: (id <LCReader>) reader;
- (LCField *) initWithName: (NSString *) name
					reader: (id <LCReader>) reader
				termVector: (LCTermVector_Type) termVector;
- (id) initWithName: (NSString *) name
			  value: (NSData *) value
			  store: (LCStore_Type) store;
- (void) setStoreTermVector: (LCTermVector_Type) termVector;
- (BOOL) isStored;
- (BOOL) isIndexed;
- (BOOL) isTokenized;
- (BOOL) isCompressed;
- (BOOL) isTermVectorStored;
- (BOOL) isOffsetWithTermVectorStored;
- (BOOL) isPositionWithTermVectorStored;
- (BOOL) isBinary;

@end

#endif /* __LUCENE_DOCUMENT_FIELD__ */
