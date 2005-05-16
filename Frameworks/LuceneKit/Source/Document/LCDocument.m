#include <LuceneKit/Document/LCDocument.h>
#include <LuceneKit/GNUstep/GNUstep.h>

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

@implementation LCDocument

- (id) init
{
	self = [super init];
	fields = [[NSMutableArray alloc] init];
	boost = 1.0f;
	return self;
}

- (void) dealloc
{
	DESTROY(fields);
	[super dealloc];
}

/** Sets a boost factor for hits on any field of this document.  This value
* will be multiplied into the score of all hits on this document.
*
* <p>Values are multiplied into the value of {@link Field#getBoost()} of
* each field in this document.  Thus, this method in effect sets a default
* boost for the fields of this document.
*
* @see Field#setBoost(float)
*/
- (void) setBoost: (float) b
{
	boost = b;
}

/** Returns the boost factor for hits on any field of this document.
*
* <p>The default value is 1.0.
*
* <p>Note: This value is not stored directly with the document in the index.
* Documents returned from {@link IndexReader#document(int)} and
* {@link Hits#doc(int)} may thus not have the same value present as when
* this document was indexed.
*
* @see #setBoost(float)
*/
- (float) boost
{
	return boost;
}

/**
* <p>Adds a field to a document.  Several fields may be added with
 * the same name.  In this case, if the fields are indexed, their text is
 * treated as though appended for the purposes of search.</p>
 * <p> Note that add like the removeField(s) methods only makes sense 
 * prior to adding a document to an index. These methods cannot
 * be used to change the content of an existing index! In order to achieve this,
 * a document has to be deleted from an index and a new changed version of that
 * document has to be added.</p>
 */
- (void) addField: (LCField *) f
{
	[fields addObject: f];
}

/**
* <p>Removes field with the specified name from the document.
 * If multiple fields exist with this name, this method removes the first field that has been added.
 * If there is no field with the specified name, the document remains unchanged.</p>
 * <p> Note that the removeField(s) methods like the add method only make sense 
 * prior to adding a document to an index. These methods cannot
 * be used to change the content of an existing index! In order to achieve this,
 * a document has to be deleted from an index and a new changed version of that
 * document has to be added.</p>
 */
- (void) removeFieldWithName: (NSString *) n
{
	LCField *field;
	int i, count = [fields count];
	for(i = 0; i < count; i++)
    {
		field = [fields objectAtIndex: i];
		if ([[field name] isEqualToString: n])
        {
			[fields removeObjectAtIndex: i];
			return;
		}
    }
}

/**
* <p>Removes all fields with the given name from the document.
 * If there is no field with the specified name, the document remains unchanged.</p>
 * <p> Note that the removeField(s) methods like the add method only make sense 
 * prior to adding a document to an index. These methods cannot
 * be used to change the content of an existing index! In order to achieve this,
 * a document has to be deleted from an index and a new changed version of that
 * document has to be added.</p>
 */

- (void) removeFieldsWithName: (NSString *) n
{
	LCField *field;
	int i;
	for(i = [fields count]-1; i > -1; i--)
    {
		field = [fields objectAtIndex: i];
		if ([[field name] isEqualToString: n])
        {
			[fields removeObjectAtIndex: i];
		}
    }
}

/** Returns a field with the given name if any exist in this document, or
* null.  If multiple fields exists with this name, this method returns the
* first value added.
*/
- (LCField *) fieldWithName: (NSString *) name
{
	LCField *field;
	int i, count = [fields count];;
	for (i = 0; i < count; i++) 
    {
		field = [fields objectAtIndex: i];
		if ([[field name] isEqualToString: name])
			return field;
    }
	return nil;
}

