#import <Foundation/Foundation.h>

@class ETUUID, COBranchInfo, CORevisionID;

/**
 * Simple data structure returned by -[COSQLiteStore persistentRootInfoForUUID:]
 * to describe the entire state of a persistent root. It is a lightweight object
 * that mainly stores the list of branches and the revision ID of each branch.
 */
@interface COPersistentRootInfo : NSObject
{
@private
    ETUUID *uuid_;
    ETUUID *currentBranch_;
    NSMutableDictionary *branchForUUID_; // COUUID : COBranchInfo
    BOOL _deleted;
}

- (NSSet *) branchUUIDs;
- (NSArray *) branches;

- (COBranchInfo *)branchInfoForUUID: (ETUUID *)aUUID;
- (COBranchInfo *)currentBranchInfo;
/**
 * Convenience method that returns the current branch's current revision ID
 */
- (CORevisionID *)currentRevisionID;

@property (readwrite, nonatomic, strong) ETUUID *UUID;
@property (readwrite, nonatomic, strong) ETUUID *currentBranchUUID;
@property (readwrite, nonatomic, strong) NSDictionary *branchForUUID;
@property (readwrite, nonatomic, getter=isDeleted, setter=setDeleted:) BOOL deleted;

- (NSArray *)branchInfosWithMetadataValue: (id)aValue forKey: (NSString *)aKey;

@end