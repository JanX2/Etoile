#include "Index/LCDocumentWriter.h"
#include "Index/LCTermVectorOffsetInfo.h"
#include "Index/LCTerm.h"
#include "Index/LCTermbuffer.h"
#include "Index/LCTermInfo.h"
#include "Index/LCTermInfosWriter.h"
#include "Index/LCTermVectorsWriter.h"
#include "Index/LCFieldInfos.h"
#include "Index/LCFieldInfo.h"
#include "Index/LCFieldsWriter.h"
#include "Document/LCDocument.h"
#include "Document/LCField.h"
#include "Analysis/LCAnalyzer.h"
#include "Index/LCIndexWriter.h"
#include "Search/LCSimilarity.h"
#include "Java/LCStringReader.h"
#include "GNUstep/GNUstep.h"

@implementation LCPosting

- (id) initWithTerm: (LCTerm *) t
       position: (long) position
       offset: (LCTermVectorOffsetInfo *) offset
{
  self = [super init];
  ASSIGN(term, t);
  freq = 1;
  positions = [[NSMutableArray alloc] initWithObjects: [NSNumber numberWithLong: position], nil];
  if(offset != nil){
    offsets = [[NSMutableArray alloc] initWithObjects: offset, nil];
  }
  else
  {
      offsets = nil;
  }
  return self;
}

- (NSComparisonResult) compareTo: (LCPosting *) other
{
  return [[self term] compare: [other term]];
}

- (LCTerm *) term { return term; }
- (long) freq { return freq; }
- (NSMutableArray *) positions { return positions; }
- (NSMutableArray *) offsets { return offsets; }
- (void) setFreq: (long) f { freq = f; }
- (void) setPositions: (NSArray *) p { [positions setArray: p]; }
- (void) setOffsets: (NSArray *) o { [offsets setArray: o]; }

@end

static NSString *LCFieldLength = @"LCFieldLength";
static NSString *LCFieldPosition = @"LCFieldPosition";
static NSString *LCFieldOffset = @"LCFieldOffsets";
static NSString *LCFieldBoost = @"LCFieldBoost";

@implementation LCDocumentWriter
- (id) init
{
  self = [super init];
  termIndexInterval = DEFAULT_TERM_INDEX_INTERVAL;
  termBuffer = [[LCTerm alloc] init];
  postingTable = [[NSMutableDictionary alloc] init];
  return self;
}

  /** This ctor used by test code only.
   *
   * @param directory The directory to write the document information to
   * @param analyzer The analyzer to use for the document
   * @param similarity The Similarity function
   * @param maxFieldLength The maximum number of tokens a field may have
   */ 
- (id) initWithDirectory: (id <LCDirectory>) dir
       analyzer: (LCAnalyzer *) ana
              similarity: (LCSimilarity *) sim
	             maxFieldLength: (int) max
{
  self = [self init];
  ASSIGN(directory, dir);
  ASSIGN(analyzer, ana);
  ASSIGN(similarity, sim);
  maxFieldLength = max;
  return self;
}

- (id) initWithDirectory: (id <LCDirectory>) dir
       analyzer: (LCAnalyzer *) ana
              indexWriter: (LCIndexWriter *) iw
{
  self = [self init];
  ASSIGN(directory, dir);
  ASSIGN(analyzer, ana);
  ASSIGN(similarity, [iw similarity]);
  maxFieldLength = [iw maxFieldLength];
  termIndexInterval = [iw termIndexInterval];
  return self;
}

- (void) addDocument: (NSString *) segment
         document: (LCDocument *) doc
{
  // write field names
  fieldInfos = [[LCFieldInfos alloc] init];
  [fieldInfos addDocument: doc];
  [fieldInfos write: directory name: [segment stringByAppendingPathExtension: @"fnm"]];

    // write field values
  LCFieldsWriter *fieldsWriter = [[LCFieldsWriter alloc] initWithDirectory: directory segment: segment fieldInfos: fieldInfos];
  [fieldsWriter addDocument: doc];
  [fieldsWriter close];

    // invert doc into postingTable
  [postingTable removeAllObjects]; // clear postingTable
  fieldsCache = [[NSMutableArray alloc] init];
  fieldBoosts = [[NSMutableArray alloc] init];  // init fieldBoosts
  int i, count = [fieldInfos size];
  for(i = 0; i < count; i++)
    [fieldBoosts addObject: [NSNumber numberWithFloat: [doc boost]]];

  [self invertDocument: doc];
    // sort postingTable into an array
  NSArray *postings = [self sortPostingTable];
    // write postings
    [self writePostings: postings segment: segment];

    // write norms of indexed fields
    [self writeNorms: segment];

  }

  // Tokenizes the fields of a document into Postings.
