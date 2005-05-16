#ifndef __LUCENE_ANALYSIS_SIMPLE_ANALYZER__
#define __LUCENE_ANALYSIS_SIMPLE_ANALYZER__

#include <LuceneKit/Analysis/LCAnalyzer.h>

#ifdef HAVE_UKTEST
#include <UnitKit/UnitKit.h>
@interface LCSimpleAnalyzer: LCAnalyzer <UKTest>
#else
@interface LCSimpleAnalyzer: LCAnalyzer
#endif
@end

#endif /* __LUCENE_ANALYSIS_SIMPLE_ANALYZER__ */
