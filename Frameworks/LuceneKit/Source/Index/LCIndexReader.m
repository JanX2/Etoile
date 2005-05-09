#include "Index/LCIndexReader.h"
#include "Index/LCSegmentReader.h"
#include "Index/LCMultiReader.h"
#include "Store/LCFSDirectory.h"
#include "Search/LCSimilarity.h"
#include "GNUstep/GNUstep.h"

/** IndexReader is an abstract class, providing an interface for accessing an
 index.  Search of an index is done entirely through this abstract interface,
 so that any subclass which implements it is searchable.

 <p> Concrete subclasses of IndexReader are usually constructed with a call to
 one of the static <code>open()</code> methods, e.g. {@link #open(String)}.

 <p> For efficiency, in this API documents are often referred to via
 <i>document numbers</i>, non-negative integers which each name a unique
 document in the index.  These document numbers are ephemeral--they may change
 as documents are added to and deleted from an index.  Clients should thus not
 rely on a given document having the same number between sessions.

 @author Doug Cutting
 @version $Id$
*/

@interface LCIndexReader (LCPrivate)
+ (LCIndexReader *) openDirectory: (id <LCDirectory>) directory 
                    close: (BOOL) close;
- (void) aquireWriteLock;

@end

@implementation LCIndexReader
  
  /**
   * Constructor used if IndexReader is not owner of its directory. 
   * This is used for IndexReaders that are used within other IndexReaders that take care or locking directories.
   * 
   * @param directory Directory where IndexReader files reside.
   */

- (id) initWithDirectory: (id <LCDirectory>) d
{
  self = [self init];
  ASSIGN(directory, d);
  return self;
}
  
  /**
   * Constructor used if IndexReader is owner of its directory.
   * If IndexReader is owner of its directory, it locks its directory in case of write operations.
   * 
   * @param directory Directory where IndexReader files reside.
   * @param segmentInfos Used for write-l
   * @param closeDirectory
   */
- (id) initWithDirectory: (id <LCDirectory>) dir
       segmentInfos: (LCSegmentInfos *) seg
       closeDirectory: (BOOL) close
{
  self = [self initWithDirectory: dir
	       segmentInfos: seg
	       closeDirectory: close
	       directoryOwner: YES];
  return self;
}

- (id) initWithDirectory: (id <LCDirectory>) dir        
	segmentInfos: (LCSegmentInfos *) seg        
	closeDirectory: (BOOL) close        
	directoryOwner: (BOOL) owner
{
  self = [self initWithDirectory: dir];
  ASSIGN(segmentInfos, seg);
  directoryOwner = owner;
  closeDirectory = close;
  return self;
}

