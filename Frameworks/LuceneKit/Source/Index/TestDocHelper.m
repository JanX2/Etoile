#include "TestDocHelper.h"
#include "Document/LCField.h"
#include "Document/LCDocument.h"
#include "Analysis/LCWhitespaceAnalyzer.h"
#include "Search/LCSimilarity.h"
#include "Index/LCDocumentWriter.h"
#include "GNUstep/GNUstep.h"

static NSString *FIELD_1_TEXT;
static NSString *TEXT_FIELD_1_KEY;
static NSString *FIELD_2_TEXT;
static NSString *TEXT_FIELD_2_KEY;
static NSString *KEYWORD_TEXT;
static NSString *KEYWORD_FIELD_KEY;
static NSString *UNINDEXED_FIELD_TEXT;
static NSString *UNINDEXED_FIELD_KEY;
static NSString *UNSTORED_1_FIELD_TEXT;
static NSString *UNSTORED_2_FIELD_TEXT;
static NSString *UNSTORED_FIELD_1_KEY;
static NSString *UNSTORED_FIELD_2_KEY;

@implementation TestDocHelper
+ (NSString *) FIELD_1_TEXT
{
  return FIELD_1_TEXT;
}

+ (NSString *) TEXT_FIELD_1_KEY
{
  return TEXT_FIELD_1_KEY;
}

+ (NSString *) FIELD_2_TEXT
{
  return FIELD_2_TEXT;
}

+ (NSString *) TEXT_FIELD_2_KEY
{
  return TEXT_FIELD_2_KEY;
}

+ (NSString *) KEYWORD_TEXT 
{
  return KEYWORD_TEXT;
}

+ (NSString *) KEYWORD_FIELD_KEY
{
  return KEYWORD_FIELD_KEY;
}

+ (NSString *) UNINDEXED_FIELD_TEXT
{
  return UNINDEXED_FIELD_TEXT;
}

+ (NSString *) UNINDEXED_FIELD_KEY
{
  return UNINDEXED_FIELD_KEY;
}

+ (NSString *) UNSTORED_1_FIELD_TEXT
{
  return UNSTORED_1_FIELD_TEXT;
}

+ (NSString *) UNSTORED_2_FIELD_TEXT
{
  return UNSTORED_2_FIELD_TEXT;
}

+ (NSString *) UNSTORED_FIELD_1_KEY
{
  return UNSTORED_FIELD_1_KEY;
}

+ (NSString *) UNSTORED_FIELD_2_KEY
{
  return UNSTORED_FIELD_2_KEY;
}

+ (void) setupDoc: (LCDocument *) doc
{
  FIELD_1_TEXT = @"field one text";
  TEXT_FIELD_1_KEY = @"textField1";
  LCField *textField1 = [[LCField alloc] initWithName: TEXT_FIELD_1_KEY
	  string: FIELD_1_TEXT
	  store: LCStore_YES
	  index: LCIndex_Tokenized
	  termVector: LCTermVector_NO];
  
  FIELD_2_TEXT = @"field field field two text";
  //Fields will be lexicographically sorted.  So, the order is: field, text, two
  NSArray *FIELD_2_FREQS = [[NSArray alloc] initWithObjects: [NSNumber numberWithInt: 3],
	  [NSNumber numberWithInt: 1], 
	  [NSNumber numberWithInt: 1], nil]; 
  TEXT_FIELD_2_KEY = @"textField2";
  LCField *textField2 = [[LCField alloc] initWithName: TEXT_FIELD_2_KEY
	  string: FIELD_2_TEXT
	  store: LCStore_YES
	  index: LCIndex_Tokenized
	  termVector: LCTermVector_WithPositionsAndOffsets];
  
  KEYWORD_TEXT = @"Keyword";
  KEYWORD_FIELD_KEY = @"keyField";
  LCField *keyField = [[LCField alloc] initWithName: KEYWORD_FIELD_KEY 
	  string: KEYWORD_TEXT
	  store: LCStore_YES
	  index: LCIndex_Untokenized];
  
  UNINDEXED_FIELD_TEXT = @"unindexed field text";
  UNINDEXED_FIELD_KEY = @"unIndField";
  LCField *unIndField = [[LCField alloc] initWithName: UNINDEXED_FIELD_KEY
	  string: UNINDEXED_FIELD_TEXT
	  store: LCStore_YES
	  index: LCIndex_NO];
  
  UNSTORED_1_FIELD_TEXT = @"unstored field text";
  UNSTORED_FIELD_1_KEY = @"unStoredField1";
  LCField *unStoredField1 = [[LCField alloc] initWithName: UNSTORED_FIELD_1_KEY
	  string: UNSTORED_1_FIELD_TEXT
	  store: LCStore_NO
	  index: LCIndex_Tokenized
	  termVector: LCTermVector_NO];

  UNSTORED_2_FIELD_TEXT = @"unstored field text";
  UNSTORED_FIELD_2_KEY = @"unStoredField2";
  LCField *unStoredField2 = [[LCField alloc] initWithName: UNSTORED_FIELD_2_KEY
	  string: UNSTORED_2_FIELD_TEXT
	  store: LCStore_NO
	  index: LCIndex_Tokenized
	  termVector: LCTermVector_YES];

  /**
   * Adds the fields above to a document 
   * @param doc The document to write
   */ 
  [doc addField: textField1];
  [doc addField: textField2];
  [doc addField: keyField];
  [doc addField: unIndField];
  [doc addField: unStoredField1];
  [doc addField: unStoredField2];
}                         

