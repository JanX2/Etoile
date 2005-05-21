#include <LuceneKit/Index/LCTermInfosReader.h>
#include <LuceneKit/GNUstep/GNUstep.h>

/** This stores a monotonically increasing set of <Term, TermInfo> pairs in a
* Directory.  Pairs are accessed either by Term or by ordinal position the
* set.  */
@interface LCTermInfosReader (LCPrivate)
- (LCSegmentTermEnumerator *) termEnumerator;
- (void) ensureIndexIsRead;
- (int) indexOffset: (LCTerm *) term;
- (void) seekEnumerator: (int) indexOffset;
- (LCTermInfo *) scanEnumerator: (LCTerm *) term;
- (LCTerm *) scanEnumeratorAtPosition: (int) position;
@end

@implementation LCTermInfosReader

- (id) initWithDirectory: (id <LCDirectory>) dir
				 segment: (NSString *) seg
              fieldInfos: (LCFieldInfos *) fis
{
	self = [super init];
	ASSIGN(directory, dir);
	ASSIGN(segment, seg);
	ASSIGN(fieldInfos, fis);
	origEnum = [[LCSegmentTermEnumerator alloc] initWithIndexInput: [dir openInput: [segment stringByAppendingPathExtension: @"tis"]]
												  fieldInfos: fieldInfos
													 isIndex: NO];
	size = [origEnum size];
	indexEnum = [[LCSegmentTermEnumerator alloc] initWithIndexInput: [dir openInput: [segment stringByAppendingPathExtension: @"tii"]]
												   fieldInfos: fieldInfos
													  isIndex: YES];
	return self;
}

- (void) dealloc
{
	RELEASE(origEnum);
	RELEASE(indexEnum);
	[super dealloc];
}

- (int) skipInterval
{
	return [origEnum skipInterval];
}

- (void) close
{
    if (origEnum != nil)
		[origEnum close];
    if (indexEnum != nil)
		[indexEnum close];
}

/** Returns the number of term/value pairs in the set. */
- (long) size
{
    return size;
}

- (LCSegmentTermEnumerator *) termEnumerator
{
#if 0
    LCSegmentTermEnumerator *termEnum = (LCSegmentTermEnum *)enumerators.get();
    if (termEnum == nil) {
		termEnum = [self terms];
		[enumerators set: termEnum];
    }
    return termEnum;
#endif
    return [self terms];
}

- (void) ensureIndexIsRead
{
    if (indexTerms != nil)                       // index already read
		return;                                     // do nothing
													//    int indexSize = (int)[indexEnum size];        // otherwise read index
	
    ASSIGN(indexTerms, [[NSMutableArray alloc] init]);
    ASSIGN(indexInfos, [[NSMutableArray alloc] init]);
    ASSIGN(indexPointers, [[NSMutableArray alloc] init]);
	
    while([indexEnum next])
	{
		[indexTerms addObject: [indexEnum term]];
		[indexInfos addObject: [indexEnum termInfo]];
		[indexPointers addObject: [NSNumber numberWithLong: [indexEnum indexPointer]]];
	}
	
	[indexEnum close];
	DESTROY(indexEnum);
}

/** Returns the offset of the greatest index entry which is less than or equal to term.*/
- (int) indexOffset: (LCTerm *) term
{
    int lo = 0;					  // binary search indexTerms[]
    int hi = [indexTerms count] - 1;
	
    while (hi >= lo) {
		int mid = (lo + hi) >> 1;
		NSComparisonResult delta = 
			[term compare: [indexTerms objectAtIndex: mid]];
		if (delta == NSOrderedAscending)
			hi = mid - 1;
		else if (delta == NSOrderedDescending)
			lo = mid + 1;
		else
			return mid;
    }
    return hi;
}

- (void) seekEnumerator: (int) indexOffset
{
	long index = [[indexPointers objectAtIndex: indexOffset] longValue];
	int pos = indexOffset * [[self termEnumerator] indexInterval] - 1;
	//  LCTerm *t = [indexTerms objectAtIndex: indexOffset];
	//  LCTermInfo *ti = [indexInfos objectAtIndex: indexOffset];
	[[self termEnumerator] seek: index
				 position: pos
					 term: [indexTerms objectAtIndex: indexOffset]
				 termInfo: [indexInfos objectAtIndex: indexOffset]];
}

