#include <Foundation/Foundation.h>
#include <LuceneKit/LuceneKit.h>
#include <LuceneKit/GNUstep/GNUstep.h>

static BOOL inMemory = YES;
static BOOL showDetails = NO;
static NSString *source;
static id <LCDirectory> store;
static LCAnalyzer *analyzer;
static LCIndexWriter *writer;
static NSFileManager *manager;
static NSMutableArray *args;
static NSString *CONTENT = @"content";

void show_help();
BOOL process_args(int argc, const char *argv[]);
void explain_details();

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    manager = [NSFileManager defaultManager];

    ASSIGN(source, @"./");
    if (process_args(argc, argv) != YES) return 0;

    /* <1> Decide where to put index data, either in memory (LCRAMDirectory)
     *     or on file system (LCFSDirectory).
     */
    if (inMemory)
    {
      ASSIGN(store, [[LCRAMDirectory alloc] init]);
    }
    else
    {
      ASSIGN(store, [[LCFSDirectory alloc] initWithPath: [[manager currentDirectoryPath] stringByAppendingPathComponent: @"LuceneKit_Index"] create: YES]);
    }

    /* <2> Decide which analyzer to use (<Lucene/Analysis/Analysis.h>) */
    analyzer = [[LCSimpleAnalyzer alloc] init];

    /* <3> Initiate LCIndexWriter 
     *     [create] is NO if adding new documents into existed index data.
     */
    writer = [[LCIndexWriter alloc] initWithDirectory: store
                                             analyzer: analyzer
                                               create: YES];

    /* <4> Convert each entity (document, record, etc) into each LCDocument.
     *     Each property (file name, email address, etc) 
     *     is a LCField in LCDocument
     */
    NSDirectoryEnumerator *de = [manager enumeratorAtPath: source];
    NSString *file;
    while ((file = [de nextObject])) {
      /* Only deal with text file */
      if ([[file pathExtension] isEqualToString: @"txt"])
        {
          /* Build complete path by appending file name to 'source' */
          file = [source stringByAppendingPathComponent: file];

          LCDocument *doc = [[LCDocument alloc] init];
          /* <5> Add each LCField into LCDocument */
          /* Filename is a keyword. Stored and Untokenized. */
          LCField *field = [[LCField alloc] initWithName: @"filename"
                                            string: file
                                            store: LCStore_YES
                                            index: LCIndex_Untokenized];
          [doc addField: field];
          /* Content, tokenized, but not stored. */
          field = [[LCField alloc] initWithName: CONTENT
                                   string: [NSString stringWithContentsOfFile: file]
                                   store: LCStore_NO
                                   index: LCIndex_Tokenized
                                   termVector: LCTermVector_WithPositionsAndOffsets];
          [doc addField: field];

          /* <6> Add each LCDocument into LCIndexWriter */
          [writer addDocument: doc];
        }
    }

    /* <7> Close LCIndexWriter. 
     *     The index data has been build.
     */
    [writer optimize]; // Not necessary
    [writer close];

    /* <8> Build query (LCQuery). */
    LCBooleanQuery *bq = [[LCBooleanQuery alloc] init];
    int i;
    for (i = 0; i < [args count]; i++)
    {
      /* <8.1> Check for boolean query. */
      LCOccurType occur = LCOccur_SHOULD;
      NSString *text = nil;
      if ([[args objectAtIndex: i] hasPrefix: @"+"]) {
        occur = LCOccur_MUST;
        ASSIGN(text, [[args objectAtIndex: i] substringFromIndex: 1]);
      } else if ([[args objectAtIndex: i] hasPrefix: @"-"]) {
        occur = LCOccur_MUST_NOT;
        ASSIGN(text, [[args objectAtIndex: i] substringFromIndex: 1]);
      } else {
        occur = LCOccur_SHOULD;
        ASSIGNCOPY(text, [args objectAtIndex: i]);
      }
   
      LCTerm *term;
      LCQuery *tq;
      if ([text hasSuffix: @"*"]) 
      {
        /* <8.2> Prefix Query */
        term = [[LCTerm alloc] initWithField: CONTENT
                                        text: [text substringToIndex: [text length]-1]];
        tq = [[LCPrefixQuery alloc] initWithTerm: term];
      } 
      else
      { 
        /* <8.3> Term Query */
        term = [[LCTerm alloc] initWithField: CONTENT
                                                text: text];
        tq = [[LCTermQuery alloc] initWithTerm: term];
      }
      [bq addQuery: tq occur: occur];
      DESTROY(term);
      DESTROY(tq);
    }
    printf("\nQuery: %s\n", [[bq description] cString]);

    /* <9> Initiate LCIndexSearcher. */
    LCIndexSearcher *searcher = [[LCIndexSearcher alloc] initWithDirectory: store];

    /* <9.1> Show document frequency through LCIndexReader. */
    if (showDetails)
    {
      NSArray *clauses = [bq clauses];
      int j;
      for (j = 0; j < [clauses count]; j++)
      {
        /* Only work for term query */
        id query = [(LCBooleanClause *)[clauses objectAtIndex: j] query];
        if (![query isKindOfClass: [LCTermQuery class]])
          continue;
        LCTerm *term = [(LCTermQuery *)query term];
        LCIndexReader *reader = [searcher indexReader];
        printf("\t- Term: %s\n", [[term description] cString]);
        printf("\t\t document frequency: %ld\n", [reader documentFrequency: term]);
      }
    }

    /* <10> Search with query. */
    LCHits *hits = [searcher search: bq];
    int n = [hits count];
    printf("\n=== %d files found ===\n", n);

    /* <11> Display search results */
    for (i = 0; i < n; i++)
    {
      LCDocument *doc = [hits document: i];
      printf("%d: %s\n", i+1, [[doc stringForField: @"filename"] cString]);

      /* <12> Shows details if requested */
      if (showDetails)
      {
        /* <12.1> Show score of each document */
	printf("\t- score: %f\n", [hits score: i]);

        /* <12.2> Show internal identifier of each document */
        printf("\t- identifier: %d\n", [hits identifier: i]);

        /* <12.3> Show weight information 
        id <LCWeight> weight = [bq weight: searcher];
        printf("\t- weight: %s\n", [[[weight explain: [searcher indexReader]
                                          document: [hits identifier: i]] description] cString]);
        */
        /* <12.4> Show scorer information
        LCScorer *scorer = [weight scorer: [searcher indexReader]];
        printf("\t- scorer: %s\n", [[[scorer explain: [hits identifier: i]] description] cString]);
        */
        /* <12.5> Show details associated with each term */
        NSArray *clauses = [bq clauses];
        int j;
        for (j = 0; j < [clauses count]; j++)
        {
          /* Only work for term query */
          id query = [(LCBooleanClause *)[clauses objectAtIndex: j] query];
          if (![query isKindOfClass: [LCTermQuery class]])
            continue;
          LCTerm *term = [(LCTermQuery *)query term];
          LCIndexReader *reader = [searcher indexReader];
#if 0 
          /* <12.5.1> Show term frequency only */
          id <LCTermDocuments> td = [reader termDocumentsWithTerm: term];
          while([td next])
          {
            if ([td document] == [hits identifier: i])
            {
              printf("\t- term: %s\n", [[term description] cString]);
              printf("\t\t- term frequency: %ld\n", [td frequency]);
            }
          }
#else
          /* <12.5.2> Shows term frequency and positions. */
          id <LCTermPositions> tp = [reader termPositionsWithTerm: term];
          while([tp hasNextDocument])
          if ([tp document] == [hits identifier: i])
          {
            printf("\t- term: %s\n", [[term description] cString]);
            printf("\t\t- term frequency: %ld\n", [tp frequency]);
            int k, kcount = [tp frequency];
            for (k = 0; k < kcount; k++)    
              printf("\t\t\t- term position #%d: %d\n", k+1, [tp nextPosition]);
          }
#endif
          /* <12.5.3> Use term vector. */
          id tv = [reader termFrequencyVector: [hits identifier: i]
                                           field: CONTENT];
          if ([tv conformsToProtocol: @protocol(LCTermPositionVector)])
          {
            id <LCTermPositionVector> termVector = (id <LCTermPositionVector>) tv;
            int index = [termVector indexOfTerm: [term text]];

            /* <12.5.3.1> Shows term positions.
             * Not useful here since term positions can be obtained
             * through -termPositionsWithTerm (LCIndexReader).
             * NSArray *positions = [termVector termPositions: index];
             */
 
            /* <12.5.3.2> Shows term offsets. */
            NSArray *offsets = [termVector termOffsets: index];
            int n;
            for (n = 0; n < [offsets count]; n++)
            {
              LCTermVectorOffsetInfo *info = [offsets objectAtIndex: n];
              printf("\t\t\t- term offset #%d: %d-%d\n", n+1, [info startOffset], [info endOffset]);;
            }
          }
          else
          {
            /* <12.5.3.3> Shows term frequency 
             * Not useful here since term frequency can be obtained
             * through -termPositionsWithTerm: or -termDocumentsWithTerm:
             * (LCIndexReader).
             */
          }
	}
      }
    }

    if (showDetails)
    {
      explain_details();
    }

    RELEASE(pool);
    return 0;
}

