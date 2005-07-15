#include <LuceneKit/LuceneKit.h>
#include <UnitKit/UnitKit.h>
#include <LuceneKit/GNUstep/GNUstep.h>

static NSString *FIELD = @"field";

@interface TestFuzzyQuery: NSObject <UKTest>
@end

@implementation TestFuzzyQuery

- (void) addDoc: (NSString *) text : (LCIndexWriter *) writer
{
	LCDocument *doc = [[LCDocument alloc] init];
	LCField *field = [[LCField alloc] initWithName: FIELD string: text store: LCStore_YES
											 index: LCIndex_Tokenized];
	[doc addField: field];
	[writer addDocument: doc];
	DESTROY(field);
	DESTROY(doc);
}

- (void) testFuzziness
{
	NSLog(@"testFuzziness");
	LCRAMDirectory *directory = [[LCRAMDirectory alloc] init];
	LCIndexWriter *writer = [[LCIndexWriter alloc] initWithDirectory: directory analyzer: [[LCWhitespaceAnalyzer alloc] init]
															  create: YES];
	[self addDoc: @"aaaaa" : writer];
	[self addDoc: @"aaaab" : writer];
	[self addDoc: @"aaabb" : writer];
	[self addDoc: @"aabbb" : writer];
	[self addDoc: @"abbbb" : writer];
	[self addDoc: @"bbbbb" : writer];
	[self addDoc: @"ddddd" : writer];
	[writer optimize];
	[writer close];
	
	LCIndexSearcher *searcher = [[LCIndexSearcher alloc] initWithDirectory: directory];

	LCTerm *t = [[LCTerm alloc] initWithField: FIELD text: @"aaaaa"];
	LCFuzzyQuery *query = [[LCFuzzyQuery alloc] initWithTerm: t
										   minimumSimilarity: [LCFuzzyQuery defaultMinSimilarity]
												prefixLength: 0];
	LCHits *hits = [searcher search: query];
	UKIntsEqual(3, [hits count]);
#if 0
    FuzzyQuery query = new FuzzyQuery(new Term(FIELD, "aaaaa"), FuzzyQuery.defaultMinSimilarity, 0);   
    Hits hits = searcher.search(query);
    assertEquals(3, hits.length());
    
    // same with prefix
    query = new FuzzyQuery(new Term("field", "aaaaa"), FuzzyQuery.defaultMinSimilarity, 1);   
    hits = searcher.search(query);
    assertEquals(3, hits.length());
    query = new FuzzyQuery(new Term("field", "aaaaa"), FuzzyQuery.defaultMinSimilarity, 2);   
    hits = searcher.search(query);
    assertEquals(3, hits.length());
    query = new FuzzyQuery(new Term("field", "aaaaa"), FuzzyQuery.defaultMinSimilarity, 3);   
    hits = searcher.search(query);
    assertEquals(3, hits.length());
    query = new FuzzyQuery(new Term("field", "aaaaa"), FuzzyQuery.defaultMinSimilarity, 4);   
    hits = searcher.search(query);
    assertEquals(2, hits.length());
    query = new FuzzyQuery(new Term("field", "aaaaa"), FuzzyQuery.defaultMinSimilarity, 5);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    query = new FuzzyQuery(new Term("field", "aaaaa"), FuzzyQuery.defaultMinSimilarity, 6);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());

    // not similar enough:
    query = new FuzzyQuery(new Term("field", "xxxxx"), FuzzyQuery.defaultMinSimilarity, 0);  	
    hits = searcher.search(query);
    assertEquals(0, hits.length());
    query = new FuzzyQuery(new Term("field", "aaccc"), FuzzyQuery.defaultMinSimilarity, 0);   // edit distance to "aaaaa" = 3
    hits = searcher.search(query);
    assertEquals(0, hits.length());

    // query identical to a word in the index:
    query = new FuzzyQuery(new Term("field", "aaaaa"), FuzzyQuery.defaultMinSimilarity, 0);   
    hits = searcher.search(query);
    assertEquals(3, hits.length());
    assertEquals(hits.doc(0).get("field"), ("aaaaa"));
    // default allows for up to two edits:
    assertEquals(hits.doc(1).get("field"), ("aaaab"));
    assertEquals(hits.doc(2).get("field"), ("aaabb"));

    // query similar to a word in the index:
    query = new FuzzyQuery(new Term("field", "aaaac"), FuzzyQuery.defaultMinSimilarity, 0);   
    hits = searcher.search(query);
    assertEquals(3, hits.length());
    assertEquals(hits.doc(0).get("field"), ("aaaaa"));
    assertEquals(hits.doc(1).get("field"), ("aaaab"));
    assertEquals(hits.doc(2).get("field"), ("aaabb"));
    
    // now with prefix
    query = new FuzzyQuery(new Term("field", "aaaac"), FuzzyQuery.defaultMinSimilarity, 1);   
    hits = searcher.search(query);
    assertEquals(3, hits.length());
    assertEquals(hits.doc(0).get("field"), ("aaaaa"));
    assertEquals(hits.doc(1).get("field"), ("aaaab"));
    assertEquals(hits.doc(2).get("field"), ("aaabb"));
    query = new FuzzyQuery(new Term("field", "aaaac"), FuzzyQuery.defaultMinSimilarity, 2);   
    hits = searcher.search(query);
    assertEquals(3, hits.length());
    assertEquals(hits.doc(0).get("field"), ("aaaaa"));
    assertEquals(hits.doc(1).get("field"), ("aaaab"));
    assertEquals(hits.doc(2).get("field"), ("aaabb"));
    query = new FuzzyQuery(new Term("field", "aaaac"), FuzzyQuery.defaultMinSimilarity, 3);   
    hits = searcher.search(query);
    assertEquals(3, hits.length());
    assertEquals(hits.doc(0).get("field"), ("aaaaa"));
    assertEquals(hits.doc(1).get("field"), ("aaaab"));
    assertEquals(hits.doc(2).get("field"), ("aaabb"));
    query = new FuzzyQuery(new Term("field", "aaaac"), FuzzyQuery.defaultMinSimilarity, 4);   
    hits = searcher.search(query);
    assertEquals(2, hits.length());
    assertEquals(hits.doc(0).get("field"), ("aaaaa"));
    assertEquals(hits.doc(1).get("field"), ("aaaab"));
    query = new FuzzyQuery(new Term("field", "aaaac"), FuzzyQuery.defaultMinSimilarity, 5);   
    hits = searcher.search(query);
    assertEquals(0, hits.length());
    

    query = new FuzzyQuery(new Term("field", "ddddX"), FuzzyQuery.defaultMinSimilarity, 0);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    assertEquals(hits.doc(0).get("field"), ("ddddd"));
    
    // now with prefix
    query = new FuzzyQuery(new Term("field", "ddddX"), FuzzyQuery.defaultMinSimilarity, 1);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    assertEquals(hits.doc(0).get("field"), ("ddddd"));
    query = new FuzzyQuery(new Term("field", "ddddX"), FuzzyQuery.defaultMinSimilarity, 2);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    assertEquals(hits.doc(0).get("field"), ("ddddd"));
    query = new FuzzyQuery(new Term("field", "ddddX"), FuzzyQuery.defaultMinSimilarity, 3);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    assertEquals(hits.doc(0).get("field"), ("ddddd"));
    query = new FuzzyQuery(new Term("field", "ddddX"), FuzzyQuery.defaultMinSimilarity, 4);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    assertEquals(hits.doc(0).get("field"), ("ddddd"));
    query = new FuzzyQuery(new Term("field", "ddddX"), FuzzyQuery.defaultMinSimilarity, 5);   
    hits = searcher.search(query);
    assertEquals(0, hits.length());
    

    // different field = no match:
    query = new FuzzyQuery(new Term("anotherfield", "ddddX"), FuzzyQuery.defaultMinSimilarity, 0);   
    hits = searcher.search(query);
    assertEquals(0, hits.length());
