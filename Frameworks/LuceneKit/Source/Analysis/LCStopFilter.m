#include "Analysis/LCStopFilter.h"
#include "GNUstep/GNUstep.h"

/**
* Removes stop words from a token stream.
 */

@implementation LCStopFilter
/**
* Builds a Set from an array of stop words,
 * appropriate for passing into the StopFilter constructor.
 * This permits this stopWords construction to be cached once when
 * an Analyzer is constructed.
 */
+ (NSSet *) makeStopSet: (NSArray *) sw // Array of String
{
	NSMutableSet *set = [[NSMutableSet alloc] initWithCapacity: [sw count]];
	int i, count = [sw count];
	for(i = 0; i < count; i++)
    {
		[set addObject: [sw objectAtIndex: i]];
    }
	return AUTORELEASE(set);
}

/**
* Constructs a filter which removes words from the input
 * TokenStream that are named in the array of words.
 */
- (id) initWithTokenStream: (LCTokenStream *) stream
          stopWordsInArray: (NSArray *) sw
{
	return [self initWithTokenStream: stream
					  stopWordsInSet: [LCStopFilter makeStopSet: sw]];
}

/**
* Constructs a filter which removes words from the input
 * TokenStream that are named in the Hashtable.
 *
 * @deprecated Use {@link #StopFilter(TokenStream, Set)} instead
 */
- (id) initWithTokenStream: (LCTokenStream *) stream
     stopWordsInDictionary: (NSDictionary *) st
{
	return [self initWithTokenStream: stream
					stopWordsInArray: [st allKeys]];
}

/**
* Constructs a filter which removes words from the input
 * TokenStream that are named in the Set.
 * It is crucial that an efficient Set implementation is used
 * for maximum performance.
 *
 * @see #makeStopSet(java.lang.String[])
 */
- (id) initWithTokenStream: (LCTokenStream *) stream
            stopWordsInSet: (NSSet *) sw
{
	self = [super initWithTokenStream: stream];
	stopWords = [[NSSet alloc] initWithSet: sw];
	return self;
}

- (void) dealloc
{
	DESTROY(stopWords);
	[super dealloc];
}

#if 0
/**
* Builds a Hashtable from an array of stop words,
 * appropriate for passing into the StopFilter constructor.
 * This permits this table construction to be cached once when
 * an Analyzer is constructed.
 *
 * @deprecated Use {@link #makeStopSet(String[])} instead.
 */
public static final Hashtable makeStopTable(String[] stopWords) {
    Hashtable stopTable = new Hashtable(stopWords.length);
    for (int i = 0; i < stopWords.length; i++)
		stopTable.put(stopWords[i], stopWords[i]);
    return stopTable;
}
#endif

/**
* Returns the next input Token whose termText() is not a stop word.
 */
- (LCToken *) next
{
	// return the first non-stop word found
	LCToken *t = nil;
	while((t = [input next]))
    {
		if (![stopWords containsObject: [t termText]])
			return t;
    }
	return nil;
}

@end
