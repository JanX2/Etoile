#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include "Store/LCRAMDirectory.h"
#include "Index/LCIndexWriter.h"
#include "Index/LCIndexReader.h"
#include "Document/LCDocument.h"
#include "Document/LCField.h"
#include "Analysis/LCWhitespaceAnalyzer.h"
#include "GNUstep/GNUstep.h"

@interface TestIndexReader: NSObject <UKTest>
@end

@implementation TestIndexReader

- (void) addDocumentWithFields: (LCIndexWriter *) writer
{
  LCDocument *doc = [[LCDocument alloc] init];
  LCField *field = [[LCField alloc] initWithName: @"keyword"
	  string: @"test1"
	  store: LCStore_YES
	  index: LCIndex_Untokenized];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"text"
	  string: @"test1"
	  store: LCStore_YES
	  index: LCIndex_Tokenized];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"unindexed"
	  string: @"test1"
	  store: LCStore_YES
	  index: LCIndex_NO];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"unstored"
	  string: @"test1"
	  store: LCStore_NO
	  index: LCIndex_Tokenized];
  [doc addField: field];
  RELEASE(field);
  [writer addDocument: doc];
  RELEASE(doc);
}

- (void) addDocumentWithDifferentFields: (LCIndexWriter *) writer
{
  LCDocument *doc = [[LCDocument alloc] init];
  LCField *field = [[LCField alloc] initWithName: @"keyword2"
	  string: @"test1"
	  store: LCStore_YES
	  index: LCIndex_Untokenized];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"text2"
	  string: @"test1"
	  store: LCStore_YES
	  index: LCIndex_Tokenized];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"unindexed2"
	  string: @"test1"
	  store: LCStore_YES
	  index: LCIndex_NO];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"unstored2"
	  string: @"test1"
	  store: LCStore_NO
	  index: LCIndex_Tokenized];
  [doc addField: field];
  RELEASE(field);
  [writer addDocument: doc];
  RELEASE(doc);
}

- (void) addDocumentWithTermVectorFields: (LCIndexWriter *) writer
{
  LCDocument *doc = [[LCDocument alloc] init];
  LCField *field = [[LCField alloc] initWithName: @"tvnot"
	  string: @"tvnot"
	  store: LCStore_YES
	  index: LCIndex_Tokenized
	  termVector: LCTermVector_NO];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"termvector"
	  string: @"termvector"
	  store: LCStore_YES
	  index: LCIndex_Tokenized
	  termVector: LCTermVector_YES];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"tvoffset"
	  string: @"tvoffset"
	  store: LCStore_YES
	  index: LCIndex_Tokenized
	  termVector: LCTermVector_WithOffsets];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"tvposition"
	  string: @"tvposition"
	  store: LCStore_YES
	  index: LCIndex_Tokenized
	  termVector: LCTermVector_WithPositions];
  [doc addField: field];
  RELEASE(field);
  field = [[LCField alloc] initWithName: @"tvpositionoffset"
	  string: @"tvpositionoffset"
	  store: LCStore_YES
	  index: LCIndex_Tokenized
	  termVector: LCTermVector_WithPositionsAndOffsets];
  [doc addField: field];
  RELEASE(field);
  [writer addDocument: doc];
  RELEASE(doc);
}

- (void) addDoc: (LCIndexWriter *) writer value: (NSString *) value
{
  LCDocument *doc = [[LCDocument alloc] init];
  LCField *field = [[LCField alloc] initWithName: @"content"
	  string: value
	  store: LCStore_NO
	  index: LCIndex_Tokenized];
  [doc addField: field];
  RELEASE(field);
  [writer addDocument: doc];
  RELEASE(doc);
}
    /**
     * Tests the IndexReader.getFieldNames implementation
     * @throws Exception on error
     */