- (void) invertDocument: (LCDocument *) doc
{
  NSEnumerator *fields = [doc fieldEnumerator];
  LCField *field;
  NSString *fieldName;
  while ((field = [fields nextObject]))
  {
    fieldName = [field name];
    int fieldNumber = [fieldInfos fieldNumber: fieldName];
    long length = 0, position = 0, offset = 0;
    if (fieldNumber < [fieldsCache count])
    {
      length = [[[fieldsCache objectAtIndex: fieldNumber] objectForKey: LCFieldLength] longValue];
      position = [[[fieldsCache objectAtIndex: fieldNumber] objectForKey: LCFieldPosition] longValue];
      offset = [[[fieldsCache objectAtIndex: fieldNumber] objectForKey: LCFieldOffset] longValue];
    }

      if ([field isIndexed]) {
        if (![field isTokenized]) {		  // un-tokenized field
          NSString *stringValue = [field stringValue];
          if([field isOffsetWithTermVectorStored])
	    {
	      LCTermVectorOffsetInfo *tvoi = [[LCTermVectorOffsetInfo alloc] initWithStartOffset: offset endOffset: offset + [stringValue length]];
              [self addField: fieldName
		    text: stringValue
		    position: position++
		    offset: tvoi];
	    }
          else
            [self addField: fieldName
		    text: stringValue
		    position: position++
		    offset: nil];
          offset += [stringValue length];
          length++;
          } 
	else 
          {
            id <LCReader> reader;			  // find or make Reader
            if ([field readerValue] != nil)
              reader = [field readerValue];
            else if ([field stringValue] != nil)
              reader = [[LCStringReader alloc] initWithString: [field stringValue]];
            else
	    {
              NSLog(@"field must have either String or Reader value");
	      return;
	    }

            // Tokenize field and add to postingTable
            LCTokenStream *stream = [analyzer tokenStreamWithField: fieldName
	  	                 reader: reader];
            LCToken *t, *lastToken = nil;

            for (t = [stream next]; t != nil; t = [stream next]) {
              position += ([t positionIncrement] - 1);
              
              if([field isOffsetWithTermVectorStored])
	        {
	          LCTermVectorOffsetInfo *tvoi = [[LCTermVectorOffsetInfo alloc] initWithStartOffset: [t startOffset] endOffset: offset + [t endOffset]];
                  [self addField: fieldName
		    text: [t termText]
		    position: position++
		    offset: tvoi];
	        }
              else
                [self addField: fieldName
		    text: [t termText]
		    position: position++
		    offset: nil];
              
              lastToken = t;
              if (++length > maxFieldLength) {
                break;
              }
            }
            
            if(lastToken != nil)
              offset += [lastToken endOffset] + 1;
            
            [stream close];
          }

	NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys: 
		[NSNumber numberWithLong: length], LCFieldLength,
		[NSNumber numberWithLong: position], LCFieldPosition,
		[NSNumber numberWithLong: offset], LCFieldOffset,
		nil];
	if (fieldNumber < [fieldsCache count])
	{
	  [fieldsCache replaceObjectAtIndex: fieldNumber withObject: d];
	}
	else
	  [fieldsCache addObject: d];

	float newBoosts = [[fieldBoosts objectAtIndex: fieldNumber] floatValue] * [field boost];
	[fieldBoosts replaceObjectAtIndex: fieldNumber withObject: [NSNumber numberWithFloat: newBoosts]];
      } /* if tokenized */
      else
      {
        [fieldsCache addObject: @""]; // fill the void
      }
    } /* while */
  }

  //private final Term termBuffer = new Term("", ""); // avoid consing

- (void) addField: (NSString *) field
             text: (NSString *) text
	              position: (long) position
		offset: (LCTermVectorOffsetInfo *) offset
{
  [termBuffer setField: field];
  [termBuffer setText: text];
    //System.out.println("Offset: " + offset);
  LCPosting *ti = (LCPosting*) [postingTable objectForKey: termBuffer];
    if (ti != nil) {				  // word seen before
      int freq = [ti freq];
      if ([[ti positions] count] == freq) {	  // positions array is full

        [[ti positions] addObject: [NSNumber numberWithLong: position]];
      }
      else 
        [[ti positions] replaceObjectAtIndex: freq withObject: [NSNumber numberWithLong: position]];		  // add new position

      if (offset != nil) {
        if ([[ti offsets] count]== freq){
          [[ti offsets] addObject: offset];
          }
          else

        [[ti offsets] replaceObjectAtIndex: freq withObject: offset];
      }
      [ti setFreq: (freq + 1)];			  // update frequency
    } else {					  // word not seen before
      LCTerm *term = [[LCTerm alloc] initWithField: field text: text];
      [postingTable setObject: [[LCPosting alloc] initWithTerm: term
	      					position: position
						offset: offset]
		    forKey: term];
    }
  }

