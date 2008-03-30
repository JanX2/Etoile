#import <Foundation/Foundation.h>

@protocol ETSerialObjectStore <NSObject>
/**
 * Returns the branch that is the parent of the specified branch.
 */
- (NSString*) parentOfBranch:(NSString*)aBranch;
/**
 * Returns true if the specified branch exists.
 */
- (BOOL) isValidBranch:(NSString*)aBranch;
/**
 * Start a new version in the specified branch.  Subsequent data will be
 * written to this branch.
 */
- (void) startVersion:(unsigned)aVersion inBranch:(NSString*)aBranch;
/**
 * Writes the specified data to the store.
 */
- (void) writeBytes:(unsigned char*)bytes count:(unsigned)count;
/**
 * Interface for an object store that allows serial data to be written to it.
 */
- (NSData*) dataForVersion:(unsigned)aVersion inBranch:(NSString*)aBranch;
/**
 * Replaces the bytes in the specified range with (the same number of) new
 * bytes.
 */
- (void) replaceRange:(NSRange)aRange withBytes:(unsigned char*)bytes;
/**
 * Returns the amount of data written so far in this version.
 */
- (unsigned) size;
/**
 * Guarantees that the data is committed to the backing store.
 */
- (void) finalize;
/**
 * Returns the version currently being written, or the last version to be
 * written if the version is finalised.
 */
- (unsigned) version;
/**
 * Returns the branch currently being written, or the last branch to be
 * written if the version is finalised.
 */
- (NSString*) branch;
/**
 * Create a new branch from the specified parent branch.
 */
- (void) createBranch:(NSString*)newBranch from:(NSString*)oldBranch;
@end

@interface ETSerialObjectBuffer : NSObject <ETSerialObjectStore> {
	NSMutableData *buffer;
	unsigned version;
	NSString *branch;
}
/**
 * Returns the buffer for the current version.
 */
- (NSData*) buffer;
@end
/**
 * Object 'store' which simply logs the serialiser output to stdout.
 * Useful for debugging.
 */
@interface ETSerialObjectStdout : ETSerialObjectBuffer {}
@end

@interface  ETSerialObjectBundle : NSObject <ETSerialObjectStore> {
	FILE *file;
	NSString *bundlePath;
	unsigned version;
	NSString *branch;
}
- (id) initWithPath: (NSString *)aPath;
- (void) setPath:(NSString*)aPath;
@end
