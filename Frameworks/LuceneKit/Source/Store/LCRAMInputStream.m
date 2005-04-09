#include "Store/LCRAMInputStream.h"
#include "GNUstep/GNUstep.h"

/**
 * A memory-resident {@link IndexInput} implementation.
 *
 * @version $Id$
 */

@implementation LCRAMInputStream

- (id) initWithFile: (LCRAMFile *) f
{
  self = [super init];
  ASSIGN(file, f);
  pointer = 0;
  return self;
}

- (char) readByte
{
  NSData *d = [file buffers];
  char b;
  [d getBytes: &b range: NSMakeRange(pointer, 1)];
  pointer++;
  return b;
}

- (void) readBytes: (NSMutableData *) b offset: (int) offset length: (int) len
{
  if ((pointer + len) > [file length])
    len = [file length] - pointer;
  char *d = malloc(sizeof(char)*len);
  NSRange r = NSMakeRange(pointer, len);
  [[file buffers] getBytes: d range: r];
  r = NSMakeRange(offset, len);
  [b replaceBytesInRange: r withBytes: d];
  pointer += len;
  free(d);
}

- (void) close
{
  // Do nothing
}

- (unsigned long long) filePointer
{
  return pointer;
}

- (void) seek: (unsigned long long) pos
{
  pointer = (int)pos;
}

- (unsigned long long) length
{
  return [file length];
}

- (id) copyWithZone: (NSZone *) zone
{
  // Access the same file
  LCRAMInputStream *clone = [[LCRAMInputStream allocWithZone: zone] initWithFile: file];
  [clone seek: pointer];
  return clone;
}

@end
