#ifndef __LUCENE_ANALYSIS_PORTERSTEM_FILTER__
#define __LUCENE_ANALYSIS_PORTERSTEM_FILTER__

#include <LuceneKit/Analysis/LCTokenFilter.h>
#include <LuceneKit/Analysis/PorterStemmer.h>

@interface LCPorterStemFilter: LCTokenFilter
{
	struct stemmer *st;
}

@end

#endif /* __LUCENE_ANALYSIS_PORTERSTEM_FILTER__ */
