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
     *     [create] is NO if adding new documents into index data.
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
          field = [[LCField alloc] initWithName: @"content"
                                   string: [NSString stringWithContentsOfFile: file]
                                   store: LCStore_NO
                                   index: LCIndex_Tokenized];
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
      
      LCTerm *term = [[LCTerm alloc] initWithField: @"content"
                                              text: text];
      LCTermQuery *tq = [[LCTermQuery alloc] initWithTerm: term];
      [bq addQuery: tq occur: occur];
    }
    printf("\nQuery: %s\n", [[bq description] cString]);

    /* <9> Use LCIndexSearcher to search with LCQuery */
    LCIndexSearcher *searcher = [[LCIndexSearcher alloc] initWithDirectory: store];

    /* <9.1> shows document frequency */
    if (showDetails)
    {
      NSArray *clauses = [bq clauses];
      int j;
      for (j = 0; j < [clauses count]; j++)
      {
        /* Only work for term query */
        id query = [[clauses objectAtIndex: j] query];
        if (![query isKindOfClass: [LCTermQuery class]])
          continue;
        LCTerm *term = [(LCTermQuery *)query term];
        LCIndexReader *reader = [searcher indexReader];
        printf("\t- Term: %s\n", [[term description] cString]);
        printf("\t\t document frequency: %ld\n", [reader documentFrequency: term]);
      }
    }

    LCHits *hits = [searcher search: bq];

    /* <10> Retrive LCDocument from search results (LCHits) */
    int n = [hits count];
    printf("\n=== %d files found ===\n", n);

    /* <11> Display search results */
    for (i = 0; i < n; i++)
    {
      LCDocument *doc = [hits document: i];
      printf("%d: %s\n", i+1, [[doc stringValue: @"filename"] cString]);

      /* <12> Shows details if requested */
      if (showDetails)
      {
	printf("\t- score: %f\n", [hits score: i]);
        printf("\t- identifier: %d\n", [hits identifier: i]);
        /* <12.1> Get weight
        id <LCWeight> weight = [bq weight: searcher];
        printf("\t- weight: %s\n", [[[weight explain: [searcher indexReader]
                                          document: [hits identifier: i]] description] cString]);
        */
        /* <12.2> Get scorer 
        LCScorer *scorer = [weight scorer: [searcher indexReader]];
        printf("\t- scorer: %s\n", [[[scorer explain: [hits identifier: i]] description] cString]);
        */
        /* <12.3> Shows term frequency and positions  in each document */
        NSArray *clauses = [bq clauses];
        int j;
        for (j = 0; j < [clauses count]; j++)
        {
          /* Only work for term query */
          id query = [[clauses objectAtIndex: j] query];
          if (![query isKindOfClass: [LCTermQuery class]])
            continue;
          LCTerm *term = [(LCTermQuery *)query term];
          LCIndexReader *reader = [searcher indexReader];
#if 0 /* Use either LCTermDocuments or LCTermPositions */
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
          id <LCTermPositions> tp = [reader termPositionsWithTerm: term];
          while([tp next])
          if ([tp document] == [hits identifier: i])
          {
            printf("\t- term: %s\n", [[term description] cString]);
            printf("\t\t- term frequency: %ld\n", [tp frequency]);
            int k, kcount = [tp frequency];
            for (k = 0; k < kcount; k++)    
              printf("\t\t\t- term position: %d\n", [tp nextPosition]);
          }
#endif
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
}