/** Returns the string value of the field with the given name if any exist in
* this document, or null.  If multiple fields exist with this name, this
* method returns the first value added. If only binary fields with this name
* exist, returns null.
*/
- (NSString *) stringValue: (NSString *) name
{
	int i;
	LCField *field;
	for (i = 0; i < [fields count]; i++)
    {
		field = [fields objectAtIndex: i];
		if ([[field name] isEqualToString: name] && (![field isBinary]))
			return [field stringValue];;
    }
	return nil;
}

/** Returns an Enumeration of all the fields in a document. */
- (NSEnumerator *) fieldEnumerator
{
	return [fields objectEnumerator];
}

/**
* Returns an array of {@link Field}s with the given name.
 * This method can return <code>null</code>.
 *
 * @param name the name of the field
 * @return a <code>Field[]</code> array
 */
- (NSArray *) fieldsWithName: (NSString *) name
{
	LCField *field;
	int i, count = [fields count];;
	NSMutableArray *a = [[NSMutableArray alloc] init];
	for (i = 0; i < count; i++)
    {
		field = [fields objectAtIndex: i];
		if ([[field name] isEqualToString: name])
        {
			[a addObject: field];
        }
	}
	if ([a count] > 0)
		return AUTORELEASE(a);
	else
    {
		DESTROY(a);
		return nil;
    }
}

/**
* Returns an array of values of the field specified as the method parameter.
 * This method can return <code>null</code>.
 *
 * @param name the name of the field
 * @return a <code>String[]</code> of field values
 */
- (NSArray *) stringValues: (NSString *) name
{
	NSMutableArray *result = [[NSMutableArray alloc] init];
	int i, count = [fields count];
	LCField *field;
	for(i = 0; i < count; i++)
    {
		field = [fields objectAtIndex: i];
		if ([[field name] isEqualToString: name] && (![field isBinary]))
			[result addObject: [field stringValue]];
    }
	if ([result count] > 0)
		return AUTORELEASE(result);
	else
	{
		DESTROY(result);
		return nil;
	}
}

/**
* Returns an array of byte arrays for of the fields that have the name specified
 * as the method parameter. This method will return <code>null</code> if no
 * binary fields with the specified name are available.
 *
 * @param name the name of the field
 * @return a  <code>byte[][]</code> of binary field values.
 */

- (NSArray *) binaryValues: (NSString *) name
{
	NSMutableArray *result = [[NSMutableArray alloc] init];
	int i, count = [fields count];
	LCField *field;
	for (i = 0; i < count; i++) {
		field = [fields objectAtIndex: i];
		if ([[field name] isEqualToString: name] && [field isBinary])
			[result addObject: [field binaryValue]];
	}
	if ([result count] > 0)
		return AUTORELEASE(result);
	else
	{
		DESTROY(result);
		return nil;
	}
}

- (NSData *) binaryValue: (NSString *) name
{
	int i, count = [fields count];
	LCField *field;
	for (i = 0; i < count; i++) {
		field = [fields objectAtIndex: i];
		if ([[field name] isEqualToString: name] && [field isBinary])
			return [field binaryValue];
	}
	return nil;
}


/** Prints the fields of a document for human consumption. */
- (NSString *) description
{
	NSMutableString *s = [[NSMutableString alloc] init];
	[s appendString: @"Document<"];
	LCField *field;
	int i;
	for (i = 0; i < [fields count]; i++) 
    {
		field = [fields objectAtIndex: i];
		[s appendString: [field description]];
		if (i != [fields count]-1)
			[s appendString: @" "];
    }
    [s appendString: @">"];
    return AUTORELEASE(s);
}

- (NSArray *) fields
{
	return fields;
}

#ifdef HAVE_UKTEST

