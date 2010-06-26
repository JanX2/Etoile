#import <Foundation/Foundation.h>

@class ETSocket;

@protocol ETSerialObjectStore <NSObject>
/**
 * Returns the branch that is the parent of the specified branch.
 */
- (NSString *) parentOfBranch: (NSString *)aBranch;
/**
 * Returns true if the specified branch exists.
 */
- (BOOL) isValidBranch:(NSString *)aBranch;
/**
 * Start a new version in the specified branch.  Subsequent data will be
 * written to this branch.
 */
- (void) startVersion: (unsigned int)aVersion inBranch: (NSString *)aBranch;
/**
 * Writes the specified data to the store.
 */
- (void) writeBytes: (unsigned char *)bytes count: (unsigned int)count;
/**
 * Interface for an object store that allows serial data to be written to it.
 */
- (NSData *) dataForVersion: (unsigned int)aVersion inBranch: (NSString *)aBranch;
/**
 * Returns the amount of data written so far in this version.
 */
- (unsigned int) size;
/**
 * Guarantees that the data is committed to the backing store.
 */
- (void) commit;
/**
 * Returns the version currently being written, or the last version to be
 * written if the version is finalised.
 */
- (unsigned int) version;
/**
 * Returns the branch currently being written, or the last branch to be
 * written if the version is finalised.
 */
- (NSString *) branch;
/**
 * Creates a new branch from the specified parent branch.
 */
- (void) createBranch: (NSString *)newBranch from: (NSString *)oldBranch;
@end

@protocol ETSeekableObjectStore <ETSerialObjectStore>
/**
 * Replaces the bytes in the specified range with (the same number of) new
 * bytes.
 */
- (void) replaceRange: (NSRange)aRange withBytes: (unsigned char *)bytes;
@end


@interface ETSerialObjectBuffer : NSObject <ETSeekableObjectStore> {
	NSMutableData *buffer;
	unsigned version;
	NSString *branch;
}
/**
 * Returns the buffer for the current version.
 */
- (NSData *) buffer;
@end

/**
 * Object 'store' which simply logs the serialiser output to stdout.
 * Useful for debugging.
 */
@interface ETSerialObjectStdout : ETSerialObjectBuffer {}
@end

/**
 * Object 'store' which sends data over the network to the specified host.
 */
@interface ETSerialObjectSocket : ETSerialObjectBuffer {
	/** The socket */
	ETSocket *socket;
}
/**
 * Initializes the store pointing to the specified host and network service.
 * Defaults to using the CoreObject service (which must exist in
 * /etc/services in order to work).
 * */
- (id) initWithRemoteHost: (NSString *)aHost forService: (NSString *)aService;
@end

@interface  ETSerialObjectBundle : NSObject <ETSeekableObjectStore> {
	FILE *file;
	NSString *bundlePath;
	unsigned version;
	NSString *branch;
}
- (id) initWithPath: (NSString *)aPath;
- (void) setPath: (NSString *)aPath;
@end
