#include "LCFieldCacheImpl.h"
#include "GNUstep.h"

/**
* Expert: The default cache implementation, storing all values in memory.
 * A WeakHashMap is used for storage.
 *
 * <p>Created: May 19, 2004 4:40:36 PM
 *
 * @author  Tim Jones (Nacimiento Software)
 * @since   lucene 1.4
 * @version $Id$
 */
/** Expert: Every key in the internal cache is of this type. */
@implementation LCEntry
- (id) initWithField: (NSString *) f
				type: (LCSortFieldType) t
{
	self = [super init];
	ASSIGN(field, f);
	type = t;
	custom = nil;
	return self;
}

- (id) initWithField: (NSString *) f
			  custom: (id) c
{
	self = [self initWithField: f type: LCSortField_CUSTOM];
	ASSIGN(custom, c);
	return self;
}

- (NSString *) field { return field; }
- (LCSortFieldType) type { return type; }
- (id) custom { return custom; }
- (void) setField: (NSString *) f { ASSIGN(field, f); }
- (void) setType: (LCSortFieldType) t { type = t; }
- (void) setCustom: (id) c { ASSIGN(custom, c); }


- (BOOL) isEqual: (id) o
{
	if ([o isKindOfClass: [self class]])
	{
		LCEntry *other = (LCEntry *) o;
		if ([[other field] isEqualToString: field] && ([other type] == type))
		{
			if (([other custom] == nil) && (custom == nil))
			{
				return YES;
			}
			else if ([[other custom] isEqual: custom])
			{
				return YES;
			}
		}
	}
	return NO;
}

- (unsigned) hash
{
	return [field hash] ^ type ^ ((custom == nil) ? 0 : [custom hash]);
}

- (id) copyWithZone: (NSZone *) zone
{
	LCEntry *entry = [[LCEntry allocWithZone: zone] initWithField: AUTORELEASE([[self field] copy]) type: [self type]];
	[entry setCustom: [self custom]];
	return entry;
}

@end

/** Indicator for StringIndex values in the cache. */
// NOTE: the value assigned to this constant must not be
// the same as any of those in SortField!!
//
static int LCFieldCache_STRING_INDEX = -1;

@implementation LCFieldCacheImpl

- (id) init
{
	self = [super init];
	cache = [[NSMutableDictionary alloc] init];
	return self;
}

- (void) dealloc
{
	DESTROY(cache);
	[super dealloc];
}

/** See if an object is in the cache. */
- (id) lookup: (LCIndexReader *) reader field: (NSString *) field
		 type: (LCSortFieldType) type
{
	LCEntry *entry = [[LCEntry alloc] initWithField: field type: type];
	//    synchronized (this) {
	NSDictionary *readerCache = [cache objectForKey: reader];
	if (readerCache == nil) return nil;
	AUTORELEASE(entry);
	return [readerCache objectForKey: entry];
	//    }
}

/** See if a custom object is in the cache. */
- (id) lookup: (LCIndexReader *) reader field: (NSString *) field
	 comparer: (id) comparer
{
	LCEntry *entry = [[LCEntry alloc] initWithField: field custom: comparer];
	//    synchronized (this) {
	NSDictionary *readerCache = [cache objectForKey: reader];
	if (readerCache == nil) return nil;
	AUTORELEASE(entry);
	return [readerCache objectForKey: entry];
	//    }
}

/** Put an object into the cache. */
- (id) store: (LCIndexReader *) reader field: (NSString *) field
		type: (LCSortFieldType) type custom: (id) value
{
	LCEntry *entry = [[LCEntry alloc] initWithField: field type: type];
	//    synchronized (this) {
	NSMutableDictionary *readerCache = [cache objectForKey: reader];
	if (readerCache == nil)
	{
		readerCache = [[NSMutableDictionary alloc] init];
		AUTORELEASE(readerCache);
	}
	[readerCache setObject: value forKey: entry];
	[cache setObject: readerCache forKey: reader];
	AUTORELEASE(entry);
	return readerCache;
	//    }
}

/** Put a custom object into the cache. */
- (id) store: (LCIndexReader *) reader field: (NSString *) field
	comparer: (id) comparer custom: (id) value
{
	LCEntry *entry = [[LCEntry alloc] initWithField: field custom: comparer];
	//    synchronized (this) {
	NSMutableDictionary *readerCache = [cache objectForKey: reader];
	if (readerCache == nil)
	{
		readerCache = [[NSMutableDictionary alloc] init];
		AUTORELEASE(readerCache);
	}
	[readerCache setObject: value forKey: entry];
	[cache setObject: readerCache forKey: reader];
	AUTORELEASE(entry);
	return readerCache;
	//    }
}

#if 0 // FIXME: need to update to lastest version.
   private static final IntParser INT_PARSER = new IntParser() {
    	       public int parseInt(String value) {
	        	         return Integer.parseInt(value);
				  	       }
					        	     };
							      	 
								  	   private static final FloatParser FLOAT_PARSER = new FloatParser() {
									    	       public float parseFloat(String value) {
										        	         return Float.parseFloat(value);
													  	       }
														        	     };
																     #endif

