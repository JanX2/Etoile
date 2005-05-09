#include "GNUstep/GNUstep.h"
#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include "Document/LCDocument.h"
#include "Document/LCField.h"
#include "Index/LCIndexWriter.h"
#include "Index/LCIndexReader.h"
#include "Index/LCTermEnum.h"
#include "Index/LCTerm.h"
#include "Store/LCRAMDirectory.h"
#include "Analysis/LCWhitespaceAnalyzer.h"

@interface TestSegmentTermEnum: NSObject <UKTest>
@end

@implementation TestSegmentTermEnum

- (void) addDoc: (LCIndexWriter *) writer : (NSString *) value
{
	LCDocument *doc = [[LCDocument alloc] init];
	LCField *field = [[LCField alloc] initWithName: @"content" string: value
											 store: LCStore_NO index: LCIndex_Tokenized];
	[doc addField: field];
	[writer addDocument: doc];
}

- (void) verifyDocFreq: (id <LCDirectory>) dir count: (int) total
{
	LCIndexReader *reader = [LCIndexReader openDirectory: dir];
	LCTermEnum *termEnum = nil;
	
	// create enumeration of all terms
	termEnum = [reader terms];
	// go to the first term (aaa)
	[termEnum next];
	
    // assert that term is 'aaa'
	UKStringsEqual(@"aaa", [[termEnum term] text]);
	UKIntsEqual(total*2, [termEnum documentFrequency]);
	// go to the second term (bbb)
	[termEnum next];
	// assert that term is 'bbb'
	UKStringsEqual(@"bbb", [[termEnum term] text]);
	UKIntsEqual(total, [termEnum documentFrequency]);
	
	[termEnum close];
	
    // create enumeration of terms after term 'aaa', including 'aaa'
    termEnum = [reader termsWithTerm: [[LCTerm alloc] initWithField: @"content" text: @"aaa"]];
    // assert that term is 'aaa'
	UKStringsEqual(@"aaa", [[termEnum term] text]);
	UKIntsEqual(2*total, [termEnum documentFrequency]);
	// go to term 'bbb'
    [termEnum next];
    // assert that term is 'bbb'
    UKStringsEqual(@"bbb", [[termEnum term] text]);
	UKIntsEqual(total, [termEnum documentFrequency]);
	[termEnum close];
}

- (void) testSegmentTermEnum
{
	id <LCDirectory> dir = [[LCRAMDirectory alloc] init];
	LCIndexWriter *writer = nil;
	writer = [[LCIndexWriter alloc] initWithDirectory: dir
											 analyzer: [[LCWhitespaceAnalyzer alloc] init]
											   create: YES];
	
	// add 100 documents with term : aaa
	// add 100 documents with terms: aaa bbb
	// Therefore, term 'aaa' has document frequency of 200 and term 'bbb' 100
	int i, total = 100;
	for (i = 0; i < total; i++)
    {
		[self addDoc: writer : @"aaa"];
		[self addDoc: writer : @"aaa bbb"];
    }
	[writer close];
	
	// verify document frequency of terms in an unoptimized index
	[self verifyDocFreq: dir count: total];
	
	// merge segments by optimizing the index
	writer = [[LCIndexWriter alloc] initWithDirectory: dir
											 analyzer: [[LCWhitespaceAnalyzer alloc] init]
											   create: NO];
	[writer optimize];
	[writer close];
	// verify document frequency of terms in an optimized index
	[self verifyDocFreq: dir count: total];
}

@end
