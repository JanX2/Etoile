#include <LuceneKit/Search/LCFieldSortedHitQueue.h>
#include <LuceneKit/Search/LCFieldCacheImpl.h>
#include <LuceneKit/Search/LCScoreDoc.h>
#include <LuceneKit/Search/LCScoreDocComparator.h>
#include <LuceneKit/GNUstep/GNUstep.h>

@implementation LCFieldSortedHitQueue

/**
* Expert: A hit queue for sorting by hits by terms in more than one field.
 * Uses <code>FieldCache.DEFAULT</code> for maintaining internal term lookup tables.
 *
 * <p>Created: Dec 8, 2003 12:56:03 PM
 *
 * @author  Tim Jones (Nacimiento Software)
 * @since   lucene 1.4
 * @version $Id$
 * @see Searchable#search(Query,Filter,int,Sort)
 * @see FieldCache
 */

/**
* Creates a hit queue sorted by the given list of fields.
 * @param reader  Index to use.
 * @param fields Field names, in priority order (highest priority first).  Cannot be <code>null</code> or empty.
 * @param size  The number of hits to retain.  Must be greater than zero.
 * @throws IOException
 */
- (id) initWithReader: (LCIndexReader *) reader        
		   sortFields: (NSArray *) f size: (int) size
{
	self = [super initWithSize: size];
	int n = [fields count];
	comparators = [[NSMutableArray alloc] init];
	fields = [[NSMutableArray alloc] init];
	int i;
	cache = [LCComparatorCache sharedComparatorCache];
	for (i=0; i<n; ++i) {
		LCSortField *field = [f objectAtIndex: i];
		NSString *fieldname = [field field];
		[comparators addObject: [cache cachedComparator: reader field: fieldname type: [field type] factory: [field factory]]];
		[fields addObject: [[LCSortField alloc] initWithField: fieldname type: [[comparators objectAtIndex: i] sortType] reverse: [field reverse]]];
	}
	maxscore = 1.0f;
	return self;
}

/* LuceneKit: use old style -lessThan method */
/**
* Returns whether <code>a</code> is less relevant than <code>b</code>.
 * @param a ScoreDoc
 * @param b ScoreDoc
 * @return <code>true</code> if document <code>a</code> should be sorted after document <code>b</code>.
 */
- (BOOL) lessThan: (id) a : (id) b
{
	LCScoreDoc *docA = (LCScoreDoc *) a;
	LCScoreDoc *docB = (LCScoreDoc *) b;
	
	// keep track of maximum score
	if ([docA score] > maxscore) maxscore = [docA score];
	if ([docB score] > maxscore) maxscore = [docB score];
	
	// run comparators
	int n = [comparators count];
	int i;
	NSComparisonResult c = NSOrderedSame;
	for (i=0; i<n && c == NSOrderedSame; ++i) {
		c = ([[fields objectAtIndex: i] reverse]) ? 
	    [[comparators objectAtIndex: i] compare: docB to: docA] :
	    [[comparators objectAtIndex: i] compare: docA to: docB];
	}
	// avoid random sort order that could lead to duplicates (bug #31241):
	if (c == NSOrderedSame)
	{
		if ([docA document] > [docB document])
			return YES;
	}
	if (c == NSOrderedDescending)
	{
		return YES;
		//  return c > 0;
	}
	else
		return NO;
}

/**
* Given a FieldDoc object, stores the values used
 * to sort the given document.  These values are not the raw
 * values out of the index, but the internal representation
 * of them.  This is so the given search hit can be collated
 * by a MultiSearcher with other search hits.
 * @param  doc  The FieldDoc to store sort values into.
 * @return  The same FieldDoc passed in.
 * @see Searchable#search(Query,Filter,int,Sort)
 */
- (LCFieldDoc *) fillFields: (LCFieldDoc *) doc
{
	int n = [comparators count];
	NSMutableArray *f = [[NSMutableArray alloc] init];
	int i;
	for (i=0; i<n; ++i)
		[f addObject: [[comparators objectAtIndex: i] sortValue: doc]];
	[doc setFields: f ];
	if (maxscore > 1.0f) [doc setScore: ([doc score] / maxscore)];   // normalize scores
	return doc;
}


/** Returns the SortFields being used by this hit queue. */
- (NSArray *) sortFields
{
	return fields;
}

@end

static LCComparatorCache *sharedInstance;

@implementation LCComparatorCache

+ (LCComparatorCache *) sharedComparatorCache
{
	if (sharedInstance == nil)
    {
		sharedInstance = [[LCComparatorCache alloc] init];
    }
	return sharedInstance;
}

- (id) init
{
	self = [super init];
	comparators = [[NSMutableDictionary alloc] init];
	return self;
}

