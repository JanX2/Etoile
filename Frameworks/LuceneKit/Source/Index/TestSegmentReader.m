#include "LCSegmentInfo.h"
#include "LCField.h"
#include "LCTerm.h"
#include "LCTermEnum.h"
#include "LCSegmentTermEnum.h"
#include "GNUstep.h"
#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include "LCSegmentReader.h"
#include "LCDocument.h"
#include "LCRAMDirectory.h"
#include "TestDocHelper.h"

@interface TestSegmentReader: NSObject <UKTest>
{
	LCRAMDirectory *dir;
	LCDocument *testDoc;
	LCSegmentReader *reader;
}
@end

@implementation TestSegmentReader

- (id) init
{
	self = [super init];
	dir = [[LCRAMDirectory alloc] init];
	testDoc = [[LCDocument alloc] init];
	[TestDocHelper setupDoc: testDoc];
	[TestDocHelper writeDirectory: dir doc: testDoc];
	//TODO: Setup the reader w/ multiple documents
	LCSegmentInfo *info = [[LCSegmentInfo alloc] initWithName: @"test" numberOfDocuments: 1 directory: dir];
	reader = RETAIN([LCSegmentReader segmentReaderWithInfo: info]);
	return self;
}

- (void) testBasic
{
	UKNotNil(dir);
	UKNotNil(reader);
	UKTrue([[TestDocHelper nameValues] count] > 0);
	UKTrue([TestDocHelper numFields: testDoc] == 6);
}

- (void) testDocument
{
	UKIntsEqual([reader numberOfDocuments], 1);
	UKTrue([reader maximalDocument] >= 1);
	LCDocument *result = [reader document: 0];
	UKNotNil(result);
	//There are 2 unstored fields on the document that are not preserved across writing
	UKIntsEqual([TestDocHelper numFields: result], [TestDocHelper numFields: testDoc]-2);
	
	NSEnumerator *fields = [result fieldEnumerator];
	LCField *field;
	while ((field = [fields nextObject]))
	{
		UKNotNil(field);
		UKNotNil([[TestDocHelper nameValues] objectForKey: [field name]]);
	}
}

- (void) testDelete
{
	LCDocument *docToDelete = [[LCDocument alloc] init];
	[TestDocHelper setupDoc: docToDelete];
	[TestDocHelper writeDirectory: dir segment: @"seg-to-delete" doc: docToDelete];
	LCSegmentInfo *info = [[LCSegmentInfo alloc] initWithName: @"seg-to-delete" numberOfDocuments: 1 directory: dir];
	
	LCSegmentReader *deleteReader = [LCSegmentReader segmentReaderWithInfo: info];
	UKNotNil(deleteReader);
	UKIntsEqual([deleteReader numberOfDocuments], 1);
	[deleteReader deleteDocument: 0];
	UKTrue([deleteReader isDeleted: 0]);
	UKTrue([deleteReader hasDeletions]);
	UKIntsEqual([deleteReader numberOfDocuments], 0);
#if 0
	try {
        Document test = deleteReader.document(0);
        assertTrue(false);
	} catch (IllegalArgumentException e) {
        assertTrue(true);
	}
} catch (IOException e) {
	e.printStackTrace();
	assertTrue(false);
}
#endif
  }    

- (void) testGetFieldNameVariations
{
	NSArray *result = [reader fieldNames: LCFieldOption_ALL];
	UKNotNil(result);
	UKIntsEqual([result count], 6);
	NSEnumerator *e = [result objectEnumerator];
	NSString *s;
	while ((s = [e nextObject]))
	{
		UKNotNil([[TestDocHelper nameValues] objectForKey: s]);
		//  assertTrue(DocHelper.nameValues.containsKey(s) == true || s.equals(""));
	}
	
	result = [reader fieldNames: LCFieldOption_INDEXED];
	UKNotNil(result);
	UKIntsEqual([result count], 5);
	e = [result objectEnumerator];
	while ((s = [e nextObject]))
	{
		UKNotNil([[TestDocHelper nameValues] objectForKey: s]);
    }
    
	result = [reader fieldNames: LCFieldOption_UNINDEXED];
	UKNotNil(result);
	UKIntsEqual([result count], 1);
	
    //Get all indexed fields that are storing term vectors
	result = [reader fieldNames: LCFieldOption_INDEXED_WITH_TERMVECTOR];
	UKNotNil(result);
	UKIntsEqual([result count], 2);
	
	result = [reader fieldNames: LCFieldOption_INDEXED_NO_TERMVECTOR];
	UKNotNil(result);
	UKIntsEqual([result count], 3);
	
} 

- (void) testTerms
{
	
	LCSegmentTermEnumerator *terms = (LCSegmentTermEnumerator *)[reader termEnumerator];
	UKNotNil(terms);
	while([terms hasNextTerm])
	{
		LCTerm *term = [terms term];
		UKNotNil(term);
		NSString *fieldValue = [[TestDocHelper nameValues] objectForKey: [term field]];
		UKTrue([fieldValue rangeOfString: [term text]].location != NSNotFound);
		//     assertTrue(fieldValue.indexOf(term.text()) != -1);
	}
	
	id <LCTermDocuments> termDocs = [reader termDocuments];
	UKNotNil(termDocs);
	LCTerm *t = [[LCTerm alloc] initWithField: [TestDocHelper TEXT_FIELD_1_KEY] text: @"field"];
	[termDocs seekTerm: t];
	UKTrue([termDocs hasNextDocument]);
	
	id <LCTermPositions> positions = [reader termPositions];
	[positions seekTerm: t];
	UKNotNil(positions);
	UKIntsEqual([positions document], 0);
	UKTrue([positions nextPosition] >= 0);
}

#if 0
public void testNorms() {
    //TODO: Not sure how these work/should be tested
	/*
	 try {
		 byte [] norms = reader.norms(DocHelper.TEXT_FIELD_1_KEY);
		 System.out.println("Norms: " + norms);
		 assertTrue(norms != null);
	 } catch (IOException e) {
		 e.printStackTrace();
		 assertTrue(false);
	 }
	 */
	
}
#endif

- (void) testTermVectors
{
	id <LCTermFrequencyVector> result = [reader termFrequencyVector: 0 field: [TestDocHelper TEXT_FIELD_2_KEY]];
	UKNotNil(result);
	NSArray *terms = [result allTerms];
	NSArray *freqs = [result allTermFrequencies];
	UKNotNil(terms);
	UKIntsEqual([terms count], 3);
	UKNotNil(freqs);
	UKIntsEqual([freqs count], 3);
	int i;
	for (i = 0; i < [terms count]; i++)
	{
		NSString *term = [terms objectAtIndex: i];
		long freq = [[freqs objectAtIndex: i] longValue];
		UKTrue([[TestDocHelper FIELD_2_TEXT] rangeOfString: term].location != NSNotFound);
		UKTrue(freq > 0);
	}
	NSArray *results = [reader termFrequencyVectors: 0];
	UKNotNil(result);
	UKIntsEqual([results count], 2);
}

@end
