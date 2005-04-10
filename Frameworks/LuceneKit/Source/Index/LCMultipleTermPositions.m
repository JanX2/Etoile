#include "Index/LCMultipleTermPositions.h"
#include "Index/LCIndexReader.h"
#include "Util/LCPriorityQueue.h"

/**
 * Describe class <code>MultipleTermPositions</code> here.
 *
 * @author Anders Nielsen
 * @version 1.0
 */
@implementation LCTermPositionsQueue
- (id) initWithTermPositions: (NSArray *) termPositions
{
  self = [super initWithSize: [termPositions count]];
  NSEnumerator *e = [termPositions objectEnumerator];
  id <LCTermPositions> tp;
  while((tp = [e nextObject]))
  {
    if ([tp next])
      [self put:tp];
  }
    
}

- (id <LCTermPositions>) peek
{
  return (id <LCTermPositions>)[self top];
}

- (BOOL) lessThan: (id) a : (id) b
{ 
  return [(id <LCTermPositions>)a doc] < [(id <LCTermPositions>)b doc];
}
@end

@implementation LCIntQueue
- (id) init
{
  self = [super init];
  _arraySize = 16;
  _index = 0;
  _lastIndex = 0;
  _array = [[NSMutableArray alloc] init];
  return self;
}

- (void) add: (int) i
{
  if (_lastIndex == _arraySize)
    [self growArray];
  [_array addObject: [NSNumber numberWithInt: i]];
  _lastIndex++;
}

- (int) next
{
  return [[_array objectAtIndex: _index++] intValue];
}

- (void) sort
{
  [_array sortUsingSelector: @selector(compare:)];
}

- (void) clear
{
  _index = 0;
  _lastIndex = 0;
  [_array removeAllObjects];
}

- (int) size
{
  return (_lastIndex - _index);
}

- (void) growArray
{
  _arraySize *= 2;
}

@end
 
@implementation LCMultipleTermPositions
    /**
     * Creates a new <code>MultipleTermPositions</code> instance.
     *
     * @param indexReader an <code>IndexReader</code> value
     * @param terms a <code>Term[]</code> value
     * @exception IOException if an error occurs
     */
- (id) initWithIndexReader: (LCIndexReader *) indexReader
                terms: (NSArray *) terms
{
  self = [super init];
  NSMutableArray *termPositions = [[NSMutableArray alloc] init];
  int i;
  for (i = 0; i < [terms count]; i++)
    [termPositions addObject: [indexReader termPositionsWithTerm: [terms objectAtIndex: i] ]];

  _termPositionsQueue = [[LCTermPositionsQueue alloc] initWithTermPositions: termPositions];
  _posList = [[LCIntQueue alloc] init];
  return self;
}

- (BOOL) next
{
  if ([_termPositionsQueue size] == 0)
    return NO;

  [_posList clear];
  _doc = [[_termPositionsQueue peek] doc];

  id <LCTermPositions> tp;
  do
  {
  	    tp = [_termPositionsQueue peek];

  int i;
	    for (i=0; i< [tp freq]; i++)
	     [_posList add: [tp nextPosition]];

	    if ([tp next])
	     [_termPositionsQueue adjustTop];
	    else
	    {
	     [_termPositionsQueue pop];
	     [tp close];
	    }
	}
	while ([_termPositionsQueue size] > 0 && [[_termPositionsQueue peek] doc] == _doc);

	[_posList sort];
	_freq = [_posList size];

	return YES;
    }

- (int) nextPosition
{

	return [_posList next];
    }

     - (BOOL)  skipTo: (int) target
    {
	while (target > [[_termPositionsQueue peek] doc])
	{
	    id <LCTermPositions> tp = (id <LCTermPositions>)[_termPositionsQueue pop];

	    if ([tp skipTo: target])
		[_termPositionsQueue put: tp];
	    else
		[tp close];
	}

	return [self next];
    }

- (long) doc
{

	return _doc;
    }

- (long) freq
{
	return _freq;
    }

- (void) close
{
	while ([_termPositionsQueue size] > 0)
	    [(id <LCTermPositions>)[_termPositionsQueue pop] close];
    }

    /** Not implemented.
     * @throws UnsupportedOperationException
     */
     - (void) seekTerm: (LCTerm *) arg0
    {
    NSLog(@"UnsupportedOperation");
    }

    /** Not implemented.
     * @throws UnsupportedOperationException
     */
     - (void) seekTermEnum: (LCTermEnum *) termEnum
     {
    NSLog(@"UnsupportedOperation");
    }

    /** Not implemented.
     * @throws UnsupportedOperationException
     */
     - (int) readDocs: (NSArray *) docs  frequency: (NSArray *) freq
     {
    NSLog(@"UnsupportedOperation");
    }
    @end