/** Returns a comparator if it is in the cache. */
- (id <LCScoreDocComparator>) lookup: (LCIndexReader *) reader
							   field: (NSString *) field type: (int) type
							 factory: (id) factory
{
	LCEntry *entry;
	if (factory != nil)
	{
		entry = [[LCEntry alloc] initWithField: field custom: factory];
	}
	else
	{
		entry = [[LCEntry alloc] initWithField: field type: type];
	}
	
	NSDictionary *readerCache = [comparators objectForKey: reader];
	if (readerCache == nil) return nil;
	return [readerCache objectForKey: entry];
}

/** Stores a comparator into the cache. */
- (id) store: (LCIndexReader *) reader field: (NSString *) field 
		type: (int) type factory: (id) factory value: (id) value
{
	LCEntry *entry;
	if (factory != nil)
	{
		entry = [[LCEntry alloc] initWithField: field custom: factory];
	}
	else
	{
		entry = [[LCEntry alloc] initWithField: field type: type];
	}
	NSMutableDictionary *readerCache = [comparators objectForKey: reader];
	if (readerCache == nil) 
	{
		readerCache = [[NSMutableDictionary alloc] init];
		AUTORELEASE(readerCache);
	}
	[readerCache setObject: value forKey: entry];
	[comparators setObject: readerCache forKey: reader];
	return readerCache;
}

- (id <LCScoreDocComparator>) cachedComparator: (LCIndexReader *) reader
										 field: (NSString *) fieldname
										  type: (int) type
									  //locale: (LCLocale *) locale
									   factory: (id) factory
{
	if (type == LCSortField_DOC) 
		return AUTORELEASE([[LCIndexOrderScoreDocComparator alloc] init]);
	if (type == LCSortField_SCORE) 
		return AUTORELEASE([[LCRelevanceScoreDocComparator alloc] init]);
	id <LCScoreDocComparator> comparator = [self lookup: reader field: fieldname type: type factory: factory];
    if (comparator == nil) {
		switch (type) {
			case LCSortField_AUTO:
				comparator = [self comparatorObject: reader field: fieldname];
				break;
			case LCSortField_INT:
				comparator = [self comparatorInt: reader field: fieldname];
				break;
			case LCSortField_FLOAT:
				comparator = [self comparatorFloat: reader field: fieldname];
				break;
			case LCSortField_STRING:
#if 0
				if (locale != null) comparator = comparatorStringLocale (reader, fieldname, locale);
				else comparator = comparatorString (reader, fieldname);
#endif
				comparator = [self comparatorString: reader field: fieldname];
				break;
			case LCSortField_CUSTOM:
				comparator = [factory newComparator: reader field: fieldname];
				break;
			default:
				NSLog(@"unknown field type %d", type);
				return nil;
		}
		[self store: reader field: fieldname type: type factory: factory value: comparator];
    }
    return comparator;
}

/**
* Returns a comparator for sorting hits according to a field containing integers.
 * @param reader  Index to use.
 * @param fieldname  Field containg integer values.
 * @return  Comparator for sorting hits.
 * @throws IOException If an error occurs reading the index.
 */
- (id <LCScoreDocComparator>) comparatorInt: (LCIndexReader *) reader
									  field: (NSString *) fieldname
{
	NSDictionary *fieldOrder = [[LCFieldCache defaultCache] ints: reader field: fieldname];
	id object = [[LCIntsScoreDocComparator alloc] initWithValues: fieldOrder];
	return AUTORELEASE(object);
	
}

- (id <LCScoreDocComparator>) comparatorFloat: (LCIndexReader *) reader 
										field: (NSString *) fieldname
{
	NSDictionary *fieldOrder = [[LCFieldCache defaultCache] floats: reader field: fieldname];
	id object = [[LCFloatsScoreDocComparator alloc] initWithValues: fieldOrder];
	return AUTORELEASE(object);
	
}
- (id <LCScoreDocComparator>) comparatorString: (LCIndexReader *) reader
										 field: (NSString *) fieldname;
{
	LCStringIndex *fieldOrder = [[LCFieldCache defaultCache] stringIndex: reader field: fieldname];
	id object = [[LCStringsScoreDocComparator alloc] initWithStringIndex: fieldOrder];
	return AUTORELEASE(object);
}