- (void) makeDocumentWithFields
{
	[self addField: [[LCField alloc] initWithName: @"keyword" 
										   string: @"test1"
											store: LCStore_YES
											index: LCIndex_Untokenized]];
	[self addField: [[LCField alloc] initWithName: @"keyword" 
										   string: @"test2"
											store: LCStore_YES
											index: LCIndex_Untokenized]];
	[self addField: [[LCField alloc] initWithName: @"text" 
										   string: @"test1"
											store: LCStore_YES
											index: LCIndex_Tokenized]];
	[self addField: [[LCField alloc] initWithName: @"text" 
										   string: @"test2"
											store: LCStore_YES
											index: LCIndex_Tokenized]];
	[self addField: [[LCField alloc] initWithName: @"unindexed" 
										   string: @"test1"
											store: LCStore_YES
											index: LCIndex_NO]];
	[self addField: [[LCField alloc] initWithName: @"unindexed" 
										   string: @"test2"
											store: LCStore_YES
											index: LCIndex_NO]];
	[self addField: [[LCField alloc] initWithName: @"unstored" 
										   string: @"test1"
											store: LCStore_YES
											index: LCIndex_Tokenized]];
	[self addField: [[LCField alloc] initWithName: @"unstored" 
										   string: @"test2"
											store: LCStore_YES
											index: LCIndex_Tokenized]];
}

- (void) doAssertFromIndex: (BOOL) fromIndex
{
	NSArray *keywordFieldValues = [self stringValues: @"keyword"];
	NSArray *textFieldValues = [self stringValues: @"text"];
	NSArray *unindexedFieldValues = [self stringValues: @"unindexed"];
	NSArray *unstoredFieldValues = [self stringValues: @"unstored"];
	
	UKIntsEqual(2, [keywordFieldValues count]);
	UKIntsEqual(2, [textFieldValues count]);
	UKIntsEqual(2, [unindexedFieldValues count]);
	// this test cannot work for documents retrieved from the index
	// since unstored fields will obviously not be returned
	if (! fromIndex)
    {
		UKIntsEqual(2, [unstoredFieldValues count]);
    }
	
	UKStringsEqual(@"test1", [keywordFieldValues objectAtIndex: 0]);
	UKStringsEqual(@"test2", [keywordFieldValues objectAtIndex: 1]);
	UKStringsEqual(@"test1", [textFieldValues objectAtIndex: 0]);
	UKStringsEqual(@"test2", [textFieldValues objectAtIndex: 1]);
	UKStringsEqual(@"test1", [unindexedFieldValues objectAtIndex: 0]);
	UKStringsEqual(@"test2", [unindexedFieldValues objectAtIndex: 1]);
	// this test cannot work for documents retrieved from the index
	// since unstored fields will obviously not be returned
	if (! fromIndex)
    {
		UKStringsEqual(@"test1", [unstoredFieldValues objectAtIndex: 0]);
		UKStringsEqual(@"test2", [unstoredFieldValues objectAtIndex: 1]);
    }
}

- (void) testRemoveForNewDocument
{
	[self makeDocumentWithFields];
	UKIntsEqual(8, [[self fields] count]);
	[self removeFieldsWithName: @"keyword"];
	UKIntsEqual(6, [[self fields] count]);
	[self removeFieldsWithName: @"doexnotexists"];
	[self removeFieldsWithName: @"keyword"];
	UKIntsEqual(6, [[self fields] count]);
	[self removeFieldWithName: @"text"];
	UKIntsEqual(5, [[self fields] count]);
	[self removeFieldWithName: @"text"];
	UKIntsEqual(4, [[self fields] count]);
	[self removeFieldWithName: @"text"];
	UKIntsEqual(4, [[self fields] count]);
	[self removeFieldWithName: @"doesnotexists"];
	UKIntsEqual(4, [[self fields] count]);
	[self removeFieldsWithName: @"unindexed"];
	UKIntsEqual(2, [[self fields] count]);
	[self removeFieldsWithName: @"unstored"];
	UKIntsEqual(0, [[self fields] count]);
	[self removeFieldWithName: @"doesnotexists"];
	UKIntsEqual(0, [[self fields] count]);
}

- (void) testGetValuesForNewDocument
{
	[self makeDocumentWithFields];
	[self doAssertFromIndex: NO];
}

