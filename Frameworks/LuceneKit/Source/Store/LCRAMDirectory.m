#include "Store/LCRAMDirectory.h"
#include "Store/LCFSDirectory.h"
#include "Store/LCRAMInputStream.h"
#include "Store/LCRAMOutputStream.h"
#include "GNUstep/GNUstep.h"

/**
 * A memory-resident {@link Directory} implementation.
 *
 * @version $Id$
 */
@implementation LCRAMDirectory

- (void) dealloc
{
  RELEASE(files);
  [super dealloc];
}

  /** Constructs an empty {@link Directory}. */
- (id) init
{
  self = [super init];
  ASSIGN(files, AUTORELEASE([[NSMutableDictionary alloc] init]));
  return self; 
}

  /**
   * Creates a new <code>RAMDirectory</code> instance from a different
   * <code>Directory</code> implementation.  This can be used to load
   * a disk-based index into memory.
   * <P>
   * This should be used only with indices that can fit into memory.
   *
   * @param dir a <code>Directory</code> value
   * @exception IOException if an error occurs
   */
- (id) initWithDirectory: (id <LCDirectory>) dir
{
  return [self initWithDirectory: dir close: NO];
}

- (id) initWithDirectory: (id <LCDirectory>) dir
                   close: (BOOL) closeDirectory;
{
  self = [self init];
  NSArray *f = [dir list];
  int i, count = [f count];
  unsigned long long len;
  NSMutableData *buf = [[NSMutableData alloc] init];
  LCIndexOutput *os;
  LCIndexInput *is;
  for (i = 0; i < count; i++) 
    {
      // make place on ram disk
      os = [self createOutput: [f objectAtIndex: i]];
      // read current file
      is = [self openInput: [f objectAtIndex: i]];
      // and copy to ram disk
      len = [is length];
      [is readBytes: buf offset: 0 length: len];
      [os writeBytes: buf length: len];
      // graceful cleanup
      [is close];
      [os close];
      [buf setLength: 0]; // clean data
    }
  if (closeDirectory)
    [dir close];

  RELEASE(buf);
  return self;
}

  /**
   * Creates a new <code>RAMDirectory</code> instance from the {@link FSDirectory}.
   *
   * @param dir a <code>String</code> specifying the full index directory path
   */
- (id) initWithPath: (NSString *) absolutePath
{
  LCFSDirectory *d = [[LCFSDirectory alloc] initWithPath: absolutePath
	               create: NO];
  return [self initWithDirectory: d close: YES];
}

  /** Returns an array of strings, one for each file in the directory. */
- (NSArray *) list
{
  return [files allKeys];
}

  /** Returns true iff the named file exists in this directory. */
- (BOOL) fileExists: (NSString *) name
{
  LCRAMFile *f = [files objectForKey: name];
  return (f != nil);
}

  /** Returns the time the named file was last modified. */
- (NSTimeInterval) fileModified: (NSString *) name
{
  LCRAMFile *f = [files objectForKey: name];
  return [f lastModified];
}

  /** Set the modified time of an existing file to now. */
- (void) touchFile: (NSString *) name
{
  LCRAMFile *f = [files objectForKey: name];
  [f setLastModified: [[NSData data] timeIntervalSince1970]];
}

  /** Returns the length in bytes of a file in the directory. */
- (unsigned long long) fileLength: (NSString *) name
{
  LCRAMFile *f = [files objectForKey: name];
  return [f length];
}

  /** Removes an existing file in the directory. */
- (void) deleteFile: (NSString *) name
{
  [files removeObjectForKey: name];
}

  /** Removes an existing file in the directory. */
- (void) renameFile: (NSString *) from to: (NSString *) to
{
  LCRAMFile *f = [files objectForKey: from];
  [files setObject: f forKey: to];
  [files removeObjectForKey: from];
}

  /** Creates a new, empty file in the directory with the given name.
      Returns a stream writing this file. */
- (LCIndexOutput *) createOutput: (NSString *) name
{
  LCRAMFile *f = [[LCRAMFile alloc] init];
  [files setObject: f forKey: name];
  RELEASE(f);
  LCRAMOutputStream *s = [[LCRAMOutputStream alloc] initWithFile: f];
  return AUTORELEASE(s);
}

  /** Returns a stream reading an existing file. */
- (LCIndexInput *) openInput: (NSString *) name
{
  LCRAMFile *f = [files objectForKey: name];
  LCRAMInputStream *i = [[LCRAMInputStream alloc] initWithFile: f];
  return AUTORELEASE(i);
}

  /** Construct a {@link Lock}.
   * @param name the name of the lock file
   */
#if 0
  public final Lock makeLock(final String name) {
    return new Lock() {
      public boolean obtain() throws IOException {
        synchronized (files) {
          if (!fileExists(name)) {
            createOutput(name).close();
            return true;
          }
          return false;
        }
      }
      public void release() {
        deleteFile(name);
      }
      public boolean isLocked() {
        return fileExists(name);
      }
    };
  }
#endif

- (void) close
{
}

@end
