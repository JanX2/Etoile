#include "LuceneKit/Index/LCSegmentTermEnum.h"
#include "LuceneKit/Index/LCFieldInfos.h"
#include "LuceneKit/Index/LCTermInfo.h"
#include "LuceneKit/Index/LCTermInfosWriter.h"
#include "LuceneKit/Index/LCTermBuffer.h"
#include "LuceneKit/Store/LCIndexInput.h"
#include "GNUstep.h"

@implementation LCSegmentTermEnum

- (id) initWithIndexInput: (LCIndexInput *) i
              fieldInfos: (LCFieldInfos *) fis
	      isIndex: (BOOL) isi;
{
  self = [super init];
  position = -1;
  ASSIGN(termBuffer, [[LCTermBuffer alloc] init]);
  ASSIGN(prevBuffer, [[LCTermBuffer alloc] init]);
  ASSIGN(termInfo, [[LCTermInfo alloc] init]);
  isIndex = isi;
  indexPointer = 0;
  ASSIGN(input, i);
  ASSIGN(fieldInfos, fis);
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

- (id) copyWithZone: (NSZone *) zone
{
  LCSegmentTermEnum *clone = [[LCSegmentTermEnum allocWithZone: zone] init];

  [clone setIndexInput: [input copy]];
  [clone setTermInfo: [[LCTermInfo alloc] initWithTermInfo: termInfo]];
  [clone setTermBuffer: [termBuffer copy]];
  [clone setPrevBuffer: [termBuffer copy]];
  [clone setScratch: nil];

  return AUTORELEASE(clone);
}

- (void) seek: (long) pointer position: (int) p
         term: (LCTerm *) t termInfo: (LCTermInfo *) ti
{
  [input seek: pointer];
  position = p;
  [termBuffer setTerm: t];
  [prevBuffer reset];
  [termInfo setTermInfo: ti];
}

  /** Increments the enumeration to the next element.  True if one exists.*/
- (BOOL) next
{
    if (position++ >= size - 1) {
      [termBuffer reset];
      return NO;
    }

    [prevBuffer setTermBuffer: termBuffer];
    [termBuffer read: input fieldInfos: fieldInfos];

    [termInfo setDocFreq: [input readVInt]];	  // read doc freq
    [termInfo setFreqPointer: [input readVLong] + [termInfo freqPointer]];	  // read freq pointer
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
      indexPointer += [input readVLong];	  // read index pointer

    return YES;
  }

  /** Optimized scan, without allocating new terms. */
- (void) scanTo: (LCTerm *) term
{
    if (scratch == nil)
      ASSIGN(scratch, AUTORELEASE([[LCTermBuffer alloc] init]));
    [scratch setTerm: term];
    while (([scratch compareTo: termBuffer] == NSOrderedDescending) && [self next]) {}
  }

  /** Returns the current Term in the enumeration.
   Initially invalid, valid after next() called for the first time.*/
- (LCTerm *) term
{
    return [termBuffer toTerm];
  }

  /** Returns the previous Term enumerated. Initially null.*/
- (LCTerm *) prev
{
    return [prevBuffer toTerm];
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
  [ti setTermInfo: termInfo];
  }

  /** Returns the docFreq from the current TermInfo in the enumeration.
   Initially invalid, valid after next() called for the first time.*/
- (int) docFreq
{
    return [termInfo docFreq];
  }

  /* Returns the freqPointer from the current TermInfo in the enumeration.
    Initially invalid, valid after next() called for the first time.*/
- (long) freqPointer
{
    return [termInfo freqPointer];
  }

  /* Returns the proxPointer from the current TermInfo in the enumeration.
    Initially invalid, valid after next() called for the first time.*/
- (long) proxPointer
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

- (LCFieldInfos *) fieldInfos
{
  return fieldInfos;
}

- (long) size
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

- (long) position
{
  return position;
}

@end