- (NSArray *) sortPostingTable
{
    // copy postingTable into an array
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSEnumerator *e = [postingTable objectEnumerator];
    id object;
    while((object = [e nextObject]))
    {
      [array addObject: object];
    }

    // sort the array
    [array sortUsingSelector: @selector(compareTo:)];

    return array;
}

#if 0
- (void) quickSort: (NSMutableArray *) postings
         low: (int) lo
	 high: (int) hi
{
  if (lo >= hi)
    return;

  int mid = (lo + hi) / 2;

  if ([[[postings objectAtIndex: lo] term] compareTo: [[postings objectAtIndex: mid] term] == NSOrderedDescending])
    Posting tmp = postings[lo];
    postings[lo] = postings[mid];
    postings[mid] = tmp;
  }

    if (postings[mid].term.compareTo(postings[hi].term) > 0) {
      Posting tmp = postings[mid];
      postings[mid] = postings[hi];
      postings[hi] = tmp;

      if (postings[lo].term.compareTo(postings[mid].term) > 0) {
        Posting tmp2 = postings[lo];
        postings[lo] = postings[mid];
        postings[mid] = tmp2;
      }
    }

    int left = lo + 1;
    int right = hi - 1;

    if (left >= right)
      return;

    Term partition = postings[mid].term;

    for (; ;) {
      while (postings[right].term.compareTo(partition) > 0)
        --right;

      while (left < right && postings[left].term.compareTo(partition) <= 0)
        ++left;

      if (left < right) {
        Posting tmp = postings[left];
        postings[left] = postings[right];
        postings[right] = tmp;
        --right;
      } else {
        break;
      }
    }

    quickSort(postings, lo, left);
    quickSort(postings, left + 1, hi);
  }
#endif
- (void) writePostings: (NSArray *) postings 
         segment: (NSString *) segment
{
  LCIndexOutput *freq = nil, *prox = nil;
  LCTermInfosWriter *tis = nil;
  LCTermVectorsWriter *termVectorWriter = nil;

  //open files for inverse index storage
  NSString *name = [segment stringByAppendingPathExtension: @"frq"];
  freq = [directory createOutput: name];
  name = [segment stringByAppendingPathExtension: @"prx"];
  prox = [directory createOutput: name];
  tis = [[LCTermInfosWriter alloc] initWithDirectory: directory
	     segment: segment
	     fieldInfos: fieldInfos
             interval: termIndexInterval];
  LCTermInfo *ti = [[LCTermInfo alloc] init];
  NSString *currentField = nil;

  int i;
  for (i = 0; i < [postings count]; i++) {
    LCPosting *posting = [postings objectAtIndex: i];

    // add an entry to the dictionary with pointers to prox and freq files
    [ti setDocFreq: 1];
    [ti setFreqPointer: [freq filePointer]];
    [ti setProxPointer: [prox filePointer]];
    [ti setSkipOffset: -1];
    [tis addTerm: [posting term] termInfo: ti];

    // add an entry to the freq file
    long postingFreq = [posting freq];
    if (postingFreq == 1)				  // optimize freq=1
    {
      [freq writeVInt: 1];			  // set low bit of doc num.
      }
    else {
      [freq writeVInt: 0];			  // the document number
      [freq writeVInt: postingFreq];			  // frequency in doc
          }

    long lastPosition = 0;			  // write positions
    NSArray *positions = [posting positions];
    int j;
    for (j = 0; j < postingFreq; j++) {		  // use delta-encoding
      long position = [[positions objectAtIndex: j] longValue];
      [prox writeVInt: position - lastPosition];
      lastPosition = position;
    }

    // check to see if we switched to a new field
    NSString *termField = [[posting term] field];
    if (currentField != termField) {
      // changing field - see if there is something to save
      currentField = termField;
      LCFieldInfo *fi = [fieldInfos fieldInfo: currentField];
      if ([fi isTermVectorStored]) {
        if (termVectorWriter == nil) {
  	  termVectorWriter = [[LCTermVectorsWriter alloc] initWithDirectory: directory segment: segment fieldInfos: fieldInfos];
	  [termVectorWriter openDocument];
        }
        [termVectorWriter openField: currentField];

      } else if (termVectorWriter != nil) {
        [termVectorWriter closeField];
      }
    }
    if (termVectorWriter != nil && [termVectorWriter isFieldOpen]) {
      [termVectorWriter addTerm: [[posting term] text]
  	         freq: postingFreq
		 positions: [posting positions]
		 offsets: [posting offsets]];
    }
  }
  if (termVectorWriter != nil)
        [termVectorWriter closeDocument];

  // make an effort to close all streams we can but remember and re-throw
  // the first exception encountered in this process
  if (freq) [freq close];
  if (prox) [prox close];
  if (tis) [tis close];
  if (termVectorWriter) [termVectorWriter close];
}

