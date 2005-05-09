#include "Util/LCPriorityQueue.h"
#include "GNUstep/GNUstep.h"

@interface LCPriorityQueue (LCPrivate)
- (void) upHeap;
- (void) downHeap;
@end

@implementation LCPriorityQueue

/** Subclass constructors must call this. */
- (id) initWithSize: (int) m
{
	self = [self init];
	heap = [[NSMutableArray alloc] init];
	maxSize = m;
	return self;
}

- (void) dealloc
{
	DESTROY(heap);
	[super dealloc];
}

/**
* Adds an Object to a PriorityQueue in log(size) time.
 * If one tries to add more objects than maxSize from initialize
 * a RuntimeException (ArrayIndexOutOfBound) is thrown.
 */
- (void) put: (id) element
{
	if ([heap count] >= maxSize)
    {
		NSLog(@"Out of bound");
		return;
    }
	[heap addObject: element];
	[self upHeap];
}

/* LuceneKit: override by classes in /Search */
- (BOOL) lessThan: (id) a : (id) b
{
	if([(id <LCComparable>)a compare: b] == NSOrderedAscending)
		return YES;
	else
		return NO;
}

/**
* Adds element to the PriorityQueue in log(size) time if either
 * the PriorityQueue is not full, or not lessThan(element, top()).
 * @param element
 * @return true if element is added, false otherwise.
 */
- (BOOL) insert: (id) element
{
	if([heap count] < maxSize)
    {
		[self put: element];
		return YES;
    }
	else if([heap count] > 0 && ![self lessThan: element : [self top]])
		//else if([heap count] > 0 && ([(id <LCComparable>)element compare: [self top]] != NSOrderedAscending))
    {
		[heap replaceObjectAtIndex: 0 withObject: element];
		[self adjustTop];
		return YES;
    }
	else
    {
		return NO;
    }
}

/** Returns the least element of the PriorityQueue in constant time. */
- (id) top
{
	if ([heap count] > 0)
		return [heap objectAtIndex: 0];
	else
		return nil;
}

/** Removes and returns the least element of the PriorityQueue in log(size)
time. */
- (id) pop
{
	if ([heap count] > 0) 
    {
		NSObject *result = [heap objectAtIndex: 0]; // save first value
		RETAIN(result);
		[heap replaceObjectAtIndex: 0 withObject: [heap lastObject]];  // move last to first
		[heap removeLastObject];			  // permit GC of objects
		[self downHeap];				  // adjust heap
		return AUTORELEASE(result);
    }
	else
    {
		return nil;
    }
}

/** Should be called when the Object at top changes values.  Still log(n)
* worst case, but it's at least twice as fast to <pre>
*  { pq.top().change(); pq.adjustTop(); }
* </pre> instead of <pre>
*  { o = pq.pop(); o.change(); pq.push(o); }
* </pre>
*/
- (void) adjustTop
{
	[self downHeap];
}

/** Returns the number of elements currently stored in the PriorityQueue. */
- (int) size
{
	return [heap count];
}

/** Removes all entries from the PriorityQueue. */
- (void) clear
{
	[heap removeAllObjects];
}

- (void) upHeap
{
	if ([heap count] == 0) return;
	int i = [heap count]-1;
	id <LCComparable> node = [heap objectAtIndex: i];	  // save bottom node
	RETAIN(node);
	int j = i >> 1;
	while (j >= 0 && [self lessThan: node : [heap objectAtIndex: j]]) 
		//  while (j >= 0 && ([node compare: [heap objectAtIndex: j]] == NSOrderedAscending)) 
    {
		// shift parents down
		[heap replaceObjectAtIndex: i withObject: [heap objectAtIndex: j]];
		i = j;
		j = j >> 1;
		if (i == j) // i == j == 0
			break;
    }
	[heap replaceObjectAtIndex: i withObject: node]; // install saved node
	DESTROY(node);
}

- (void) downHeap
{
	if ([heap count] == 0) return;
	int i = 0;
	NSObject *node = [heap objectAtIndex: i];	  // save top node
	RETAIN(node);
	int j = i << 1;				  // find smaller child
	int k = j + 1;
	if (k < [heap count] && [self lessThan: [heap objectAtIndex: k]: [heap objectAtIndex: j]]) {
		//  if (k < [heap count] && ([(id <LCComparable>)[heap objectAtIndex: k] compare: [heap objectAtIndex: j]] == NSOrderedAscending)) {
		j = k;
		}
	while (j < [heap count] && [self lessThan: [heap objectAtIndex: j] : node]) {
		//  while (j < [heap count] && ([(id <LCComparable>)[heap objectAtIndex: j] compare: node] == NSOrderedAscending)) {
		// shift up child
		[heap replaceObjectAtIndex: i withObject: [heap objectAtIndex: j]];
		i = j;
		j = i << 1;
		k = j + 1;
		if (k < [heap count] && [self lessThan: [heap objectAtIndex: k] : [heap objectAtIndex: j]]) {
			//if (k < [heap count] && ([(id <LCComparable>)[heap objectAtIndex: k] compare: [heap objectAtIndex: j]] == NSOrderedAscending)) {
			j = k;
			}
		}
	[heap replaceObjectAtIndex: i withObject: node]; // install saved node
	DESTROY(node);
		}

@end

#ifdef HAVE_UKTEST
#include <UnitKit/UnitKit.h>

@interface LCIntegerQueue: LCPriorityQueue <UKTest>
@end

@implementation LCIntegerQueue
- (void) doTestPriorityQueue: (int) count
{
	self = [self initWithSize: count];
	srandom((unsigned long)[[NSDate date] timeIntervalSinceReferenceDate]);
	int sum = 0, sum2 = 0;
	int i, next, prev;
	
	for(i = 0; i < count; i++)
    {
		next = (int)random();
		sum += next;
		[self put: [NSNumber numberWithInt: next]];
    }
	
	prev = -1;
	for(i = 0; i < count; i++)
    {
		next = [[self pop] intValue];
		sum2 += next;
		UKTrue(prev < next);
		if (prev >= next)
			NSLog(@"prev %d, next %d", prev, next);
		prev = next;
    }
	UKIntsEqual(sum, sum2);
}

- (void) testPriorityQueue
{
	[self doTestPriorityQueue: 10000];
}

- (void) testClear
{
	self = [self initWithSize: 3];
	[self put: [NSNumber numberWithInt: 2]];
	[self put: [NSNumber numberWithInt: 3]];
	[self put: [NSNumber numberWithInt: 1]];
	UKIntsEqual(3, [self size]);
	[self clear];
	UKIntsEqual(0, [self size]);
}

- (void) testFixedSize
{
	self = [self initWithSize: 3];
	[self insert: [NSNumber numberWithInt: 2]];
	[self insert: [NSNumber numberWithInt: 3]];
	[self insert: [NSNumber numberWithInt: 1]];
	[self insert: [NSNumber numberWithInt: 5]];
	[self insert: [NSNumber numberWithInt: 7]];
	[self insert: [NSNumber numberWithInt: 1]];
	UKIntsEqual(3, [self size]);
	UKIntsEqual(3, [[self top] intValue]);
}

@end

#endif