- (void) testGetFieldNames
{
  LCRAMDirectory *d = [[LCRAMDirectory alloc] init];
  // set up writer
  // FIXME: original test using StandardAnalyzer
  LCIndexWriter *writer = [[LCIndexWriter alloc] initWithDirectory: d
	  analyzer: [[LCWhitespaceAnalyzer alloc] init]
	  create: YES];
  [self addDocumentWithFields: writer];
  [writer close];
        // set up reader
  LCIndexReader *reader = [LCIndexReader openDirectory: d];
  NSArray *fieldNames = [reader fieldNames: LCFieldOption_ALL];
  UKTrue([fieldNames containsObject: @"keyword"]);
  UKTrue([fieldNames containsObject: @"text"]);
  UKTrue([fieldNames containsObject: @"unindexed"]);
  UKTrue([fieldNames containsObject: @"unstored"]);
  [reader close];
  // add more documents
  writer = [[LCIndexWriter alloc] initWithDirectory: d
	  analyzer: [[LCWhitespaceAnalyzer alloc] init]
	  create: NO];
  // want to get some more segments here
  int i;
  for (i = 0; i < 5*[writer mergeFactor]; i++)
  {
     [self addDocumentWithFields: writer];
  }
  // new fields are in some different segments (we hope)
  for (i = 0; i < 5*[writer mergeFactor]; i++)
  {
     [self addDocumentWithDifferentFields: writer];
  }
  // new termvector fields
  for (i = 0; i < 5*[writer mergeFactor]; i++)
  {
    [self addDocumentWithTermVectorFields: writer];
  }
        
  [writer close];
  [d close];

  DESTROY(writer);
        // verify fields again
#if 0
  reader = [LCIndexReader openDirectory: d];
  fieldNames = [reader fieldNames: LCFieldOption_ALL];
        assertEquals(13, fieldNames.size());    // the following fields
        assertTrue(fieldNames.contains("keyword"));
        assertTrue(fieldNames.contains("text"));
        assertTrue(fieldNames.contains("unindexed"));
        assertTrue(fieldNames.contains("unstored"));
        assertTrue(fieldNames.contains("keyword2"));
        assertTrue(fieldNames.contains("text2"));
        assertTrue(fieldNames.contains("unindexed2"));
        assertTrue(fieldNames.contains("unstored2"));
        assertTrue(fieldNames.contains("tvnot"));
        assertTrue(fieldNames.contains("termvector"));
        assertTrue(fieldNames.contains("tvposition"));
        assertTrue(fieldNames.contains("tvoffset"));
        assertTrue(fieldNames.contains("tvpositionoffset"));
        
        // verify that only indexed fields were returned
        fieldNames = reader.getFieldNames(IndexReader.FieldOption.INDEXED);
        assertEquals(11, fieldNames.size());    // 6 original + the 5 termvector fields 
        assertTrue(fieldNames.contains("keyword"));
        assertTrue(fieldNames.contains("text"));
        assertTrue(fieldNames.contains("unstored"));
        assertTrue(fieldNames.contains("keyword2"));
        assertTrue(fieldNames.contains("text2"));
        assertTrue(fieldNames.contains("unstored2"));
        assertTrue(fieldNames.contains("tvnot"));
        assertTrue(fieldNames.contains("termvector"));
        assertTrue(fieldNames.contains("tvposition"));
        assertTrue(fieldNames.contains("tvoffset"));
        assertTrue(fieldNames.contains("tvpositionoffset"));
        
        // verify that only unindexed fields were returned
        fieldNames = reader.getFieldNames(IndexReader.FieldOption.UNINDEXED);
        assertEquals(2, fieldNames.size());    // the following fields
        assertTrue(fieldNames.contains("unindexed"));
        assertTrue(fieldNames.contains("unindexed2"));
                
        // verify index term vector fields  
        fieldNames = reader.getFieldNames(IndexReader.FieldOption.TERMVECTOR);
        assertEquals(1, fieldNames.size());    // 1 field has term vector only
        assertTrue(fieldNames.contains("termvector"));
        
        fieldNames = reader.getFieldNames(IndexReader.FieldOption.TERMVECTOR_WITH_POSITION);
        assertEquals(1, fieldNames.size());    // 4 fields are indexed with term vectors
        assertTrue(fieldNames.contains("tvposition"));
        
        fieldNames = reader.getFieldNames(IndexReader.FieldOption.TERMVECTOR_WITH_OFFSET);
        assertEquals(1, fieldNames.size());    // 4 fields are indexed with term vectors
        assertTrue(fieldNames.contains("tvoffset"));
                
        fieldNames = reader.getFieldNames(IndexReader.FieldOption.TERMVECTOR_WITH_POSITION_OFFSET);
        assertEquals(1, fieldNames.size());    // 4 fields are indexed with term vectors
        assertTrue(fieldNames.contains("tvpositionoffset"));
#endif
        
  DESTROY(d);
    }