/** Returns the TermInfo for a Term in the set, or null. */
- (LCTermInfo *) termInfo: (LCTerm *) term
{
    if (size == 0) return nil;
	
    [self ensureIndexIsRead];
	
    // optimize sequential access: first try scanning cached enum w/o seeking
#if 0 // FIXME   
    LCSegmentTermEnumerator *enumerator = [self termEnumerator];
    if (([enumerator term] != nil)// term is at or past current
		&& (([enumerator prev] != nil && [term compareTo: [enumerator prev]] == NSOrderedDescending)
			|| [term compareTo: [enumerator term]] != NSOrderedAscending)) {
		int enumOffset = (int)([enumerator position]/[enumerator indexInterval])+1;
		if ([indexTerms count] == enumOffset	  // but before end of block
			|| [term compareTo: [indexTerms objectAtIndex: enumOffset]] == NSOrderedAscending)
			return [self scanEnumerator: term];			  // no need to seek
    }
#endif
	
    // random-access: must seek
    int index = [self indexOffset: term];
    /* LuceneKit: if term doesn't exist, return nil */
    if (index < 0) return nil;
    [self seekEnumerator: index];
    return [self scanEnumerator: term];
}

/** Scans within block for matching term. */
- (LCTermInfo *) scanEnumerator: (LCTerm *) term
{
    LCSegmentTermEnumerator *enumerator = [self termEnumerator];
    [enumerator scanTo: term];
    
    if ([enumerator term] != nil && [term compare: [enumerator term]] == NSOrderedSame)
		return [enumerator termInfo];
    else
		return nil;
}

/** Returns the nth term in the set. */
- (LCTerm *) termAtPosition: (int) position
{
    if (size == 0) return nil;
	
    LCSegmentTermEnumerator *enumerator = [self termEnumerator];
    if (enumerator != nil && [enumerator term] != nil &&
        position >= [enumerator position] &&
		position < ([enumerator position] + [enumerator indexInterval]))
		return [self scanEnumeratorAtPosition: position];		  // can avoid seek
	
    [self seekEnumerator: (position / [enumerator indexInterval])]; // must seek
    return [self scanEnumeratorAtPosition: position];
}

- (LCTerm *) scanEnumeratorAtPosition: (int) position
{
    LCSegmentTermEnumerator *enumerator = [self termEnumerator];
    while([enumerator position] < position)
		if (![enumerator next])
			return nil;
	
    return [enumerator term];
}

/** Returns the position of a Term in the set or -1. */
- (long) positionOfTerm: (LCTerm *) term
{
    if (size == 0) return -1;
	
    [self ensureIndexIsRead];
    int indexOffset = [self indexOffset: term];
    [self seekEnumerator: indexOffset];
	
    LCSegmentTermEnumerator *enumerator = [self termEnumerator];
    while([term compare: [enumerator term]] == NSOrderedDescending && [enumerator next]) {}
	
    if ([term compare: [enumerator term]] == NSOrderedSame)
		return [enumerator position];
    else
		return -1;
}

/** Returns an enumeration of all the Terms and TermInfos in the set. */
- (LCSegmentTermEnumerator *) terms
{
	return (LCSegmentTermEnumerator *)[origEnum copy];
	
}

/** Returns an enumeration of terms starting at or after the named term. */
- (LCSegmentTermEnumerator *) termsWithTerm: (LCTerm *) term
{
#if 0
	[self termInfo: term];
    return (LCSegmentTermEnumerator *)[[self termEnumerator] copy];
#else
	[self ensureIndexIsRead];
    LCSegmentTermEnumerator *enumerator = [self termEnumerator];
    [self seekEnumerator: [self indexOffset: term]];
    [enumerator scanTo: term];
    return enumerator;
	
#endif
	
}

@end
