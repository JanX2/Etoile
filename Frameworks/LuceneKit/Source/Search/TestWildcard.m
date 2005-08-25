#include <LuceneKit/LuceneKit.h>
#include <UnitKit/UnitKit.h>

@interface TestWildcardQuery: NSObject <UKTest>
@end

@implementation TestWildcardQuery

- (void) assertMatches: (LCIndexSearcher *) searcher query: (LCQuery *) q expected: (int) expectedMatches
{
	LCHits *result = [searcher search: q];
	UKIntsEqual(expectedMatches, [result count]);
}

- (void) testEquals
{
	LCTerm *t = [[LCTerm alloc] initWithField: @"field" text: @"b*a"];
	LCWildcardQuery *wq1 = [[LCWildcardQuery alloc] initWithTerm: t];
	t = [[LCTerm alloc] initWithField: @"field" text: @"b*a"];
	LCWildcardQuery *wq2 = [[LCWildcardQuery alloc] initWithTerm: t];
	t = [[LCTerm alloc] initWithField: @"field" text: @"b*a"];
	LCWildcardQuery *wq3 = [[LCWildcardQuery alloc] initWithTerm: t];

	UKObjectsEqual(wq1, wq2);
	UKObjectsEqual(wq2, wq1);

	UKObjectsEqual(wq2, wq3);
	UKObjectsEqual(wq1, wq3);
	
	t = [[LCTerm alloc] initWithField: @"field" text: @"b*a"];
	LCFuzzyQuery *fq = [[LCFuzzyQuery alloc] initWithTerm: t];
	UKFalse([fq isEqual: wq1]);
	UKFalse([wq1 isEqual: fq]);
}

- (void) testWildcard
{
	LCRAMDirectory *indexStore = [[LCRAMDirectory alloc] init];
	LCIndexWriter *writer = [[LCIndexWriter alloc] initWithDirectory: indexStore
															analyzer: [[LCSimpleAnalyzer alloc] init]
															  create: YES];
	int i;
	NSArray *strings = [[NSArray alloc] initWithObjects: @"metal", @"metals", nil];
	for (i = 0; i < [strings count]; i++)
	{
		LCField *field = [[LCField alloc] initWithName: @"body"
												string: [strings objectAtIndex: i]
												 store: LCStore_YES
												 index: LCIndex_Tokenized];
		LCDocument *doc = [[LCDocument alloc] init];
		[doc addField: field];
		[writer addDocument: doc];
	}
	[writer optimize];
	[writer close];
	
	LCIndexSearcher *searcher = [[LCIndexSearcher alloc] initWithDirectory: indexStore];
	LCTerm *t = [[LCTerm alloc] initWithField: @"body" text: @"metal"];
	LCQuery *query1 = [[LCTermQuery alloc] initWithTerm: t];
	t = [[LCTerm alloc] initWithField: @"body"  text: @"metal*"];
	LCQuery *query2 = [[LCWildcardQuery alloc] initWithTerm: t];
	t = [[LCTerm alloc] initWithField: @"body"  text: @"m*tal"];
	LCQuery *query3 = [[LCWildcardQuery alloc] initWithTerm: t];
	t = [[LCTerm alloc] initWithField: @"body"  text: @"m*tal*"];
	LCQuery *query4 = [[LCWildcardQuery alloc] initWithTerm: t];
	t = [[LCTerm alloc] initWithField: @"body"  text: @"m*tals"];
	LCQuery *query5 = [[LCWildcardQuery alloc] initWithTerm: t];
	
	LCBooleanQuery *query6 = [[LCBooleanQuery alloc] init];
	[query6 addQuery: query5 occur: LCOccur_SHOULD];

	LCBooleanQuery *query7 = [[LCBooleanQuery alloc] init];
	[query7 addQuery: query3 occur: LCOccur_SHOULD];
	[query7 addQuery: query5 occur: LCOccur_SHOULD];

	t = [[LCTerm alloc] initWithField: @"body"  text: @"M*tal*"];
	LCQuery *query8 = [[LCWildcardQuery alloc] initWithTerm: t];
	
	[self assertMatches: searcher query: query1 expected: 1];
	[self assertMatches: searcher query: query2 expected: 2];
	[self assertMatches: searcher query: query3 expected: 1];
	[self assertMatches: searcher query: query4 expected: 2];
	[self assertMatches: searcher query: query5 expected: 1];
	[self assertMatches: searcher query: query6 expected: 1];
	[self assertMatches: searcher query: query7 expected: 2];
	[self assertMatches: searcher query: query8 expected: 0];
	
	t = [[LCTerm alloc] initWithField: @"body"  text: @"*tall"];
	LCQuery *query9 = [[LCWildcardQuery alloc] initWithTerm: t];

	t = [[LCTerm alloc] initWithField: @"body"  text: @"*tal"];
	LCQuery *query10 = [[LCWildcardQuery alloc] initWithTerm: t];

	t = [[LCTerm alloc] initWithField: @"body"  text: @"*tal*"];
	LCQuery *query11 = [[LCWildcardQuery alloc] initWithTerm: t];
	
	[self assertMatches: searcher query: query9 expected: 0];
	[self assertMatches: searcher query: query10 expected: 1];
	[self assertMatches: searcher query: query11 expected: 2];
}
#if 0

  /**
   * Tests Wildcard queries with a question mark.
   *
   * @throws IOException if an error occurs
   */
  public void testQuestionmark()
      throws IOException {
    RAMDirectory indexStore = getIndexStore("body", new String[]
    {"metal", "metals", "mXtals", "mXtXls"});
    IndexSearcher searcher = new IndexSearcher(indexStore);
    Query query1 = new WildcardQuery(new Term("body", "m?tal"));
    Query query2 = new WildcardQuery(new Term("body", "metal?"));
    Query query3 = new WildcardQuery(new Term("body", "metals?"));
    Query query4 = new WildcardQuery(new Term("body", "m?t?ls"));
    Query query5 = new WildcardQuery(new Term("body", "M?t?ls"));

    assertMatches(searcher, query1, 1);
    assertMatches(searcher, query2, 2);
    assertMatches(searcher, query3, 1);
    assertMatches(searcher, query4, 3);
    assertMatches(searcher, query5, 0);
  }

#endif

@end
