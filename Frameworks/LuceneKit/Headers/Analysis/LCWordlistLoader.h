#ifndef __LUCENE_ANALYSIS_WORDLIST_LOADER__
#define __LUCENE_ANALYSIS_WORDLIST_LOADER__

#include <Foundation/Foundation.h>

@interface LCWordlistLoader: NSObject

+ (NSSet *) getWordSet: (NSString *) absolutePath;
+ (NSDictionary *) makeWordTable: (NSSet *) wordSet;

@end
#endif /* __LUCENE_ANALYSIS_WORDLIST_LOADER__ */
