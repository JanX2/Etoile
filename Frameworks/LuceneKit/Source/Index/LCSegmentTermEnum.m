#include "LuceneKit/Index/LCSegmentTermEnum.h"
#include "LuceneKit/Index/LCFieldInfos.h"
#include "LuceneKit/Index/LCTermInfo.h"
#include "LuceneKit/Index/LCTermInfosWriter.h"
#include "LuceneKit/Index/LCTermBuffer.h"
#include "LuceneKit/Store/LCIndexInput.h"
#include "GNUstep.h"

@implementation LCSegmentTermEnum

- (id) init
{
  self = [super init];
  position = -1;
  [self setTermBuffer: AUTORELEASE([[LCTermBuffer alloc] init])];
  [self setPrevBuffer: AUTORELEASE([[LCTermBuffer alloc] init])];
  termInfo = [[LCTermInfo alloc] init];
  indexPointer = 0;
  return self;
}

- (id) initWithIndexInput: (LCIndexInput *) i
              fieldInfos: (LCFieldInfos *) fis
	      isIndex: (BOOL) isi;
{
  self = [self init];
  [self setIndexInput: i];
  [self setFieldInfos: fis];
  isIndex = isi;
  int firstInt = [input readInt];
  if (firstInt >= 0) {
      // original-format file, without explicit format version number
      format = 0;
      size = firstInt;

      // back-compatible settings
      indexInterval = 128;
      skipInterval = INT_MAX; //Integer.MAX_VALUE; // switch off skipTo optimization

    } else {
      // we have a format version number
      format = firstInt;

      // check that it is a format we can understand
      if (format < LCTermInfos_FORMAT)
      {
	      NSLog(@"Unknown format version: %d", format);
	      return nil;
      }

      size = [input readLong];                    // read the size
      
      if(format == -1){
        if (!isIndex) {
          indexInterval = [input readInt];
          formatM1SkipInterval = [input readInt];
        }
        // switch off skipTo optimization for file format prior to 1.4rc2 in order to avoid a bug in 
        // skipTo implementation of these versions
        skipInterval = INT_MAX; // Integer.MAX_VALUE;
      }
      else{
        indexInterval = [input readInt];
        skipInterval = [input readInt];
      }
    }
  return self;

  }

- (void) seek: (long) pointer position: (int) p
         term: (LCTerm *) t termInfo: (LCTermInfo *) ti
{
  [input seek: pointer];
  position = p;
  [termBuffer setTerm: t];
  [termInfo setTermInfo: ti];
}

  /** Increments the enumeration to the next element.  True if one exists.*/
- (BOOL) next
{
    if (position++ >= size-1)
    {
      return NO;
    }

    [prevBuffer setTerm: termBuffer];
    [termBuffer read: input fieldInfos: fieldInfos];

    long intValue = [input readVInt];
    [termInfo setDocFreq: intValue];	  // read doc freq
    long long longValue = [input readVLong];
    [termInfo setFreqPointer: longValue + [termInfo freqPointer]];	  // read freq pointer
    [termInfo setProxPointer: [input readVLong] + [termInfo proxPointer]];	  // read prox pointer
    
    if(format == -1){
    //  just read skipOffset in order to increment  file pointer; 
    // value is never used since skipTo is switched off
      if (!isIndex) {
        if ([termInfo docFreq] > formatM1SkipInterval) {
          [termInfo setSkipOffset: [input readVInt]]; 
        }
      }
    }
    else{
      if ([termInfo docFreq] >= skipInterval) 
        [termInfo setSkipOffset: [input readVInt]];
    }
    
    if (isIndex)
    {
      long long longValue = [input readVLong];
      indexPointer += longValue;
//      indexPointer += [input readVLong];	  // read index pointer
    }

    return YES;
  }

  /** Optimized scan, without allocating new terms. */
- (void) scanTo: (LCTerm *) term
{
  if (scratch == nil)
    scratch = [[LCTermBuffer alloc] init];
  [scratch setTerm: term];
  while (([scratch compare: termBuffer] == NSOrderedDescending) && [self next]) {}
}

  /** Returns the current Term in the enumeration.
   Initially invalid, valid after next() called for the first time.*/
- (LCTerm *) term
{
    return termBuffer;
  }

  /** Returns the previous Term enumerated. Initially null.*/
- (LCTerm *) prev
{
    return prevBuffer;
  }

  /** Returns the current TermInfo in the enumeration.
   Initially invalid, valid after next() called for the first time.*/
- (LCTermInfo *) termInfo
{
  return AUTORELEASE([[LCTermInfo alloc] initWithTermInfo: termInfo]);
}

  /** Sets the argument to the current TermInfo in the enumeration.
   Initially invalid, valid after next() called for the first time.*/
- (void) setTermInfo: (LCTermInfo *) ti
{
  [termInfo setTermInfo: ti];
}

  /** Returns the docFreq from the current TermInfo in the enumeration.
   Initially invalid, valid after next() called for the first time.*/
- (long) docFreq
{
    return [termInfo docFreq];
  }

  /* Returns the freqPointer from the current TermInfo in the enumeration.
    Initially invalid, valid after next() called for the first time.*/
- (long long) freqPointer
{
    return [termInfo freqPointer];
  }

  /* Returns the proxPointer from the current TermInfo in the enumeration.
    Initially invalid, valid after next() called for the first time.*/
- (long long) proxPointer
{
    return [termInfo proxPointer];
  }

  /** Closes the enumeration to further activity, freeing resources. */
