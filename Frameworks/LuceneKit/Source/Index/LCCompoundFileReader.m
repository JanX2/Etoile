#include "LuceneKit/Index/LCCompoundFileReader.h"
#include "GNUstep.h"

/**
 * Class for accessing a compound stream.
 * This class implements a directory, but is limited to only read operations.
 * Directory methods that would normally modify data throw an exception.
 *
 * @author Dmitry Serebrennikov
 * @version $Id$
 */
@interface LCFileEntry: NSObject
{
  long offset;
  long length;
}
- (long) offset;
- (long) length;
- (void) setOffset: (long) o;
- (void) setLength: (long) l;

@end

@implementation LCFileEntry
- (long) offset { return offset; }
- (long) length { return length; }
- (void) setOffset: (long) o { offset = o; }
- (void) setLength: (long) l { length = l; }
@end

    /** Implementation of an IndexInput that reads from a portion of the
     *  compound file. The visibility is left as "package" *only* because
     *  this helps with testing since JUnit test cases in a different class
     *  can then access package fields of this class.
     */
@implementation LCCSIndexInput

- (id) initWithCompoundFileReader: (LCCompoundFileReader *) cr
       indexInput: (LCIndexInput *) b offset: (long) f
       length: (long) len
{
  self = [super init];
  ASSIGN(reader, cr);
  ASSIGN(base, b);
  fileOffset = f;
  length = len;
  return self;
}

        /** Expert: implements buffer refill.  Reads bytes from the current
         *  position in the input.
         * @param b the array to read bytes into
         * @param offset the offset in the array to start storing bytes
         * @param len the number of bytes to read
         */
- (char) readByte
{
  NSMutableData *data = [[NSMutableData alloc] init];
  [self readBytes: data offset: 0 length: 1];
  return *(char *)[data bytes];
}

- (void) readBytes: (NSMutableData *) b
         offset: (int) offset
	 length: (int) len
{
  long start = [self filePointer];
  if (start + len > length)
    {
	    NSLog(@"read past EOF");
	    return;
    }
  [base seek: fileOffset + start];
  [base readBytes: b offset: offset length: len];
}

        /** Expert: implements seek.  Sets current position in this file, where
         *  the next {@link #readInternal(byte[],int,int)} will occur.
         * @see #readInternal(byte[],int,int)
         */
- (void) seek: (unsigned long long) pos {}

        /** Closes the stream to further operations. */
- (void) close {}

- (unsigned long long) length { return length; }

@end

@implementation LCCompoundFileReader

- (id) init
{
  self = [super init];
  entries = [[NSMutableDictionary alloc] init];
  return self;
}

- (id) initWithDirectory: (id <LCDirectory>) dir
       name: (NSString *) name
{
  self = [self init];
  ASSIGN(directory, dir);
  ASSIGN(fileName, name);

  BOOL success = NO;
  stream = [dir openInput: name];

  // read the directory and init files
  int count = [stream readVInt];
  LCFileEntry *entry = nil;
  int i;
  NSString *iden;
  for (i=0; i<count; i++) {
    long offset = [stream readLong];
    NSString *iden = [stream readString];

    if (entry != nil) {
      // set length of the previous entry
      [entry setLength: offset - [entry offset]];
    }

  entry = [[LCFileEntry alloc] init];
  [entry setOffset: offset];
  [entries setObject: entry forKey: iden];
  }

  // set the length of the final entry
  if (entry != nil) {
    [entry setLength: [stream length] - [entry offset]];
  }

  success = YES;

  if (! success && (stream != nil)) {
    [stream close];
  }
}

- (id <LCDirectory>) directory { return directory; }

- (NSString *) name { return fileName; }

- (void) close
{
  if (stream == nil)
  {
    NSLog(@"Already closed");
    return;
  }

  [entries removeAllObjects];
  [stream close];
  stream = nil;
}

- (LCIndexInput *) openInput: (NSString *) iden
{
  if (stream == nil)
  {
    [stream close];
    return nil;
  }

  LCFileEntry *entry = (LCFileEntry *)[entries objectForKey: iden];
  if (entry == nil)
  {
	  NSLog(@"No sub-file with iden %@ found", iden);
	  return nil;
  }
    return [[LCCompoundFileReader alloc] 
        initWithCompoundFileReader: self
       indexInput: stream offset: [entry offset]
       length: [entry length]];
}

    /** Returns an array of strings, one for each file in the directory. */
  - (NSArray *) list
  {
    [entries allKeys];
  }

    /** Returns true iff a file with the given name exists. */
- (BOOL) fileExists: (NSString *) name
{
  return ([entries objectForKey: name]) ? YES : NO;
}

    /** Returns the time the named file was last modified. */
- (NSTimeInterval) fileModified: (NSString *) name
{
  // Ignore name
  return [directory fileModified: fileName];
}

    /** Set the modified time of an existing file to now. */
- (void) touchFile: (NSString *) name
{
  [directory touchFile: fileName];
    }

    /** Not implemented
     * @throws UnsupportedOperationException */
- (void) deleteFile: (NSString *) name
    {
	NSLog(@"Not support");
    }

    /** Not implemented
     * @throws UnsupportedOperationException */
- (void) renameFile: (NSString *) from
                 to: (NSString *) to
    {
	NSLog(@"Not support");
    }

    /** Returns the length of a file in the directory.
     * @throws IOException if the file does not exist */
- (unsigned long long) fileLength: (NSString *) name
{
        LCFileEntry *e = (LCFileEntry *) [entries objectForKey: name];
        if (e == nil)
	{
	  NSLog(@"File %@ does not exist", name);
	  return 0;
	}
        return [e length];
    }

    /** Not implemented
     * @throws UnsupportedOperationException */
- (LCIndexOutput *) createOutput: (NSString *) name
{
	NSLog(@"Not support");
    }

    /** Not implemented
     * @throws UnsupportedOperationException */
#if 0
    public Lock makeLock(String name)
    {
        throw new UnsupportedOperationException();
    }
#endif
@end
