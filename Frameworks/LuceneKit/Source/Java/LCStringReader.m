#include "LuceneKit/Java/LCStringReader.h"
#include "GNUstep.h"

@implementation LCStringReader
- (id) initWithString: (NSString *) s
{
  self = [super init];
  ASSIGN(source, AUTORELEASE([s copy]));
  return self;
}

- (void) close
{
  // Do something 
}

- (int) read
{
  if (pos >= [source length]) return -1;
  return (int)[source characterAtIndex: pos++];
}
- (int) read: (unichar *) buf length: (unsigned int) len
{
  if (pos >= [source length]) return -1;
  if ((pos+len) > [source length])
    len = [source length]-pos;
  NSRange range = NSMakeRange(pos, len);
  [source getCharacters: buf range: range];
  pos += len;
  return len;
}

- (BOOL) ready
{
  return YES;
}

- (long) skip: (long) n
{
  if ((pos+n) > [source length])
    {
      pos = [source length];
      return ([source length]-pos);
    }
  else
    {
      pos += n;
      return n;
    }
}

#ifdef HAVE_UKTEST
- (void) testStringReader
{
  self = [self initWithString: @"This is a reader"];
  UKTrue([self ready]);
  UKIntsEqual('T', [self read]);
  unichar buf[4];
  [self read: buf length: 3];
  UKIntsEqual('s', buf[2]);
  UKIntsEqual(' ', [self read]);
  UKIntsEqual(8, [self skip: 8]);
  UKIntsEqual('d', [self read]);
  UKIntsEqual(2, [self read: buf length: 3]);
  UKIntsEqual('r', buf[1]);
  UKIntsEqual(0, [self skip: 3]);
}
#endif

@end
