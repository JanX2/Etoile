#include "Store/LCFSIndexInput.h"
#include "GNUstep/GNUstep.h"

@implementation LCFSIndexInput

- (id) copyWithZone: (NSZone *) zone;
{
  LCFSIndexInput *clone = [[LCFSIndexInput allocWithZone: zone] initWithFile: path];
  [clone seek: [self filePointer]];
  return AUTORELEASE(clone);
}

- (id) initWithFile: (NSString *) absolutePath
{
  self = [super init];
  ASSIGN(path, absolutePath);
  ASSIGN(handle, [NSFileHandle fileHandleForReadingAtPath: absolutePath]);
  NSFileManager *manager = [NSFileManager defaultManager];
  NSDictionary *d = [manager fileAttributesAtPath: absolutePath
	                            traverseLink: YES];
  length = [[d objectForKey: NSFileSize] longValue];
  return self;
}

- (char) readByte
{
  char b;
  NSData *d = [handle readDataOfLength: 1];
  [d getBytes: &b length: 1];
  return b;
}

- (void) readBytes: (NSMutableData *) b 
         offset: (int) offset length: (int) len
{
  NSData *d = [handle readDataOfLength: len];
  unsigned l = [d length];
  NSRange r = NSMakeRange(offset, l);
  char *buf = malloc(sizeof(char)*l);
  [d getBytes: buf length: l];
  [b replaceBytesInRange: r withBytes: buf];
  free(buf);
}

- (unsigned long long) filePointer
{
  return [handle offsetInFile];
}

- (void) seek: (unsigned long long) pos
{
  if (pos < [self length])
    [handle seekToFileOffset: pos];
  else
    [handle seekToEndOfFile];
}

  /** IndexInput methods */
- (void) close
{
  [handle closeFile];
}

- (unsigned long long) length
{
  return length;
}

- (void) dealloc
{
  [handle closeFile];
  RELEASE(handle);
  RELEASE(path);
  [super dealloc];
}

@end
