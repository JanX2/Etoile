#include "LuceneKit/Index/LCDocumentWriter.h"
#include "LuceneKit/Index/LCTermVectorOffsetInfo.h"
#include "LuceneKit/Index/LCTerm.h"
#include "LuceneKit/Index/LCTermbuffer.h"
#include "LuceneKit/Index/LCTermInfo.h"
#include "LuceneKit/Index/LCTermInfosWriter.h"
#include "LuceneKit/Index/LCTermVectorsWriter.h"
#include "LuceneKit/Index/LCFieldInfos.h"
#include "LuceneKit/Index/LCFieldInfo.h"
#include "LuceneKit/Index/LCFieldsWriter.h"
#include "LuceneKit/Document/LCDocument.h"
#include "LuceneKit/Document/LCField.h"
#include "LuceneKit/Analysis/LCAnalyzer.h"
#include "LuceneKit/Index/LCIndexWriter.h"
#include "LuceneKit/Search/LCSimilarity.h"
#include "LuceneKit/Java/LCStringReader.h"
#include "GNUstep.h"

@implementation LCPosting

- (id) initWithTerm: (LCTerm *) t
       position: (int) position
       offset: (LCTermVectorOffsetInfo *) offset
{
  self = [super init];
  ASSIGN(term, t);
  freq = 1;
  positions = [[NSMutableArray alloc] initWithObjects: [NSNumber numberWithInt: position], nil];
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
  return [[self term] compareTo: [other term]];
}

- (LCTerm *) term { return term; }
- (int) freq { return freq; }
- (NSMutableArray *) positions { return positions; }
- (NSMutableArray *) offsets { return offsets; }
- (void) setFreq: (int) f { freq = f; }
- (void) setPositions: (NSArray *) p { [positions setArray: p]; }
- (void) setOffsets: (NSArray *) o { [offsets setArray: o]; }

@end

@implementation LCDocumentWriter
- (id) init
{
  self = [super init];
  termIndexInterval = DEFAULT_TERM_INDEX_INTERVAL;
  termBuffer = [[LCTermBuffer alloc] init];
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
  fieldLengths = [[NSMutableArray alloc] init];   // init fieldLengths
  fieldPositions = [[NSMutableArray alloc] init]; // init fieldPositions
  fieldOffsets = [[NSMutableArray alloc] init]; // init fieldOffsets

  fieldBoosts = [[NSMutableArray alloc] init];  // init fieldBoosts
  int i, count = [fieldInfos size];
  for(i = 0; i < count; i++)
    [fieldBoosts addObject: [NSNumber numberWithFloat: [doc boost]]];

  [self invertDocument: doc];

    // sort postingTable into an array
  NSArray *postings = [self sortPostingTable];

    /*
    for (int i = 0; i < postings.length; i++) {
      Posting posting = postings[i];
      System.out.print(posting.term);
      System.out.print(" freq=" + posting.freq);
      System.out.print(" pos=");
      System.out.print(posting.positions[0]);
      for (int j = 1; j < posting.freq; j++)
	System.out.print("," + posting.positions[j]);
      System.out.println("");
    }
    */

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

    int length = [[fieldLengths objectAtIndex: fieldNumber] intValue];     // length of field
    int position = [[fieldPositions objectAtIndex: fieldNumber] intValue]; // position in field
    int offset = [[fieldOffsets objectAtIndex: fieldNumber] intValue];       // offset field

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
        } else 
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
#if 0
                if (infoStream != null)
                  infoStream.println("maxFieldLength " +maxFieldLength+ " reached, ignoring following tokens");
#endif
                break;
              }
            }
            
            if(lastToken != nil)
              offset += [lastToken endOffset] + 1;
            
            [stream close];
        }

	[fieldLengths replaceObjectAtIndex: fieldNumber withObject: [NSNumber numberWithInt: length]]; 	  // save field length
	[fieldPositions replaceObjectAtIndex: fieldNumber withObject: [NSNumber numberWithInt: position]]; 	  // save field position
	float newBoosts = [[fieldBoosts objectAtIndex: fieldNumber] floatValue] * [field boost];
	[fieldBoosts replaceObjectAtIndex: fieldNumber withObject: [NSNumber numberWithFloat: newBoosts]];
	[fieldOffsets replaceObjectAtIndex: fieldNumber withObject: [NSNumber numberWithInt: offset]]; 	  
      }
    }
  }

  //private final Term termBuffer = new Term("", ""); // avoid consing

- (void) addField: (NSString *) field
             text: (NSString *) text
	              position: (int) position
		offset: (LCTermVectorOffsetInfo *) offset
{
  [termBuffer setField: field text: text];
    //System.out.println("Offset: " + offset);
  LCPosting *ti = (LCPosting*) [postingTable objectForKey: termBuffer];
    if (ti != nil) {				  // word seen before
      int freq = [ti freq];
      if ([[ti positions] count] == freq) {	  // positions array is full
        NSMutableArray *newPositions = [[NSMutableArray alloc] init];  // double size
        NSMutableArray *positions = [ti positions];
	int i;
        for (i = 0; i < freq; i++)		  // copy old positions to new
          [newPositions addObject: [positions objectAtIndex: i]];;
        [ti setPositions: newPositions];
      }
      [[ti positions] replaceObjectAtIndex: freq withObject: [NSNumber numberWithInt: position]];		  // add new position

      if (offset != nil) {
        if ([[ti offsets] count]== freq){
	  NSMutableArray *newOffsets;
	  NSArray *offsets = [ti offsets];
	  int i;
          for (i = 0; i < freq; i++)
          {
            [newOffsets addObject: [offsets objectAtIndex: i]];
          }
          [ti setOffsets: newOffsets];
        }
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
    [ti setDocFreq: 1 freqPointer: [freq filePointer]
	  proxPointer: [prox filePointer] skipOffset: -1];
    [tis addTerm: [posting term] termInfo: ti];

    // add an entry to the freq file
    int postingFreq = [posting freq];
    if (postingFreq == 1)				  // optimize freq=1
      [freq writeVInt: 1];			  // set low bit of doc num.
    else {
      [freq writeVInt: 0];			  // the document number
      [freq writeVInt: postingFreq];			  // frequency in doc
          }

    int lastPosition = 0;			  // write positions
    NSArray *positions = [posting positions];
    int j;
    for (j = 0; j < postingFreq; j++) {		  // use delta-encoding
      int position = [[positions objectAtIndex: j] intValue];
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
      float norm = [[fieldBoosts objectAtIndex: n] floatValue] * [similarity lengthNorm: [fi name] numberOfTokens: [[fieldLengths objectAtIndex: n] intValue]];
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
