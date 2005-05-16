#ifndef __LUCENE_SEARCH_FIELD_SORTED_HIT_QUEUE__
#define __LUCENE_SEARCH_FIELD_SORTED_HIT_QUEUE__

#include <LuceneKit/Util/LCPriorityQueue.h>
#include <LuceneKit/Index/LCIndexReader.h>
#include <LuceneKit/Search/LCScoreDocComparator.h>
#include <LuceneKit/Search/LCSortComparatorSource.h>
#include <LuceneKit/Search/LCFieldCache.h>
#include <LuceneKit/Search/LCFieldDoc.h>

@interface LCIntsScoreDocComparator: NSObject <LCScoreDocComparator>
{
	NSDictionary *fieldOrder;
}
- (id) initWithValues: (NSDictionary *) values;
@end

@interface LCFloatsScoreDocComparator: NSObject <LCScoreDocComparator>
{
	NSDictionary *fieldOrder;
}
- (id) initWithValues: (NSDictionary *) values;
@end

@interface LCStringsScoreDocComparator: NSObject <LCScoreDocComparator>
{
	LCStringIndex *index;
}
- (id) initWithStringIndex: (LCStringIndex *) index;
@end

/* LuceneKit: new class */
@interface LCComparatorCache: NSObject
{
	NSMutableDictionary *comparators;
}
+ (LCComparatorCache *) sharedComparatorCache;
- (id <LCScoreDocComparator>) lookup: (LCIndexReader *) reader 
							   field: (NSString *) field type: (int) type 
							 factory: (id) factory;
- (id) store: (LCIndexReader *) reader field: (NSString *) field 
		type: (int) type factory: (id) factory value: (id) value;
- (id <LCScoreDocComparator>) cachedComparator: (LCIndexReader *) reader
										 field: (NSString *) fieldname
										  type: (int) type
									  //locale: (LCLocale *) locale
									   factory: (id <LCSortComparatorSource>) factory;
- (id <LCScoreDocComparator>) comparatorInt: (LCIndexReader *) reader 
									  field: (NSString *) fieldname;
- (id <LCScoreDocComparator>) comparatorFloat: (LCIndexReader *) 
								 reader field: (NSString *) fieldname;
- (id <LCScoreDocComparator>) comparatorString: (LCIndexReader *) reader 
										 field: (NSString *) fieldname;
#if 0
+ (LCScoreDocComparator *) comparatorStringLocale: (LCIndexReader *) reader field: (NSString *) fieldname locale: (LCLocale *) locale;
#endif
- (id <LCScoreDocComparator>) comparatorObject: (LCIndexReader *) reader 
										 field: (NSString *) fieldname;

@end

@interface LCFieldSortedHitQueue: LCPriorityQueue
{
	/** Stores a comparator corresponding to each field being sorted by */
	NSMutableArray *comparators;
	/** Stores the sort criteria being used. */
	NSMutableArray *fields;
	/** Stores the maximum score value encountered, for normalizing.
		*  we only care about scores greater than 1.0 - if all the scores
		*  are less than 1.0, we don't have to normalize. */
	float maxscore;
	LCComparatorCache *cache;
}

- (id) initWithReader: (LCIndexReader *) reader 
		   sortFields: (NSArray *) fields size: (int) size;

- (LCFieldDoc *) fillFields: (LCFieldDoc *) doc;
- (NSArray *) sortFields;

@end

#endif /* __LUCENE_SEARCH_FIELD_SORTED_HIT_QUEUE__ */