#if 0
    private void assertTermDocsCount(String msg,
                                     IndexReader reader,
                                     Term term,
                                     int expected)
    throws IOException
    {
        TermDocs tdocs = null;

        try {
            tdocs = reader.termDocs(term);
            assertNotNull(msg + ", null TermDocs", tdocs);
            int count = 0;
            while(tdocs.next()) {
                count++;
            }
            assertEquals(msg + ", count mismatch", expected, count);

        } finally {
            if (tdocs != null)
                try { tdocs.close(); } catch (Exception e) { }
        }

    }



    public void testBasicDelete() throws IOException
    {
        Directory dir = new RAMDirectory();

        IndexWriter writer = null;
        IndexReader reader = null;
        Term searchTerm = new Term("content", "aaa");

        //  add 100 documents with term : aaa
        writer  = new IndexWriter(dir, new WhitespaceAnalyzer(), true);
        for (int i = 0; i < 100; i++)
        {
            addDoc(writer, searchTerm.text());
        }
        writer.close();

        // OPEN READER AT THIS POINT - this should fix the view of the
        // index at the point of having 100 "aaa" documents and 0 "bbb"
        reader = IndexReader.open(dir);
        assertEquals("first docFreq", 100, reader.docFreq(searchTerm));
        assertTermDocsCount("first reader", reader, searchTerm, 100);

        // DELETE DOCUMENTS CONTAINING TERM: aaa
        int deleted = 0;
        reader = IndexReader.open(dir);
        deleted = reader.delete(searchTerm);
        assertEquals("deleted count", 100, deleted);
        assertEquals("deleted docFreq", 100, reader.docFreq(searchTerm));
        assertTermDocsCount("deleted termDocs", reader, searchTerm, 0);
        reader.close();

        // CREATE A NEW READER and re-test
        reader = IndexReader.open(dir);
        assertEquals("deleted docFreq", 100, reader.docFreq(searchTerm));
        assertTermDocsCount("deleted termDocs", reader, searchTerm, 0);
        reader.close();
    }


    public void testDeleteReaderWriterConflictUnoptimized() throws IOException{
      deleteReaderWriterConflict(false);
    }
    
    public void testDeleteReaderWriterConflictOptimized() throws IOException{
        deleteReaderWriterConflict(true);
    }

    private void deleteReaderWriterConflict(boolean optimize) throws IOException
    {
        //Directory dir = new RAMDirectory();
        Directory dir = getDirectory(true);

        Term searchTerm = new Term("content", "aaa");
        Term searchTerm2 = new Term("content", "bbb");

        //  add 100 documents with term : aaa
        IndexWriter writer  = new IndexWriter(dir, new WhitespaceAnalyzer(), true);
        for (int i = 0; i < 100; i++)
        {
            addDoc(writer, searchTerm.text());
        }
        writer.close();

        // OPEN READER AT THIS POINT - this should fix the view of the
        // index at the point of having 100 "aaa" documents and 0 "bbb"
        IndexReader reader = IndexReader.open(dir);
        assertEquals("first docFreq", 100, reader.docFreq(searchTerm));
        assertEquals("first docFreq", 0, reader.docFreq(searchTerm2));
        assertTermDocsCount("first reader", reader, searchTerm, 100);
        assertTermDocsCount("first reader", reader, searchTerm2, 0);

        // add 100 documents with term : bbb
        writer  = new IndexWriter(dir, new WhitespaceAnalyzer(), false);
        for (int i = 0; i < 100; i++)
        {
            addDoc(writer, searchTerm2.text());
        }

        // REQUEST OPTIMIZATION
        // This causes a new segment to become current for all subsequent
        // searchers. Because of this, deletions made via a previously open
        // reader, which would be applied to that reader's segment, are lost
        // for subsequent searchers/readers
        if(optimize)
          writer.optimize();
        writer.close();

        // The reader should not see the new data
        assertEquals("first docFreq", 100, reader.docFreq(searchTerm));
        assertEquals("first docFreq", 0, reader.docFreq(searchTerm2));
        assertTermDocsCount("first reader", reader, searchTerm, 100);
        assertTermDocsCount("first reader", reader, searchTerm2, 0);


        // DELETE DOCUMENTS CONTAINING TERM: aaa
        // NOTE: the reader was created when only "aaa" documents were in
        int deleted = 0;
        try {
            deleted = reader.delete(searchTerm);
            fail("Delete allowed on an index reader with stale segment information");
        } catch (IOException e) {
            /* success */
        }

        // Re-open index reader and try again. This time it should see
        // the new data.
        reader.close();
        reader = IndexReader.open(dir);
        assertEquals("first docFreq", 100, reader.docFreq(searchTerm));
        assertEquals("first docFreq", 100, reader.docFreq(searchTerm2));
        assertTermDocsCount("first reader", reader, searchTerm, 100);
        assertTermDocsCount("first reader", reader, searchTerm2, 100);

        deleted = reader.delete(searchTerm);
        assertEquals("deleted count", 100, deleted);
        assertEquals("deleted docFreq", 100, reader.docFreq(searchTerm));
        assertEquals("deleted docFreq", 100, reader.docFreq(searchTerm2));
        assertTermDocsCount("deleted termDocs", reader, searchTerm, 0);
        assertTermDocsCount("deleted termDocs", reader, searchTerm2, 100);
        reader.close();

        // CREATE A NEW READER and re-test
        reader = IndexReader.open(dir);
        assertEquals("deleted docFreq", 100, reader.docFreq(searchTerm));
        assertEquals("deleted docFreq", 100, reader.docFreq(searchTerm2));
        assertTermDocsCount("deleted termDocs", reader, searchTerm, 0);
        assertTermDocsCount("deleted termDocs", reader, searchTerm2, 100);
        reader.close();
    }

  private Directory getDirectory(boolean create) throws IOException {
    return FSDirectory.getDirectory(new File(System.getProperty("tempDir"), "testIndex"), create);
  }

  public void testFilesOpenClose() throws IOException
    {
        // Create initial data set
        Directory dir = getDirectory(true);
        IndexWriter writer  = new IndexWriter(dir, new WhitespaceAnalyzer(), true);
        addDoc(writer, "test");
        writer.close();
        dir.close();

        // Try to erase the data - this ensures that the writer closed all files
        dir = getDirectory(true);

        // Now create the data set again, just as before
        writer  = new IndexWriter(dir, new WhitespaceAnalyzer(), true);
        addDoc(writer, "test");
        writer.close();
        dir.close();

        // Now open existing directory and test that reader closes all files
        dir = getDirectory(false);
        IndexReader reader1 = IndexReader.open(dir);
        reader1.close();
        dir.close();

        // The following will fail if reader did not close all files
        dir = getDirectory(true);
    }

    public void testDeleteReaderReaderConflictUnoptimized() throws IOException{
      deleteReaderReaderConflict(false);
    }
    
    public void testDeleteReaderReaderConflictOptimized() throws IOException{
      deleteReaderReaderConflict(true);
    }
    
    private void deleteReaderReaderConflict(boolean optimize) throws IOException
    {
        Directory dir = getDirectory(true);

        Term searchTerm1 = new Term("content", "aaa");
        Term searchTerm2 = new Term("content", "bbb");
        Term searchTerm3 = new Term("content", "ccc");

        //  add 100 documents with term : aaa
        //  add 100 documents with term : bbb
        //  add 100 documents with term : ccc
        IndexWriter writer  = new IndexWriter(dir, new WhitespaceAnalyzer(), true);
        for (int i = 0; i < 100; i++)
        {
            addDoc(writer, searchTerm1.text());
            addDoc(writer, searchTerm2.text());
            addDoc(writer, searchTerm3.text());
        }
        if(optimize)
          writer.optimize();
        writer.close();

        // OPEN TWO READERS
        // Both readers get segment info as exists at this time
        IndexReader reader1 = IndexReader.open(dir);
        assertEquals("first opened", 100, reader1.docFreq(searchTerm1));
        assertEquals("first opened", 100, reader1.docFreq(searchTerm2));
        assertEquals("first opened", 100, reader1.docFreq(searchTerm3));
        assertTermDocsCount("first opened", reader1, searchTerm1, 100);
        assertTermDocsCount("first opened", reader1, searchTerm2, 100);
        assertTermDocsCount("first opened", reader1, searchTerm3, 100);

        IndexReader reader2 = IndexReader.open(dir);
        assertEquals("first opened", 100, reader2.docFreq(searchTerm1));
        assertEquals("first opened", 100, reader2.docFreq(searchTerm2));
        assertEquals("first opened", 100, reader2.docFreq(searchTerm3));
        assertTermDocsCount("first opened", reader2, searchTerm1, 100);
        assertTermDocsCount("first opened", reader2, searchTerm2, 100);
        assertTermDocsCount("first opened", reader2, searchTerm3, 100);

        // DELETE DOCS FROM READER 2 and CLOSE IT
        // delete documents containing term: aaa
        // when the reader is closed, the segment info is updated and
        // the first reader is now stale
        reader2.delete(searchTerm1);
        assertEquals("after delete 1", 100, reader2.docFreq(searchTerm1));
        assertEquals("after delete 1", 100, reader2.docFreq(searchTerm2));
        assertEquals("after delete 1", 100, reader2.docFreq(searchTerm3));
        assertTermDocsCount("after delete 1", reader2, searchTerm1, 0);
        assertTermDocsCount("after delete 1", reader2, searchTerm2, 100);
        assertTermDocsCount("after delete 1", reader2, searchTerm3, 100);
        reader2.close();

        // Make sure reader 1 is unchanged since it was open earlier
        assertEquals("after delete 1", 100, reader1.docFreq(searchTerm1));
        assertEquals("after delete 1", 100, reader1.docFreq(searchTerm2));
        assertEquals("after delete 1", 100, reader1.docFreq(searchTerm3));
        assertTermDocsCount("after delete 1", reader1, searchTerm1, 100);
        assertTermDocsCount("after delete 1", reader1, searchTerm2, 100);
        assertTermDocsCount("after delete 1", reader1, searchTerm3, 100);


        // ATTEMPT TO DELETE FROM STALE READER
        // delete documents containing term: bbb
        try {
            reader1.delete(searchTerm2);
            fail("Delete allowed from a stale index reader");
        } catch (IOException e) {
            /* success */
        }

        // RECREATE READER AND TRY AGAIN
        reader1.close();
        reader1 = IndexReader.open(dir);
        assertEquals("reopened", 100, reader1.docFreq(searchTerm1));
        assertEquals("reopened", 100, reader1.docFreq(searchTerm2));
        assertEquals("reopened", 100, reader1.docFreq(searchTerm3));
        assertTermDocsCount("reopened", reader1, searchTerm1, 0);
        assertTermDocsCount("reopened", reader1, searchTerm2, 100);
        assertTermDocsCount("reopened", reader1, searchTerm3, 100);

        reader1.delete(searchTerm2);
        assertEquals("deleted 2", 100, reader1.docFreq(searchTerm1));
        assertEquals("deleted 2", 100, reader1.docFreq(searchTerm2));
        assertEquals("deleted 2", 100, reader1.docFreq(searchTerm3));
        assertTermDocsCount("deleted 2", reader1, searchTerm1, 0);
        assertTermDocsCount("deleted 2", reader1, searchTerm2, 0);
        assertTermDocsCount("deleted 2", reader1, searchTerm3, 100);
        reader1.close();

        // Open another reader to confirm that everything is deleted
        reader2 = IndexReader.open(dir);
        assertEquals("reopened 2", 100, reader2.docFreq(searchTerm1));
        assertEquals("reopened 2", 100, reader2.docFreq(searchTerm2));
        assertEquals("reopened 2", 100, reader2.docFreq(searchTerm3));
        assertTermDocsCount("reopened 2", reader2, searchTerm1, 0);
        assertTermDocsCount("reopened 2", reader2, searchTerm2, 0);
        assertTermDocsCount("reopened 2", reader2, searchTerm3, 100);
        reader2.close();

        dir.close();
    }
#endif

@end