// FIXME: Need to re-implement with curretn Lucene with parser.
- (NSDictionary *) ints: (LCIndexReader *) reader field: (NSString *) field
{
	id ret = [self lookup: reader field: field type: LCSortField_INT];
	if (ret == nil) {
		NSMutableDictionary *retDic = [[NSMutableDictionary alloc] init];
		if ([reader maximalDocument] > 0) {
			id <LCTermDocuments> termDocs = [reader termDocuments];
			LCTerm *t = [[LCTerm alloc] initWithField: field text: @""];
			LCTermEnumerator *termEnum = [reader termEnumeratorWithTerm: t];
			if ([termEnum term] == nil)
			{
				NSLog(@"No Terms in field %@", field);
				return nil;
			}
			do {
				LCTerm *term = [termEnum term];
				if ([[term field] isEqualToString: field] == NO) break;
				int termval = [[term text] intValue];
				[termDocs seekTermEnumerator: termEnum];
				while ([termDocs hasNextDocument]) {
					[retDic setObject: [NSNumber numberWithInt: termval]
							   forKey: [NSNumber numberWithInt: [termDocs document]]];
				}
			} while ([termEnum hasNextTerm]);
			[termDocs close];
			[termEnum close];
		}
		[self store: reader field: field type: LCSortField_INT custom: retDic];
		return retDic;
	}
	return ret;
}

// FIXME: Need to re-implement with current Lucene and parser
- (NSDictionary *) floats: (LCIndexReader *) reader field: (NSString *) field
{
	id ret = [self lookup: reader field: field type: LCSortField_FLOAT];
	if (ret == nil) {
		NSMutableDictionary *retDic = [[NSMutableDictionary alloc] init];
		if ([reader maximalDocument] > 0) {
			id <LCTermDocuments> termDocs = [reader termDocuments];
			LCTerm *t = [[LCTerm alloc] initWithField: field text: @""];
			LCTermEnumerator *termEnum = [reader termEnumeratorWithTerm: t];
			if ([termEnum term] == nil)
			{
				NSLog(@"No Terms in field %@", field);
				return nil;
			}
			do {
				LCTerm *term = [termEnum term];
				if ([[term field] isEqualToString: field] == NO) break;
				float termval = [[term text] floatValue];
				[termDocs seekTermEnumerator: termEnum];
				while ([termDocs hasNextDocument]) {
					[retDic setObject: [NSNumber numberWithFloat: termval]
							   forKey: [NSNumber numberWithInt: [termDocs document]]];
				}
			} while ([termEnum hasNextTerm]);
			[termDocs close];
			[termEnum close];
		}
		[self store: reader field: field type: LCSortField_FLOAT custom: retDic];
		return retDic;
	}
	return ret;
}

- (NSDictionary *) strings: (LCIndexReader *) reader field: (NSString *) field
{
	id ret = [self lookup: reader field: field type: LCSortField_STRING];
	if (ret == nil) {
		NSMutableDictionary *retDic = [[NSMutableDictionary alloc] init];
		if ([reader maximalDocument] > 0) {
			id <LCTermDocuments> termDocs = [reader termDocuments];
			LCTerm *t = [[LCTerm alloc] initWithField: field text: @""];
			LCTermEnumerator *termEnum = [reader termEnumeratorWithTerm: t];
			if ([termEnum term] == nil)
			{
				NSLog(@"No Terms in field %@", field);
				return nil;
			}
			do {
				LCTerm *term = [termEnum term];
				if ([[term field] isEqualToString: field] == NO) break;
				NSString *termval = [[term text] copy];
				[termDocs seekTermEnumerator: termEnum];
				while ([termDocs hasNextDocument]) {
					[retDic setObject: AUTORELEASE(termval)
							   forKey: [NSNumber numberWithInt: [termDocs document]]];
				}
			} while ([termEnum hasNextTerm]);
			[termDocs close];
			[termEnum close];
		}
		[self store: reader field: field type: LCSortField_STRING custom: retDic];
		return retDic;
	}
	return ret;
}