/** Release the write lock, if needed. */
- (void) dealloc
{
#if 0
  protected void finalize() {
    if (writeLock != null) {
      writeLock.release();                        // release write lock
      writeLock = null;
  }
#endif
  DESTROY(directory);
  DESTROY(segmentInfos);
  [super dealloc];
}

+ (LCIndexReader *) openPath: (NSString *) path
{
  return [LCIndexReader openDirectory: [LCFSDirectory getDirectory: path create: NO] close: YES];
}

+ (LCIndexReader *) openDirectory: (id <LCDirectory>) dir
{
  return [LCIndexReader openDirectory: dir close: NO];
}

+ (LCIndexReader *) openDirectory: (id <LCDirectory>) dir
                    close: (BOOL) close
{
  LCSegmentInfos *infos = [[LCSegmentInfos alloc] init];
  AUTORELEASE(infos);
  [infos readFromDirectory: dir];
  if ([infos numberOfSegments] == 1)
    {
      return [LCSegmentReader segmentReaderWithInfos: infos
	               info: [infos segmentInfoAtIndex: 0]   close: close];
     }
  NSMutableArray *readers = [[NSMutableArray alloc] init];
  AUTORELEASE(readers);
  int i;
  for(i = 0; i < [infos numberOfSegments]; i++)
   {
     [readers addObject: [LCSegmentReader segmentReaderWithInfo: [infos segmentInfoAtIndex: i]]];
   }
     return AUTORELEASE([[LCMultiReader alloc] initWithDirectory: dir
	                                      segmentInfos: infos
	                                      close: close
	                                      readers: readers]);

}

  /** Returns the directory this index resides in. */
- (id <LCDirectory>) directory
{
  return directory; 
}

  /**
   * Reads version number from segments files. The version number counts the
   * number of changes of the index.
   * 
   * @param directory where the index resides.
   * @return version number.
   * @throws IOException if segments file cannot be read
   */
+ (long) currentVersionAtPath: (NSString *) path
{
  id <LCDirectory> dir = [LCFSDirectory getDirectory: path create: NO];
  long version = [LCIndexReader currentVersionWithDirectory: dir];
  [dir close];
  return version;
}

  /**
   * Reads version number from segments files. The version number counts the
   * number of changes of the index.
   * 
   * @param directory where the index resides.
   * @return version number.
   * @throws IOException if segments file cannot be read.
   */
+ (long) currentVersionWithDirectory: (id <LCDirectory>) dir
{
  return [LCSegmentInfos currentVersion: dir];
}

  /**
   *  Return an array of term frequency vectors for the specified document.
   *  The array contains a vector for each vectorized field in the document.
   *  Each vector contains terms and frequencies for all terms in a given vectorized field.
   *  If no such fields existed, the method returns null. The term vectors that are
   * returned my either be of type TermFreqVector or of type TermPositionsVector if
   * positions or offsets have been stored.
   * 
   * @param docNumber document for which term frequency vectors are returned
   * @return array of term frequency vectors. May be null if no term vectors have been
   *  stored for the specified document.
   * @throws IOException if index cannot be accessed
   * @see org.apache.lucene.document.Field.TermVector
   */
- (NSArray *) termFreqVectors: (int) number { return nil; }

  
  /**
   *  Return a term frequency vector for the specified document and field. The
   *  returned vector contains terms and frequencies for the terms in
   *  the specified field of this document, if the field had the storeTermVector
   *  flag set. If termvectors had been stored with positions or offsets, a 
   *  TermPositionsVector is returned.
   * 
   * @param docNumber document for which the term frequency vector is returned
   * @param field field for which the term frequency vector is returned.
   * @return term frequency vector May be null if field does not exist in the specified
   * document or term vector was not stored.
   * @throws IOException if index cannot be accessed
   * @see org.apache.lucene.document.Field.TermVector
   */
- (id <LCTermFreqVector>) termFreqVector: (int) docNumber
                       field: (NSString *) field
{ return nil; } 
  /**
   * Returns <code>true</code> if an index exists at the specified directory.
   * If the directory does not exist or if there is no index in it.
   * <code>false</code> is returned.
   * @param  directory the directory to check for an index
   * @return <code>true</code> if an index exists; <code>false</code> otherwise
   */
+ (BOOL) indexExistsAtPath: (NSString *) dir
{
  NSString *path = [dir stringByAppendingPathComponent: @"segments"];
  NSFileManager *manager = [NSFileManager defaultManager];
  BOOL isDir;
  if ([manager fileExistsAtPath: path isDirectory: &isDir] && !isDir)
    return YES;
  else
    return NO;
  }

  /**
   * Returns <code>true</code> if an index exists at the specified directory.
   * If the directory does not exist or if there is no index in it.
   * @param  directory the directory to check for an index
   * @return <code>true</code> if an index exists; <code>false</code> otherwise
   * @throws IOException if there is a problem with accessing the index
   */
+ (BOOL) indexExistsWithDirectory: (id <LCDirectory>) dir
{
  return [dir fileExists: @"segments"];
}

  /** Returns the number of documents in this index. */
  - (int) numberOfDocuments{ return 0; }

  /** Returns one greater than the largest possible document number.
   This may be used to, e.g., determine how big to allocate an array which
   will have an element for every document number in an index.
   */
   - (int) maximalDocument { return 0; }

  /** Returns the stored fields of the <code>n</code><sup>th</sup>
   <code>Document</code> in this index. */
   - (LCDocument *) document: (int) n { return nil; }

  /** Returns true if document <i>n</i> has been deleted */
  - (BOOL) isDeleted: (int) n { return NO; }

  /** Returns true if any documents have been deleted */
  - (BOOL) hasDeletions { return NO; }
  
  /** Returns the byte-encoded normalization factor for the named field of
   * every document.  This is used by the search code to score documents.
   *
   * @see Field#setBoost(float)
   */
- (NSData *) norms: (NSString *) field { return nil; }

  /** Reads the byte-encoded normalization factor for the named field of every
   *  document.  This is used by the search code to score documents.
   *
   * @see Field#setBoost(float)
   */
- (void) setNorms: (NSString *) field bytes: (NSMutableData *) bytes offset: (int) offset {}

  /** Expert: Resets the normalization factor for the named field of the named
   * document.  The norm represents the product of the field's {@link
   * Field#setBoost(float) boost} and its {@link Similarity#lengthNorm(String,
   * int) length normalization}.  Thus, to preserve the length normalization
   * values when resetting this, one should base the new value upon the old.
   *
   * @see #norms(String)
   * @see Similarity#decodeNorm(byte)
   */
- (void) setNorm: (int) doc field: (NSString *) field charValue: (char) value
{
  if (directoryOwner)
    [self aquireWriteLock];
  [self doSetNorm: doc field: field charValue: value];
  hasChanges = YES;
}
            
  /** Implements setNorm in subclass.*/
- (void) doSetNorm: (int) doc field: (NSString *) field charValue: (char) value {}

  /** Expert: Resets the normalization factor for the named field of the named
   * document.
   *
   * @see #norms(String)
   * @see Similarity#decodeNorm(byte)
   */
- (void) setNorm: (int) doc field: (NSString *) field floatValue: (float) value
{
  [self setNorm: doc field: field charValue: [LCSimilarity encodeNorm: value]];
}


  /** Returns an enumeration of all the terms in the index.
   The enumeration is ordered by Term.compareTo().  Each term
   is greater than all that precede it in the enumeration.
   */
- (LCTermEnum *) terms { return nil; };

  /** Returns an enumeration of all terms after a given term.
   The enumeration is ordered by Term.compareTo().  Each term
   is greater than all that precede it in the enumeration.
   */
- (LCTermEnum *) termsWithTerm: (LCTerm *) t { return nil; }

  /** Returns the number of documents containing the term <code>t</code>. */
- (long) documentFrequency: (LCTerm *) t { return 0; }

  /** Returns an enumeration of all the documents which contain
   <code>term</code>. For each document, the document number, the frequency of
   the term in that document is also provided, for use in search scoring.
   Thus, this method implements the mapping:
   <p><ul>
   Term &nbsp;&nbsp; =&gt; &nbsp;&nbsp; &lt;docNum, freq&gt;<sup>*</sup>
   </ul>
   <p>The enumeration is ordered by document number.  Each document number
   is greater than all that precede it in the enumeration.
   */
- (id <LCTermDocs>) termDocsWithTerm: (LCTerm *) term
{
  id <LCTermDocs> termDocs = [self termDocs];
  [termDocs seekTerm: term];
  return termDocs;
}
  
  /** Returns an unpositioned {@link TermDocs} enumerator. */
- (id <LCTermDocs>) termDocs { return nil; }

  /** Returns an enumeration of all the documents which contain
   <code>term</code>.  For each document, in addition to the document number
   and frequency of the term in that document, a list of all of the ordinal
   positions of the term in the document is available.  Thus, this method
   implements the mapping:

   <p><ul>
   Term &nbsp;&nbsp; =&gt; &nbsp;&nbsp; &lt;docNum, freq,
   &lt;pos<sub>1</sub>, pos<sub>2</sub>, ...
   pos<sub>freq-1</sub>&gt;
   &gt;<sup>*</sup>
   </ul>
   <p> This positional information faciliates phrase and proximity searching.
   <p>The enumeration is ordered by document number.  Each document number is
   greater than all that precede it in the enumeration.
   */
- (id <LCTermPositions>) termPositionsWithTerm: (LCTerm *) term
{
  id <LCTermPositions> termPositions = [self termPositions];
  [termPositions seekTerm: term];
  return termPositions;
}

  /** Returns an unpositioned {@link TermPositions} enumerator. */
  - (id <LCTermPositions>) termPositions { return nil; }
  
  /**
   * Tries to acquire the WriteLock on this directory.
   * this method is only valid if this IndexReader is directory owner.
   * 
   * @throws IOException If WriteLock cannot be acquired.
   */
   - (void) aquireWriteLock
   {
   #if 0
    if (stale)
      throw new IOException("IndexReader out of date and no longer valid for delete, undelete, or setNorm operations");

    if (writeLock == null) {
      Lock writeLock = directory.makeLock(IndexWriter.WRITE_LOCK_NAME);
      if (!writeLock.obtain(IndexWriter.WRITE_LOCK_TIMEOUT)) // obtain write lock
        throw new IOException("Index locked for write: " + writeLock);
      this.writeLock = writeLock;

      // we have to check whether index has changed since this reader was opened.
      // if so, this reader is no longer valid for deletion
      if (SegmentInfos.readCurrentVersion(directory) > segmentInfos.getVersion()) {
        stale = true;
        this.writeLock.release();
        this.writeLock = null;
        throw new IOException("IndexReader out of date and no longer valid for delete, undelete, or setNorm operations");
      }
    }
    #endif
  }
  
  /** Deletes the document numbered <code>docNum</code>.  Once a document is
   deleted it will not appear in TermDocs or TermPostitions enumerations.
   Attempts to read its field with the {@link #document}
   method will result in an error.  The presence of this document may still be
   reflected in the {@link #docFreq} statistic, though
   this will be corrected eventually as the index is further modified.
   */
   - (void) delete: (int) docNum
   {
   if (directoryOwner)
    [self aquireWriteLock];
   [self doDelete: docNum];
   hasChanges = YES;
   }

  /** Implements deletion of the document numbered <code>docNum</code>.
   * Applications should call {@link #delete(int)} or {@link #delete(Term)}.
   */
   - (void) doDelete: (int) docNum {}

  /** Deletes all documents containing <code>term</code>.
   This is useful if one uses a document field to hold a unique ID string for
   the document.  Then to delete such a document, one merely constructs a
   term with the appropriate field and the unique ID string as its text and
   passes it to this method.  Returns the number of documents deleted.
   See {@link #delete(int)} for information about when this deletion will 
   become effective.
   */
   - (int) deleteTerm: (LCTerm *) term
   {
    id <LCTermDocs> docs = [self termDocsWithTerm: term];
    if (docs == nil) return 0;
    int n = 0;
    while ([docs next])
    {
        [self delete: [docs document]];
        n++;
    }
    [docs close];
    return n;
  }

  /** Undeletes all documents currently marked as deleted in this index.*/
  - (void) undeleteAll
  {
    if(directoryOwner)
      [self aquireWriteLock];
    [self doUndeleteAll];
    hasChanges = YES;
  }
  
  /** Implements actual undeleteAll() in subclass. */
  - (void) doUndeleteAll {}

  /**
   * Commit changes resulting from delete, undeleteAll, or setNorm operations
   * 
   * @throws IOException
   */
   - (void) commit
   {
    if(hasChanges){
      if(directoryOwner){
               [self doCommit];
               [segmentInfos writeToDirectory:  directory];
               return;
      }
      else
        [self doCommit];
    }
    hasChanges = NO;
  }
  
  /** Implements commit. */
  - (void) doCommit {}
  
  /**
   * Closes files associated with this index.
   * Also saves any new deletions to disk.
   * No other methods should be called after this has been called.
   */
   - (void) close
   {
    [self commit];
    [self doClose];
    if (closeDirectory)
      [directory close];
      }

  /** Implements close. */
  - (void) doClose {}

  /**
   * Get a list of unique field names that exist in this index and have the specified
   * field option information.
   * @param fldOption specifies which field option should be available for the returned fields
   * @return Collection of Strings indicating the names of the fields.
   * @see IndexReader.FieldOption
   */
   - (NSArray *) fieldNames: (LCFieldOption) fieldOption { return nil; }

  /**
   * Returns <code>true</code> iff the index in the named directory is
   * currently locked.
   * @param directory the directory to check for a lock
   * @throws IOException if there is a problem with accessing the index
   */
   + (BOOL) isLocked: (id <LCDirectory>) dir
   {
#if 0
    return
            directory.makeLock(IndexWriter.WRITE_LOCK_NAME).isLocked() ||
            directory.makeLock(IndexWriter.COMMIT_LOCK_NAME).isLocked();
#endif
    return NO;
  }

  /**
   * Returns <code>true</code> iff the index in the named directory is
   * currently locked.
   * @param directory the directory to check for a lock
   * @throws IOException if there is a problem with accessing the index
   */
   - (BOOL) isLockedAtPath: (NSString *) dir
   {
   return YES;
   }
   #if 0
  public static boolean isLocked(String directory) throws IOException {
    Directory dir = FSDirectory.getDirectory(directory, false);
    boolean result = isLocked(dir);
    dir.close();
    return result;
  }
  #endif

  /**
   * Forcibly unlocks the index in the named directory.
   * <P>
   * Caution: this should only be used by failure recovery code,
   * when it is known that no other process nor thread is in fact
   * currently accessing this index.
   */
   - (void) unlock: (id <LCDirectory>) dir
   {
   #if 0
  public static void unlock(Directory directory) throws IOException {
    directory.makeLock(IndexWriter.WRITE_LOCK_NAME).release();
    directory.makeLock(IndexWriter.COMMIT_LOCK_NAME).release();
    #endif
  }
  
  /**
   * Prints the filename and size of each file within a given compound file.
   * Add the -extract flag to extract files to the current working directory.
   * In order to make the extracted version of the index work, you have to copy
   * the segments file from the compound index into the directory where the extracted files are stored.
   * @param args
   */
   #if 0
  public static void main(String [] args) {
    String dirname = null, filename = null;
    boolean extract = false;

    for (int i = 0; i < args.length; ++i) {
      if (args[i].equals("-extract")) {
        extract = true;
      } else if (dirname == null) {
        dirname = args[i];
      } else if (filename == null) {
        filename = args[i];
      }
    }

    if (dirname == null || filename == null) {
      System.out.println("Usage: org.apache.lucene.index.IndexReader [-extract] <directory> <cfsfile>");
      return;
    }

    Directory dir = null;
    CompoundFileReader cfr = null;
      
    try {
      dir = FSDirectory.getDirectory(dirname, false);

      cfr = new CompoundFileReader(dir, filename);

      String [] files = cfr.list();
      Arrays.sort(files);   // sort the array of filename so that the output is more readable
      
      for (int i = 0; i < files.length; ++i) {
        long len = cfr.fileLength(files[i]);

        if (extract) {
          System.out.println("extract " + files[i] + " with " + len + " bytes to local directory...");
          IndexInput ii = cfr.openInput(files[i]);

          FileOutputStream f = new FileOutputStream(files[i]);
          
          // read and write with a small buffer, which is more effectiv than reading byte by byte
          byte[] buffer = new byte[1024];
          int chunk = buffer.length;
          while(len > 0) {
            final int bufLen = (int) Math.min(chunk, len);
            ii.readBytes(buffer, 0, bufLen);
            f.write(buffer, 0, bufLen);
            len -= bufLen;
          }
          
          f.close();
          ii.close();
        }
        else
          System.out.println(files[i] + ": " + len + " bytes");
      }
    } catch (IOException ioe) {
      ioe.printStackTrace();
    }
    finally {
      try {
        if (dir != null)
          dir.close();
        if (cfr != null)
          cfr.close();
      }
      catch (IOException ioe) {
        ioe.printStackTrace();
      }
    }
  }
  #endif

@end
