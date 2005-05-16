#ifndef __LUCENE_ANALYSIS_STOP_FILTER__
#define __LUCENE_ANALYSIS_STOP_FILTER__

#include <LuceneKit/Analysis/LCTokenFilter.h>

@interface LCStopFilter: LCTokenFilter
{
	NSMutableSet *stopWords;
}

+ (NSSet *) makeStopSet: (NSArray *) sw;

- (id) initWithTokenStream: (LCTokenStream *) stream
          stopWordsInArray: (NSArray *) sw;
- (id) initWithTokenStream: (LCTokenStream *) stream
     stopWordsInDictionary: (NSDictionary *) st;
- (id) initWithTokenStream: (LCTokenStream *) stream 
            stopWordsInSet: (NSSet *) sw;

@end

#endif /* __LUCENE_ANALYSIS_STOP_FILTER__ */