- (LCStringIndex *) stringIndex: (LCIndexReader *) reader
						  field: (NSString *) field
{
	id ret = [self lookup: reader field: field type: LCFieldCache_STRING_INDEX];
	if (ret == nil) {
		NSMutableDictionary *retDic = [[NSMutableDictionary alloc] init];
		NSMutableArray *mterms = [[NSMutableArray alloc] init];
#if 0
		final int[] retArray = new int[reader.maxDoc()];
		String[] mterms = new String[reader.maxDoc()+1];
#endif
		if ([reader maximalDocument] > 0) {
			id <LCTermDocuments> termDocs = [reader termDocuments];
			LCTerm *tm = [[LCTerm alloc] initWithField: field text: @""];
			LCTermEnumerator *termEnum = [reader termEnumeratorWithTerm: tm];
			RELEASE(tm);
			int t = 0;  // current term number
			
			// an entry for documents that have no terms in this field
			// should a document with no terms be at top or bottom?
			// this puts them at the top - if it is changed, FieldDocSortedHitQueue
			// needs to change as well.
			/* LuceneKit: insert a non-NSString object */
			//[mterms addObject: AUTORELEASE([[NSObject alloc] init])];
			[mterms addObject: [NSNull null]];

			
			if ([termEnum term] == nil) {
				NSLog(@"No terms in field %@", field);
			}
			do {
				LCTerm *term = [termEnum term];
				if ([[term field] isEqualToString: field] == NO) break;
				
				// store term text
				// we expect that there is at most one term per document
				//    if (t >= mterms.length) throw new RuntimeException ("there are more terms than documents in field \"" + field + "\"");
				[mterms addObject: AUTORELEASE([term text])];
				
				[termDocs seekTermEnumerator: termEnum];
				while ([termDocs hasNextDocument]) {
					[retDic setObject: [NSNumber numberWithInt: t]
							   forKey: [NSNumber numberWithInt: [termDocs document]]];
				}
				
				t++;
			} while ([termEnum hasNextTerm]);
			[termDocs close];
			[termEnum close];
			
			if (t == 0) {
				// if there are no terms, make the term array
				// have a single null entry
				/* LuceneKit: This is not going to happend */
				[mterms addObject: [NSNull null]];
			} else if (t < [reader maximalDocument]+1) {
				// if there are less terms than documents,
				// trim off the dead array space
				/* LuceneKit: not necessary
				String[] terms = new String[t];
				System.arraycopy (mterms, 0, terms, 0, t);
				mterms = terms;
				*/
			}
		}
		LCStringIndex *value = [[LCStringIndex alloc] initWithOrder: retDic
															 lookup: mterms];
		[self store: reader field: field type: LCFieldCache_STRING_INDEX
			 custom: value];
		return AUTORELEASE(value);
	}
	return ret;
}

/** The pattern used to detect integer values in a field */
/** removed for java 1.3 compatibility
protected static final Pattern pIntegers = Pattern.compile ("[0-9\\-]+");
**/

/** The pattern used to detect float values in a field */
/**
* removed for java 1.3 compatibility
 * protected static final Object pFloats = Pattern.compile ("[0-9+\\-\\.eEfFdD]+");
 */

- (id) objects: (LCIndexReader *) reader field: (NSString *) field
{
	id ret = [self lookup: reader field: field type: LCSortField_AUTO];
	if (ret == nil) {
		LCTerm *t = [[LCTerm alloc] initWithField: field text: @""];
		LCTermEnumerator *enumerator = [reader termEnumeratorWithTerm: t];
		LCTerm *term = [enumerator term];
		if (term == nil) {
			NSLog(@"No terms in field %@ - cannot determin sort type", field);
			return nil;
		}
		if ([[term field] isEqualToString: field]) {
			NSString *termtext = [[term text] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
			
			/**
			* Java 1.4 level code:
			 
			 if (pIntegers.matcher(termtext).matches())
			 return IntegerSortedHitQueue.comparator (reader, enumerator, field);
			 
			 else if (pFloats.matcher(termtext).matches())
			 return FloatSortedHitQueue.comparator (reader, enumerator, field);
			 */
			
			// Java 1.3 level code:
			/* May not be accurate */
			int test_int = [termtext intValue];
			/* FIXME */
			if (test_int != 0)
			{
				ret = [self ints: reader field: field];
			}
			else 
			{
				float test_float = [termtext floatValue];
				/* FIXME */
				if (test_float != 0.0)
				{
					ret = [self floats: reader field: field];
				}
				else
				{
					ret = [self stringIndex: reader field: field];
				}
			}
			if (ret != nil) {
				[self store: reader field: field type: LCSortField_AUTO custom: ret];
			}
		} else {
			NSLog(@"field \"%@\" does not apper to be indexed", field);
			return nil;
		}
		[enumerator close];
	}
	return ret;
}

// inherit javadocs
- (NSDictionary *) custom: (LCIndexReader *) reader field: (NSString *) field
		   sortComparator: (LCSortComparator *) comparator
{
	id ret = [self lookup: reader field: field comparer: comparator];
	if (ret == nil) {
		NSMutableDictionary *retDic = [[NSMutableDictionary alloc] init];
		if ([reader maximalDocument] > 0) {
			id <LCTermDocuments> termDocs = [reader termDocuments];
			LCTerm *t = [[LCTerm alloc] initWithField: field text: @""];
			LCTermEnumerator *termEnum = [reader termEnumeratorWithTerm: t];
			if ([termEnum term] == nil) {
				NSLog(@"No terms in field %@", field);
				return nil;
			}
			do {
				LCTerm *term = [termEnum term];
				if ([[term field] isEqualToString: field] == NO) break;
				id termval = [comparator comparable: [term text]];
				[termDocs seekTermEnumerator: termEnum];
				while ([termDocs hasNextDocument]) {
					[retDic setObject: termval 
							   forKey: [NSNumber numberWithInt: [termDocs document]]];
				}
			} while ([termEnum hasNextTerm]);
			[termDocs close];
			[termEnum close];
		}
		[self store: reader field: field type: LCSortField_CUSTOM custom: retDic];
		return retDic;
	}
	return ret;
}

@end