- (void) writeNorms: (NSString *) segment
{
  int n;
  for(n = 0; n < [fieldInfos size]; n++){
    LCFieldInfo *fi = [fieldInfos fieldInfoWithNumber: n];
    if([fi isIndexed]){
      float norm = [[fieldBoosts objectAtIndex: n] floatValue] * [similarity lengthNorm: [fi name] numberOfTokens: [[[fieldsCache objectAtIndex: n] objectForKey: LCFieldLength] longValue]];
      NSString *name = [NSString stringWithFormat: @"%@.f%d", segment, n];
      LCIndexOutput *norms = [directory createOutput: name];
      [norms writeByte: [LCSimilarity encodeNorm: norm]];
      [norms close];
    }
  }
}
  
  /** If non-null, a message will be printed to this if maxFieldLength is reached.
   */
#if 0
  void setInfoStream(PrintStream infoStream) {
    this.infoStream = infoStream;
  }

}
#endif

@end

#ifdef HAVE_UKTEST

#include <UnitKit/UnitKit.h>
#include "Store/LCRAMDirectory.h"
#include "Analysis/LCWhitespaceAnalyzer.h"
#include "Index/LCSegmentReader.h"
#include "Index/LCSegmentinfo.h"
#include "TestDocHelper.h"

@interface TestDocumentWriter: NSObject <UKTest>
@end

@implementation TestDocumentWriter
- (void) testDocumentWriter
{
  LCRAMDirectory *dir = [[LCRAMDirectory alloc] init];
  LCDocument *testDoc = [[LCDocument alloc] init];
  [TestDocHelper setupDoc: testDoc];
  UKNotNil(dir);
  LCAnalyzer *analyzer = [[LCWhitespaceAnalyzer alloc] init];
  LCSimilarity *similarity= [LCSimilarity defaultSimilarity];
  LCDocumentWriter *writer = [[LCDocumentWriter alloc] initWithDirectory: dir
	  analyzer: analyzer similarity: similarity maxFieldLength: 50];
  UKNotNil(writer);
  [writer addDocument: @"test" document: testDoc];

#if 0
  //After adding the document, we should be able to read it back in
  LCSegmentReader *reader = [LCSegmentReader segmentReaderWithInfo: [[LCSegmentInfo alloc] initWithName: @"test" numberOfDocuments: 1 directory: dir]];
  UKNotNil(reader);
  LCDocument *doc = [reader document: 0];
  UKNotNil(doc);

  //System.out.println("Document: " + doc);
  NSArray *fields = [doc fieldsWithName: @"textField2"];
  UKNotNil(fields);
  UKIntsEqual(1, [fields count]);
  UKStringsEqual([TestDocHelper FIELD_2_TEXT], [[fields objectAtIndex: 0] stringValue]);
  UKTrue([[fields objectAtIndex: 0] isTermVectorStored]);

  fields = [doc fieldsWithName: @"textField1"];
  UKNotNil(fields);
  UKIntsEqual(1, [fields count]);
  UKStringsEqual([TestDocHelper FIELD_1_TEXT], [[fields objectAtIndex: 0] stringValue]);
  UKFalse([[fields objectAtIndex: 0] isTermVectorStored]);

  fields = [doc fieldsWithName: @"keyField"];
  UKNotNil(fields);
  UKIntsEqual(1, [fields count]);
  UKStringsEqual([TestDocHelper KEYWORD_TEXT], [[fields objectAtIndex: 0] stringValue]);
  #endif
}
@end
#endif /* HAVE_UKTEST */