- (void) testBinaryField
{
	NSString *binaryVal = @"this text will be stored as a byte array in the index";
	NSString *binaryVal2 = @"this text will be also stored as a byte array in the index";
	
	LCField *stringFld = [[LCField alloc] initWithName: @"string"
												string: binaryVal
												 store: LCStore_YES
												 index: LCIndex_NO];
	LCField *binaryFld = [[LCField alloc] initWithName: @"binary"
												 value: [binaryVal dataUsingEncoding: [NSString defaultCStringEncoding]]
												 store: LCStore_YES];
	LCField *binaryFld2 = [[LCField alloc] initWithName: @"binary"
												  value: [binaryVal2 dataUsingEncoding: [NSString defaultCStringEncoding]]
												  store: LCStore_YES];
	
	[self addField: stringFld];
	[self addField: binaryFld];
	
	UKIntsEqual(2, [[self fields] count]);
	
	UKTrue([binaryFld isBinary]);
	UKTrue([binaryFld isStored]);
	UKFalse([binaryFld isIndexed]);
	UKFalse([binaryFld isTokenized]);
	
	NSString *binaryTest = [[NSString alloc] initWithData: [self binaryValue: @"binary"] 
												 encoding: [NSString defaultCStringEncoding]];
	UKStringsEqual(binaryTest, binaryVal);
	
	NSString *stringTest = [self stringValue: @"string"];
	UKStringsEqual(binaryTest, stringTest);
	
	[self addField: binaryFld2];
	UKIntsEqual(3, [[self fields] count]);
	
	NSArray *binaryTests = [self binaryValues: @"binary"];
	UKIntsEqual(2, [binaryTests count]);
	
	binaryTest = [[NSString alloc] initWithData: [binaryTests objectAtIndex: 0] 
									   encoding: [NSString defaultCStringEncoding]];
	NSString *binaryTest2 = [[NSString alloc] initWithData: [binaryTests objectAtIndex: 1] 
												  encoding: [NSString defaultCStringEncoding]];
    
	UKFalse([binaryTest isEqualToString: binaryTest2]);
	UKStringsEqual(binaryTest, binaryVal);
	UKStringsEqual(binaryTest2, binaryVal2);
	
	[self removeFieldWithName: @"string"];
	UKIntsEqual(2, [[self fields] count]);
	
	[self removeFieldsWithName: @"binary"];
	UKIntsEqual(0, [[self fields] count]);
}

#if 0
public void testConstructorExceptions()
{
	new Field("name", "value", Field.Store.YES, Field.Index.NO);  // okay
	new Field("name", "value", Field.Store.NO, Field.Index.UN_TOKENIZED);  // okay
	try {
		new Field("name", "value", Field.Store.NO, Field.Index.NO);
		fail();
	} catch(IllegalArgumentException e) {
		// expected exception
	}
	new Field("name", "value", Field.Store.YES, Field.Index.NO, Field.TermVector.NO); // okay
	try {
		new Field("name", "value", Field.Store.YES, Field.Index.NO, Field.TermVector.YES);
		fail();
	} catch(IllegalArgumentException e) {
		// expected exception
	}
}
#endif
//

#if 0
public void testGetValuesForIndexedDocument() throws Exception
{
	RAMDirectory dir = new RAMDirectory();
	IndexWriter writer = new IndexWriter(dir, new StandardAnalyzer(), true);
	writer.addDocument(makeDocumentWithFields());
	writer.close();
	
	Searcher searcher = new IndexSearcher(dir);
	
	// search for something that does exists
	Query query = new TermQuery(new Term("keyword", "test1"));
	
	// ensure that queries return expected results without DateFilter first
	Hits hits = searcher.search(query);
	assertEquals(1, hits.length());
	
	try
	{
		doAssert(hits.doc(0), true);
	}
	catch (Exception e)
	{
		e.printStackTrace(System.err);
		System.err.print("\n");
	}
	finally
	{
		searcher.close();
	}
}

#endif

#endif

@end
