#include "LCFieldCache.h"
#include "LCFieldCacheImpl.h"
#include "GNUstep.h"

/**
* Expert: Maintains caches of term values.
 *
 * <p>Created: May 19, 2004 11:13:14 AM
 *
 * @author  Tim Jones (Nacimiento Software)
 * @since   lucene 1.4
 * @version $Id$
 */
@implementation LCStringIndex

- (id) initWithOrder: (NSDictionary *) values lookup: (NSArray *) l
{
	self = [super init];
	ASSIGN(order, values);
	ASSIGN(lookup, l);
	return self;
}

- (NSDictionary *) order
{
	return order;
}

- (NSArray *) lookup
{
	return lookup;
}

- (void) dealloc
{
	DESTROY(order);
	DESTROY(lookup);
	[super dealloc];
}

@end

static LCFieldCache *defaultImpl = nil;

@implementation LCFieldCache
+ (LCFieldCache *) defaultCache
{
	if (defaultImpl == nil)
	{
		ASSIGN(defaultImpl, AUTORELEASE([[LCFieldCacheImpl alloc] init]));
	}
	return defaultImpl;
}

#if 0 // FIXME
   /** Interface to parse ints from document fields.
    	    * @see #getInts(IndexReader, String, IntParser)
	     	    */
		     	   public interface IntParser {
			    	     /** Return an integer representation of this field's value. */
				      	     public int parseInt(String string);
					      	   }
						    	 
							  	 
								  	   /** Interface to parse floats from document fields.
									    	    * @see #getFloats(IndexReader, String, FloatParser)
										     	    */
											     	   public interface FloatParser {
												    	     /* Return an float representation of this field's value. */
													      	     public float parseFloat(String string);
														      	   }

#endif

- (NSDictionary *) ints: (LCIndexReader *) reader field: (NSString *) field
{
	return nil;
}

#if 0 // FIXME
   /** Checks the internal cache for an appropriate entry, and if none is found,
    	    * reads the terms in <code>field</code> as integers and returns an array of
	     	    * size <code>reader.maxDoc()</code> of the value each document has in the
		     	    * given field.
			     	    * @param reader  Used to get field values.
				     	    * @param field   Which field contains the integers.
					     	    * @param parser  Computes integer for string values.
						     	    * @return The values in the given field for each document.
							     	    * @throws IOException  If any error occurs.
								     	    */
									     	   public int[] getInts (IndexReader reader, String field, IntParser parser)
										    	   throws IOException;
											    	 
												 #endif

- (NSDictionary *) floats: (LCIndexReader *) reader field: (NSString *) field
{
	return nil;
}

#if 0
 
  	   /** Checks the internal cache for an appropriate entry, and if
	    	    * none is found, reads the terms in <code>field</code> as floats and returns an array
		     	    * of size <code>reader.maxDoc()</code> of the value each document
			     	    * has in the given field.
				     	    * @param reader  Used to get field values.
					     	    * @param field   Which field contains the floats.
						     	    * @param parser  Computes float for string values.
							     	    * @return The values in the given field for each document.
								     	    * @throws IOException  If any error occurs.
									     	    */
										     	   public float[] getFloats (IndexReader reader, String field,
											    	                             FloatParser parser) throws IOException;
															     #endif

- (NSDictionary *) strings: (LCIndexReader *) reader field: (NSString *) field
{
	return nil;
}

- (LCStringIndex *) stringIndex: (LCIndexReader *) reader field: (NSString *) field
{
	return nil;
}

- (id) objects: (LCIndexReader *) reader field: (NSString *) field
{
	return nil;
}

- (NSDictionary *) custom: (LCIndexReader *) reader field: (NSString *) field
		   sortComparator: (LCSortComparator *) comparator
{
	return nil;
}

@end