#if 0
+ (LCScoreDocComparator *) comparatorStringLocale: (LCIndexReader *) reader field: (NSString *) fieldname locale: (LCLocale *) locale;
#endif
- (id <LCScoreDocComparator>) comparatorObject: (LCIndexReader *) reader
										 field: (NSString *) fieldname
{
	id lookupArray = [[LCFieldCache defaultCache] objects: reader field: fieldname];
	if ([lookupArray isKindOfClass: [LCStringIndex class]]) {
		return [self comparatorString: reader field: fieldname];
    } 
	else if ([lookupArray isKindOfClass: [NSDictionary class]])
	{
		/* test value */
		id value = [[lookupArray objectEnumerator] nextObject];
		if ([value isKindOfClass: [NSString class]])
			return [self comparatorString: reader field: fieldname];
		else if ([value isKindOfClass: [NSNumber class]])
		{
			const char* type = [value objCType];
			if (strcmp(type, @encode(int)))
				return [self comparatorInt: reader field: fieldname];
			else if (strcmp(type, @encode(float)))
				return [self comparatorFloat: reader field: fieldname];
		}
	}
	NSLog(@"unknown data type in field '%@'", fieldname);
	return nil;
}

@end

@implementation LCIntsScoreDocComparator

- (id) initWithValues: (NSDictionary *) values
{
	self = [super init];
	ASSIGN(fieldOrder, values);
	return self;
}

- (NSComparisonResult) compare: (LCScoreDoc *) i to: (LCScoreDoc*) j
{
	int fi = [[fieldOrder objectForKey: [NSNumber numberWithInt: [i document]]] intValue];
	int fj = [[fieldOrder objectForKey: [NSNumber numberWithInt: [j document]]] intValue];
	if (fi < fj) return NSOrderedAscending;
	if (fi > fj) return NSOrderedDescending;
	return NSOrderedSame;
}

- (id) sortValue: (LCScoreDoc *) i
{
	return [fieldOrder objectForKey: [NSNumber numberWithInt: [i document]]];
}

- (int) sortType
{
	return LCSortField_INT;
}

@end

/**
* Returns a comparator for sorting hits according to a field containing floats.
 * @param reader  Index to use.
 * @param fieldname  Field containg float values.
 * @return  Comparator for sorting hits.
 * @throws IOException If an error occurs reading the index.
 */
@implementation LCFloatsScoreDocComparator

- (id) initWithValues: (NSDictionary *) values
{
	self = [super init];
	ASSIGN(fieldOrder, values);
	return self;
}

- (NSComparisonResult) compare: (LCScoreDoc *) i to: (LCScoreDoc*) j
{
	float fi = [[fieldOrder objectForKey: [NSNumber numberWithInt: [i document]]] floatValue];
	float fj = [[fieldOrder objectForKey: [NSNumber numberWithInt: [j document]]] floatValue];
	if (fi < fj) return NSOrderedAscending;
	if (fi > fj) return NSOrderedDescending;
	return NSOrderedSame;
}

- (id) sortValue: (LCScoreDoc *) i
{
	return [fieldOrder objectForKey: [NSNumber numberWithInt: [i document]]];
}

- (int) sortType
{
	return LCSortField_FLOAT;
}

@end

/**
* Returns a comparator for sorting hits according to a field containing strings.
 * @param reader  Index to use.
 * @param fieldname  Field containg string values.
 * @return  Comparator for sorting hits.
 * @throws IOException If an error occurs reading the index.
 */
@implementation LCStringsScoreDocComparator

- (id) initWithStringIndex: (LCStringIndex *) i 
{
	self = [super init];
	ASSIGN(index, i);
	return self;
}

- (void) dealloc
{
	DESTROY(index);
	[super dealloc];
}

- (NSComparisonResult) compare: (LCScoreDoc *) i to: (LCScoreDoc*) j
{
	int fi = [[[index order] objectForKey: [NSNumber numberWithInt: [i document]]] intValue];
	int fj = [[[index order] objectForKey: [NSNumber numberWithInt: [j document]]] intValue];
	if (fi < fj) return NSOrderedAscending;
	if (fi > fj) return NSOrderedDescending;
	return NSOrderedSame;
}

- (id) sortValue: (LCScoreDoc *) doc
{
	int i = [[[index order] objectForKey: [NSNumber numberWithInt: [doc document]]] intValue];
	return [[index lookup] objectAtIndex: i];
}

- (int) sortType
{
	return LCSortField_STRING;
}

@end
/**
* Returns a comparator for sorting hits according to a field containing strings.
 * @param reader  Index to use.
 * @param fieldname  Field containg string values.
 * @return  Comparator for sorting hits.
 * @throws IOException If an error occurs reading the index.
 */
#if 0
static ScoreDocComparator comparatorStringLocale (final IndexReader reader, final String fieldname, final Locale locale)
throws IOException {
    final Collator collator = Collator.getInstance (locale);
    final String field = fieldname.intern();
    final String[] index = FieldCache.DEFAULT.getStrings (reader, field);
    return new ScoreDocComparator() {
		
		public final int compare (final ScoreDoc i, final ScoreDoc j) {
			return collator.compare (index[i.doc], index[j.doc]);
		}
		
		public Comparable sortValue (final ScoreDoc i) {
			return index[i.doc];
		}
		
		public int sortType() {
			return SortField.STRING;
		}
    };
}
#endif
