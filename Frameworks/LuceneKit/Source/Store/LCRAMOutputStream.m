#include "LuceneKit/Store/LCRAMOutputStream.h"
#include "LuceneKit/Store/LCRAMFile.h"
#include "GNUstep.h"

/**
 * A memory-resident {@link IndexOutput} implementation.
 *
 * @version $Id$
 */

@implementation LCRAMOutputStream

  /** Construct an empty output buffer. */
- (id) init
{
  self = [super init];
  file = [[LCRAMFile alloc] init];
  pointer = 0;
  return self;
}

- (void) dealloc
{
  RELEASE(file);
  [super dealloc];
}

- (id) initWithFile: (LCRAMFile *) f
{
  self = [self init];
  ASSIGN(file, f);
  return self;
}

- (void) writeByte: (char) b
{
  NSData *d = [NSData dataWithBytes: &b length: 1];
  [self writeBytes: d length: 1];
}

- (void) writeBytes: (NSData *) b length: (int) len
{
  NSRange r = NSMakeRange(0, len);
  if (file)
    [file addData: [b subdataWithRange: r]];
}

- (void) flush
{
}

- (void) close
{
}

- (void) seek: (unsigned long long) pos
{
  pointer = pos;
}

- (unsigned long long) filePointer
{
  return pointer;
}

- (unsigned long long) length
{
  return [file length];
}

- (void) writeTo: (LCIndexOutput *) o
{
  [o writeBytes: [file buffers] length: [file length]];
}

- (void) reset
{
  [self seek: 0];
  [file setLength: 0];
}


@end
