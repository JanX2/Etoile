#ifndef __LUCENE_ANALYSIS_PERFIELD_ANALYZER_WRAPPER__
#define __LUCENE_ANALYSIS_PERFIELD_ANALYZER_WRAPPER__

#include "LCAnalyzer.h"

@interface LCPerFieldAnalyzerWrapper: LCAnalyzer
{
  LCAnalyzer *defaultAnalyzer;
  NSMutableDictionary *analyzerMap;
}

- (id) initWithAnalyzer: (LCAnalyzer *) analyzer;
- (void) addAnalyzerWithField: (NSString *) name
                     analyzer: (LCAnalyzer *) analyzer;

@end
#endif /* __LUCENE_ANALYSIS_PERFIELD_ANALYZER_WRAPPER__ */
