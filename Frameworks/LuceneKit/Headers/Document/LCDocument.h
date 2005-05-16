#ifndef __LUCENE_DOCUMENT_DOCUMENT__
#define __LUCENE_DOCUMENT_DOCUMENT__

#include <Foundation/Foundation.h>
#include <LuceneKit/Document/LCField.h>

/** Documents are the unit of indexing and search.
*
* A Document is a set of fields.  Each field has a name and a textual value.
* A field may be {@link Field#isStored() stored} with the document, in which
* case it is returned with search hits on the document.  Thus each document
* should typically contain one or more stored fields which uniquely identify
* it.
*
* <p>Note that fields which are <i>not</i> {@link Field#isStored() stored} are
* <i>not</i> available in documents retrieved from the index, e.g. with {@link
	* Hits#doc(int)}, {@link Searcher#doc(int)} or {@link
		* IndexReader#document(int)}.
*/

#ifdef HAVE_UKTEST
#include <UnitKit/UnitKit.h>
@interface LCDocument: NSObject <UKTest>
#else
@interface LCDocument: NSObject
#endif
{
	NSMutableArray *fields;
	float boost;
}

- (void) setBoost: (float) boost;
- (float) boost;
- (void) addField: (LCField *) field;
- (void) removeFieldWithName: (NSString *) name;
- (void) removeFieldsWithName: (NSString *) name;
- (LCField *) fieldWithName: (NSString *) name;
- (NSString *) stringValue: (NSString *) name;
- (NSEnumerator *) fieldEnumerator;
- (NSArray *) fieldsWithName: (NSString *) name;;
- (NSArray *) stringValues: (NSString *) name;
- (NSArray *) binaryValues: (NSString *) name;
- (NSData *) binaryValue: (NSString *) name;
- (NSArray *) fields;

@end

#endif
