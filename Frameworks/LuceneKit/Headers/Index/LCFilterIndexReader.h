#ifndef __LUCENE_INDEX_FILTER_INDEX_READER__
#define __LUCENE_INDEX_FILTER_INDEX_READER__

#include <LuceneKit/Index/LCIndexReader.h>
#include <LuceneKit/Index/LCTermDocs.h>
#include <LuceneKit/Index/LCTermPositions.h>
#include <LuceneKit/Index/LCTermEnum.h>

@interface LCFilterTermDocs: NSObject <LCTermDocs>
{
	id <LCTermDocs> input;
}

- (id) initWithTermDocs: (id <LCTermDocs>) docs;

@end

@interface LCFilterTermPositions: LCFilterTermDocs <LCTermPositions>
- (id) initWithTermPositions: (id <LCTermPositions>) po;
@end

@interface LCFilterTermEnum: LCTermEnum
{
	LCTermEnum* input;
}

- (id) initWithTermEnum: (LCTermEnum *) termEnum;
@end

@interface LCFilterIndexReader: LCIndexReader
{
	LCIndexReader *input;
}

- (id) initWithIndexReader: (LCIndexReader *) reader;

@end

#endif /* __LUCENE_INDEX_FILTER_INDEX_READER__ */