#endif
	[searcher close];
	[directory close];
	NSLog(@"testFuzziness done");

}

#if 0
  public void testFuzzinessLong() throws Exception {
    RAMDirectory directory = new RAMDirectory();
    IndexWriter writer = new IndexWriter(directory, new WhitespaceAnalyzer(), true);
    addDoc("aaaaaaa", writer);
    addDoc("segment", writer);
    writer.optimize();
    writer.close();
    IndexSearcher searcher = new IndexSearcher(directory);

    FuzzyQuery query;
    // not similar enough:
    query = new FuzzyQuery(new Term("field", "xxxxx"), FuzzyQuery.defaultMinSimilarity, 0);   
    Hits hits = searcher.search(query);
    assertEquals(0, hits.length());
    // edit distance to "aaaaaaa" = 3, this matches because the string is longer than
    // in testDefaultFuzziness so a bigger difference is allowed:
    query = new FuzzyQuery(new Term("field", "aaaaccc"), FuzzyQuery.defaultMinSimilarity, 0);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    assertEquals(hits.doc(0).get("field"), ("aaaaaaa"));
    
    // now with prefix
    query = new FuzzyQuery(new Term("field", "aaaaccc"), FuzzyQuery.defaultMinSimilarity, 1);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    assertEquals(hits.doc(0).get("field"), ("aaaaaaa"));
    query = new FuzzyQuery(new Term("field", "aaaaccc"), FuzzyQuery.defaultMinSimilarity, 4);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    assertEquals(hits.doc(0).get("field"), ("aaaaaaa"));
    query = new FuzzyQuery(new Term("field", "aaaaccc"), FuzzyQuery.defaultMinSimilarity, 5);   
    hits = searcher.search(query);
    assertEquals(0, hits.length());

    // no match, more than half of the characters is wrong:
    query = new FuzzyQuery(new Term("field", "aaacccc"), FuzzyQuery.defaultMinSimilarity, 0);   
    hits = searcher.search(query);
    assertEquals(0, hits.length());
    
    // now with prefix
    query = new FuzzyQuery(new Term("field", "aaacccc"), FuzzyQuery.defaultMinSimilarity, 2);   
    hits = searcher.search(query);
    assertEquals(0, hits.length());

    // "student" and "stellent" are indeed similar to "segment" by default:
    query = new FuzzyQuery(new Term("field", "student"), FuzzyQuery.defaultMinSimilarity, 0);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    query = new FuzzyQuery(new Term("field", "stellent"), FuzzyQuery.defaultMinSimilarity, 0);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    
    // now with prefix
    query = new FuzzyQuery(new Term("field", "student"), FuzzyQuery.defaultMinSimilarity, 1);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    query = new FuzzyQuery(new Term("field", "stellent"), FuzzyQuery.defaultMinSimilarity, 1);   
    hits = searcher.search(query);
    assertEquals(1, hits.length());
    query = new FuzzyQuery(new Term("field", "student"), FuzzyQuery.defaultMinSimilarity, 2);   
    hits = searcher.search(query);
    assertEquals(0, hits.length());
    query = new FuzzyQuery(new Term("field", "stellent"), FuzzyQuery.defaultMinSimilarity, 2);   
    hits = searcher.search(query);
    assertEquals(0, hits.length());
    
    // "student" doesn't match anymore thanks to increased minimum similarity:
    query = new FuzzyQuery(new Term("field", "student"), 0.6f, 0);   
    hits = searcher.search(query);
    assertEquals(0, hits.length());

    try {
      query = new FuzzyQuery(new Term("field", "student"), 1.1f);
      fail("Expected IllegalArgumentException");
    } catch (IllegalArgumentException e) {
      // expecting exception
    }
    try {
      query = new FuzzyQuery(new Term("field", "student"), -0.1f);
      fail("Expected IllegalArgumentException");
    } catch (IllegalArgumentException e) {
      // expecting exception
    }

    searcher.close();
    directory.close();
  }
#endif

@end