+ (NSDictionary *) nameValues
{
  NSDictionary *nameValues = [[NSDictionary alloc] initWithObjectsAndKeys:
    FIELD_1_TEXT, TEXT_FIELD_1_KEY,
    FIELD_2_TEXT, TEXT_FIELD_2_KEY,
    KEYWORD_TEXT, KEYWORD_FIELD_KEY,
    UNINDEXED_FIELD_TEXT, UNINDEXED_FIELD_KEY,
    UNSTORED_1_FIELD_TEXT, UNSTORED_FIELD_1_KEY, 
    UNSTORED_2_FIELD_TEXT, UNSTORED_FIELD_2_KEY, nil];
    return AUTORELEASE(nameValues);
}
  
  /**
   * Writes the document to the directory using a segment named "test"
   * @param dir
   * @param doc
   */ 
+ (void) writeDirectory: (id <LCDirectory>) dir doc: (LCDocument *) doc
{
  [TestDocHelper writeDirectory: dir segment: @"test" doc: doc];
}

  /**
   * Writes the document to the directory in the given segment
   * @param dir
   * @param segment
   * @param doc
   */ 
+ (void) writeDirectory: (id <LCDirectory>) dir segment: (NSString *) segment              doc: (LCDocument *) doc
{
  LCAnalyzer *analyzer = [[LCWhitespaceAnalyzer alloc] init];
  LCSimilarity *similarity = [LCSimilarity defaultSimilarity];
  [TestDocHelper writeDirectory: dir
	  analyzer: analyzer
	  similarity: similarity
	  segment: segment
	  doc: doc];
  }

  /**
   * Writes the document to the directory segment named "test" using the specified analyzer and similarity
   * @param dir
   * @param analyzer
   * @param similarity
   * @param doc
   */ 
+ (void) writeDirectory: (id <LCDirectory>) dir 
         analyzer: (LCAnalyzer *) analyzer
         similarity: (LCSimilarity *) similarity doc: (LCDocument *) doc
{
  [TestDocHelper writeDirectory: dir
	  analyzer: analyzer
	  similarity: similarity
	  segment: @"test" 
	  doc: doc];
}

  /**
   * Writes the document to the directory segment using the analyzer and the similarity score
   * @param dir
   * @param analyzer
   * @param similarity
   * @param segment
   * @param doc
   */ 
+ (void) writeDirectory: (id <LCDirectory>) dir 
         analyzer: (LCAnalyzer *) analyzer
         similarity: (LCSimilarity *) similarity
	 segment: (NSString *) segment doc: (LCDocument *) doc
{
  LCDocumentWriter *writer = [[LCDocumentWriter alloc]
	  initWithDirectory: dir
	  analyzer: analyzer
	  similarity: similarity
	  maxFieldLength: 50];
  [writer addDocument: segment document: doc];
}

+ (int) numFields: (LCDocument *) doc  
{
  NSEnumerator *e = [doc fieldEnumerator];
  int result = 0;
    while ([e nextObject])
    {
      result++;
    }
    return result;
}

@end