void explain_details()
{
  printf("\n===Explanation===\n");
  printf("* Term: each term contains a field name and a text for search.\n");
  printf("* Document Frequency: the number of documents containing a given term.\n");
  printf("* Score: the relevance of each document based on a given query.\n"); 
  printf("* Identifier: the internal document identifier, which often changes.\n");
  printf("* Term Frequency: the frequency of a given term contained in each dodocument.\n");
  printf("* Term Position: the position of a given term in each document,\n\tdetermied by analyzer and usually based on word.\n");
  printf("* Term Offset: the offset of a given term in each document,\n\tbased on character(byte).\n");
}

BOOL process_args(int argc, const char *argv[])
{
    if (argc < 2) {
      printf("Error: need query terms.\n\n");
      show_help();
      return NO;
    }

    int i;
    args = [[NSMutableArray alloc] init];

    for (i = 0; i < argc-1; i++)
    {
      [args addObject: [NSString stringWithCString: argv[i+1]]];
    }

    if ([[args objectAtIndex: 0] isEqualToString: @"--fs"])
    {
      inMemory = NO;
      [args removeObjectAtIndex: 0];
      /* Check whether LuceneKit_Index exists */
      if ([manager fileExistsAtPath: @"./LuceneKit_Index"])
      {
         //NSLog(@"Remove ./LuceneKit_Index/");
         [manager removeFileAtPath: @"./LuceneKit_Index" handler: nil];
      }
    }

    if ([args count] < 1) {
      printf("Error: need query terms.\n\n");
      show_help();
      return NO;
    }

    if ([[args objectAtIndex: 0] isEqualToString: @"--path"])
    {
      if ([args count] < 2) {
        printf("Error: need path.\n\n");
        show_help();
        return NO;
      }
      ASSIGN(source, [[args objectAtIndex: 1] stringByStandardizingPath]);
    
      BOOL isDir;
      if ([manager fileExistsAtPath: source isDirectory: &isDir] == NO)
      {
        printf("Error: %s does not exist.\n\n", [source cString]);
        show_help();
        return NO;
      }
      if (isDir == NO)
      {
        printf("Error: %s is not a directory.\n\n", [source cString]);
        show_help();
        return NO;
      }

      [args removeObjectAtIndex: 0];
      [args removeObjectAtIndex: 0];
    }

    if ([args count] < 1) {
      printf("Error: need query terms.\n\n");
      show_help();
      return NO;
    }

    if ([[args objectAtIndex: 0] isEqualToString: @"--details"])
    {
      showDetails = YES;
      [args removeObjectAtIndex: 0];
    }
  
    if ([args count] < 1) {
      printf("Error: need query terms.\n\n");
      show_help();
      return NO;
    }

    return YES;
}

void show_help()
{
  printf("Usage: LuceneKitExample [--fs] [--path path] [--details] query...\n");
  printf("--fs: Write index files on ./Lucene_Index/\n");
  printf("      Default: write in memory.\n");
  printf("      Note: the old ./Lucene_Index/ will be removed\n");
  printf("--path PATH: Index and search text file (.txt) under PATH.\n");
  printf("             Default: under current directory (./).\n");
  printf("--details: show details of query result.\n");
  printf("query: search terms. Use '+' for must-have, '-' for must-not-have.\n");
  printf("Example: zoo -elephant +panda\n");
  printf("No space and quotation allowed, ex. +\"great panda \"\n");
  printf("Due to the analyzer used, all search terms must be lowercase.\n");
  printf("Prefix search are supported, but no details.\n");
  printf("Example: gnu\\* -gorm\n");
}