- (void) close
{
    [input close];
}

- (void) setIndexInput: (LCIndexInput *) i
{
  ASSIGN(input, i);
}

- (void) setTermBuffer: (LCTermBuffer *) tb
{
  ASSIGN(termBuffer, tb);
}

- (void) setPrevBuffer: (LCTermBuffer *) pb
{
  ASSIGN(prevBuffer, pb);
}

- (void) setScratch: (LCTermBuffer *) s
{
  ASSIGN(scratch, s);
}

- (void) setSize: (long long) s
{
  size = s;
}

- (void) setPosition: (long long ) p
{
  position = p;
}

- (void) setFormat: (int) f
{
  format = f;
}

- (void) setIndexed: (BOOL) index
{
  isIndex = index;
}

- (void) setIndexPointer: (long) p
{
  indexPointer = p;
}

- (void) setIndexInterval: (int) i
{
  indexInterval = i;
}

- (void) setSkipInterval: (unsigned int) skip
{
  skipInterval = skip;
}

- (void) setFormatM1SkipInterval: (int) formatM1
{
  formatM1SkipInterval: formatM1;
}

- (void) setFieldInfos: (LCFieldInfos *) fi
{
  ASSIGN(fieldInfos, fi);
}

- (LCFieldInfos *) fieldInfos
{
  return fieldInfos;
}

- (long long) size
{
  return size;
}

- (long) indexPointer
{
  return indexPointer;
}

- (int) indexInterval
{
  return indexInterval;
}

- (unsigned int) skipInterval
{
  return skipInterval;
}

- (long long) position
{
  return position;
}

- (id) copyWithZone: (NSZone *) zone
{
  LCSegmentTermEnum *clone = [[LCSegmentTermEnum allocWithZone: zone] init];

  [clone setIndexInput: input];
  [clone setFieldInfos: fieldInfos];
  [clone setSize: size];
  [clone setPosition: position];
  [clone setTermInfo: [termInfo copy]];
  [clone setTermBuffer: [termBuffer copy]];
  [clone setPrevBuffer: [prevBuffer copy]];
  [clone setScratch: nil];
  [clone setFormat: format];
  [clone setIndexed: isIndex];
  [clone setIndexPointer: indexPointer];
  [clone setIndexInterval: indexInterval];
  [clone setSkipInterval: skipInterval];
  [clone setFormatM1SkipInterval: formatM1SkipInterval];

  return AUTORELEASE(clone);
}

#ifdef HAVE_UKTEST
- (void) addDoc: (LCIndexWriter *) writer : (NSString *) value
{
  NSLog(@"add %@", value);
  LCDocument *doc = [[LCDocument alloc] init];
  LCField *field = [[LCField alloc] initWithName: @"content" string: value
                         store: LCStore_NO index: LCIndex_Tokenized];
  [doc addField: field];
  NSLog(@"after addField");
  [writer addDocument: doc];
  NSLog(@"After addDocument");
}

- (void) verifyDocFreq: (id <LCDirectory>) dir
{
  LCIndexReader *reader = [LCIndexReader openDirectory: dir];
  LCTermEnum *termEnum = nil;
  
  // create enumeration of all terms
  termEnum = [reader terms];
  // go to the first term (aaa)
  [termEnum next];
  
    // assert that term is 'aaa'
  UKStringsEqual(@"aaa", [[termEnum term] text]);
  UKIntsEqual(200, [termEnum docFreq]);
    // go to the second term (bbb)
    [termEnum next];
    // assert that term is 'bbb'
      UKStringsEqual(@"bbb", [[termEnum term] text]);
  UKIntsEqual(100, [termEnum docFreq]);
  
  [termEnum close];

    // create enumeration of terms after term 'aaa', including 'aaa'
    termEnum = [reader termsWithTerm: [[LCTerm alloc] initWithField: @"content" text: @"aaa"]];
    // assert that term is 'aaa'
  UKStringsEqual(@"aaa", [[termEnum term] text]);
  UKIntsEqual(200, [termEnum docFreq]);
      // go to term 'bbb'
    [termEnum next];
    // assert that term is 'bbb'
    UKStringsEqual(@"bbb", [[termEnum term] text]);
  UKIntsEqual(100, [termEnum docFreq]);
  
  [termEnum close];
  }

- (void) testSegmentTermEnum
{
#if 0
  id <LCDirectory> dir = [[LCRAMDirectory alloc] init];
  LCIndexWriter *writer = nil;
  writer = [[LCIndexWriter alloc] initWithDirectory: dir
  									analyzer: [[LCWhitespaceAnalyzer alloc] init]
  									create: YES];

      // add 100 documents with term : aaa
      // add 100 documents with terms: aaa bbb
      // Therefore, term 'aaa' has document frequency of 200 and term 'bbb' 100
      int i;
      for (i = 0; i < 100; i++)
      {
      [self addDoc: writer : @"aaa"];
      [self addDoc: writer : @"aaa bbb"];
      }
      [writer close];
      
      // verify document frequency of terms in an unoptimized index
     [self verifyDocFreq: dir];
     #endif
#if 0
      // merge segments by optimizing the index
      write = [[LCIndexWriter alloc] initWithDirectory: dir
      								analyzer: [[LCWhitespaceAnalyzer alloc] init]
      								create: NO];
      [writer optimize];
      [writer close];
      // verify document frequency of terms in an optimized index
      [self verifyDocFreq: dir];
      #endif
}

#endif

@end
