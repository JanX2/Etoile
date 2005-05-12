include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = LuceneKit_Search

LuceneKit_Search_OBJC_FILES = \
	LCBooleanClause.m \
	LCBooleanQuery.m \
	LCBooleanScorer.m \
	LCTopDocs.m \
	LCTopFieldDocs.m \
	LCScoreDoc.m \
	LCFieldDoc.m \
	LCFilter.m \
	LCFieldCache.m \
	LCFieldCacheImpl.m \
	LCFieldSortedHitQueue.m \
	LCHit.m \
	LCHits.m \
	LCHitCollector.m \
	LCHitQueue.m \
	LCHitIterator.m \
	LCExplanation.m \
	LCReqExclScorer.m \
	LCReqOptSumScorer.m \
	LCConjunctionScorer.m \
	LCDisjunctionSumScorer.m \
	LCNonMatchingScorer.m \
	LCQuery.m \
	LCQueryFilter.m \
	LCQueryTermVector.m \
	LCIndexSearcher.m \
	LCSearcher.m \
	LCScorer.m \
	LCSortField.m \
	LCScoreDocComparator.m \
	LCSort.m \
	LCSortComparator.m \
	LCSimilarity.m  \
	LCDefaultSimilarity.m \
	LCSimilarityDelegator.m \
	LCTermQuery.m \
	LCTermScorer.m

ifeq ($(test), yes)
LuceneKit_Search_OBJC_FILES += \
	TestSetNorm.m \
	TestSimilarity.m
endif

LuceneKit_Search_INCLUDE_DIRS += -I../../Headers -I../

-include ../../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include ../../GNUmakefile.postamble
