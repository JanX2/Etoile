#include <Foundation/Foundation.h>
#include <LuceneKit/LuceneKit.h>
#include <LuceneKit/GNUstep/GNUstep.h>

static BOOL inMemory = YES;
static NSString *source;
static id <LCDirectory> store;
static LCAnalyzer *analyzer;
static LCIndexWriter *writer;
static NSFileManager *manager;
static NSMutableArray *args;

void show_help();
BOOL process_args(int argc, const char *argv[]);

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
      LCOccurType occur;
      NSString *text;
      if ([[args objectAtIndex: i] hasPrefix: @"+"]) {
        occur = LCOccur_MUST;
        ASSIGN(text, [[args objectAtIndex: i] substringFromIndex: 1]);
      } else if ([[args objectAtIndex: i] hasPrefix: @"+"]) {
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
    NSLog(@"Query: %@", bq);

    /* <9> Use LCIndexSearcher to search with LCQuery */
    LCIndexSearcher *searcher = [[LCIndexSearcher alloc] initWithDirectory: store];
    LCHits *hits = [searcher search: bq];

    /* <10> Retrive LCDocument from search results (LCHits) */
    int n = [hits count];
    printf("=== %d files found ===\n", n);

    /* <11> Display search results */
    for (i = 0; i < n; i++)
    {
      LCDocument *doc = [hits document: i];
      printf("%d: %s\n", i+1, [[doc stringValue: @"filename"] cString]);
    }

    RELEASE(pool);
    return 0;
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

    return YES;
}

void show_help()
{
  printf("Usage: LuceneKitExample [--fs] [--path path] query...\n");
  printf("--fs: Write index files on ./Lucene_Index/\n");
  printf("      Default: write in memory.\n");
  printf("      Note: the old ./Lucene_Index/ will be removed\n");
  printf("--path PATH: Index and search text file (.txt) under PATH.\n");
  printf("             Default: under current directory (./).\n");
  printf("query: search terms. Use '+' for must-have, '-' for must-not-have.\n");
  printf("Example: zoo -elephant +panda\n");
  printf("No space and quotation allowed, ex. +\"great panda \"\n");
  printf("Due to the analyzer used, all search terms must be lowercase.\n");
}
