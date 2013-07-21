/*
	Copyright (C) 2011 Christopher Armstrong

	Author:  Christopher Armstrong <carmstrong@fastmail.com.au>,
	         Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2011
	License:  Modified BSD  (see COPYING)
 */

#import "COBranch.h"
#import "COEditingContext.h"
#import "COPersistentRoot.h"
#import "COSQLiteStore.h"
#import "COObject.h"
#import "CORevision.h"
#import "FMDatabase.h"
#import "CORevisionInfo.h"
#import "COObjectGraphContext.h"

@implementation COBranch

@synthesize UUID = _UUID;
@synthesize persistentRoot = _persistentRoot;
@synthesize objectGraph = _objectGraph;
@synthesize metadata = _metadata;

- (id)init
{
	[self doesNotRecognizeSelector: _cmd];
	return nil;
}

/* Both root object and revision are lazily retrieved by the persistent root. 
   Until the loaded revision is known, it is useless to cache track nodes. */
- (id)        initWithUUID: (ETUUID *)aUUID
            persistentRoot: (COPersistentRoot *)aContext
parentRevisionForNewBranch: (CORevisionID *)parentRevisionForNewBranch
{
	NILARG_EXCEPTION_TEST(aUUID);
	NSParameterAssert([aUUID isKindOfClass: [ETUUID class]]);
	NILARG_EXCEPTION_TEST(aContext);

	if ([[aContext parentContext] store] == nil)
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"Cannot load commit track for %@ which does not have a store or editing context", aContext];
	}

	SUPERINIT;

    ASSIGN(_UUID, aUUID);
        
	/* The persistent root retains us */
	_persistentRoot = aContext;

    _objectGraph = [[COObjectGraphContext alloc] initWithBranch: self];
    
    if ([_persistentRoot persistentRootInfo] != nil
        && parentRevisionForNewBranch == nil)
    {
        // Loading an existing branch
        
        COBranchInfo *branchInfo = [self branchInfo];
        ETAssert(branchInfo != nil);
        
        ASSIGN(_currentRevisionID, [branchInfo currentRevisionID]);
        ASSIGN(_metadata, [branchInfo metadata]);
        _isCreated = YES;
                
        id<COItemGraph> aGraph = [[_persistentRoot store] contentsForRevisionID: _currentRevisionID];
        [_objectGraph setItemGraph: aGraph];
    }
    else
    {
        // Creating a new branch
        
        ASSIGN(_currentRevisionID, parentRevisionForNewBranch);
        _isCreated = NO;
        
        // If _parentRevisionID is nil, we're a new branch for a new persistent root
        // Otherwise, we're a new branch for an existing (committed) persistent root
        
        if (_currentRevisionID != nil)
        {
            id<COItemGraph> aGraph = [[_persistentRoot store] contentsForRevisionID: _currentRevisionID];
            [_objectGraph setItemGraph: aGraph];
            
            ETAssert(![_objectGraph hasChanges]);
        }
    }
    
	return self;	
}


- (void)dealloc
{
	DESTROY(_UUID);
    DESTROY(_currentRevisionID);
    DESTROY(_metadata);
    DESTROY(_objectGraph);
	[super dealloc];
}

- (BOOL) isBranchUncommitted
{
    return _isCreated == NO;
}

- (BOOL) isBranchPersistentRootUncommitted
{
    return _currentRevisionID == nil && _isCreated == NO;
}

- (BOOL)isEqual: (id)rhs
{
	if ([rhs isKindOfClass: [COBranch class]])
	{
		return ([_UUID isEqual: [rhs UUID]]
			&& [[_persistentRoot persistentRootUUID] isEqual: [[rhs persistentRoot] persistentRootUUID]]);
	}
	return NO;
}

- (NSString *)displayName
{
	NSString *label = [self label];
	NSString *displayName = [[[self persistentRoot] rootObject] displayName];
	
	if (label != nil && [label isEqual: @""] == NO)
	{
		displayName = [displayName stringByAppendingFormat: @" (%@)", label];
	}
	return displayName;
}

- (BOOL)isCopy
{
    // FIXME: Implement
    return NO;
}

- (BOOL)isBranch
{
    return YES;
//	return ([self isCopy] == NO && [self parentTrack] != nil);
}

- (BOOL)isCurrentBranch
{
    return self == [_persistentRoot currentBranch];
}

- (BOOL)isTrunkBranch
{
	// FIXME: Implement by reading from our metadata dictionary
	return NO;
}

- (COBranchInfo *) branchInfo
{
    COPersistentRootInfo *persistentRootInfo = [[self persistentRoot] persistentRootInfo];
    COBranchInfo *branchInfo = [persistentRootInfo branchInfoForUUID: _UUID];
    return branchInfo;
}

- (CORevisionInfo *) currentRevisionInfo
{
    // WARNING: Accesses store
    CORevisionID *revid = _currentRevisionID;
    COSQLiteStore *store = [[self persistentRoot] store];
    
    if (revid != nil)
    {
        return [store revisionInfoForRevisionID: revid];
    }
    return nil;
}

- (NSString *)label
{
    // FIXME: Make a standardized metadata key for this
	return [_metadata objectForKey: @"COBranchLabel"];
}

- (CORevision *)parentRevision
{
    // WARNING: Accesses store
    CORevisionID *revid = [[self branchInfo] tailRevisionID];
    COSQLiteStore *store = [[self persistentRoot] store];
    
    if (revid != nil)
    {
        return [CORevision revisionWithStore: store revisionID: revid];
    }
    
    return nil;
}

- (CORevision *)newestRevision
{
    // WARNING: Accesses store
    CORevisionID *revid = [[self branchInfo] headRevisionID];
    COSQLiteStore *store = [[self persistentRoot] store];
    
    if (revid != nil)
    {
        return [CORevision revisionWithStore: store revisionID: revid];
    }
    
    return nil;
}

- (CORevision *)currentRevision
{
    // WARNING: Accesses store
    CORevisionInfo *info = [self currentRevisionInfo];
    if (info != nil)
    {
        return [[[CORevision alloc] initWithStore: [[self persistentRoot] store]
                                     revisionInfo: info] autorelease];
    }
    return nil;
}

- (void) setCurrentRevision:(CORevision *)currentRevision
{
    ASSIGN(_currentRevisionID, [currentRevision revisionID]);
    [self reloadAtRevision: currentRevision];
}

- (COBranch *)parentTrack
{
    // FIXME: Add support for this
    return nil;
}

- (COBranch *)makeBranchWithLabel: (NSString *)aLabel
{
    if ([self isBranchUncommitted])
    {
        [NSException raise: NSGenericException format: @"uncommitted branches do not support -makeBranchWithLabel:"];
    }
    
	return [self makeBranchWithLabel: aLabel atRevision: [self currentRevision]];
}

- (COBranch *)makeBranchWithLabel: (NSString *)aLabel atRevision: (CORevision *)aRev
{
    if ([self isBranchUncommitted])
    {
        [NSException raise: NSGenericException format: @"uncommitted branches do not support -makeBranchWithLabel:atRevision:"];
    }
    
    return [_persistentRoot makeBranchWithLabel: aLabel atRevision: aRev];
}

- (COPersistentRoot *)makeCopyFromRevision: (CORevision *)aRev
{
    return [[[self persistentRoot] editingContext] insertNewPersistentRootWithRevisionID: [aRev revisionID]];
}

- (BOOL)mergeChangesFromTrack: (COBranch *)aSourceTrack
{
	return NO;
}

- (BOOL)mergeChangesFromRevision: (CORevision *)startRev
							  to: (CORevision *)endRev
						 ofTrack: (COBranch *)aSourceTrack
{
	return NO;
}

- (BOOL)mergeChangesFromRevisionSet: (NSSet *)revs
							ofTrack: (COBranch *)aSourceTrack
{
	return NO;
}

- (BOOL)isOurStoreForNotification: (NSNotification *)notif
{
    // FIXME: Implement
    return YES;
//	NSString *storeUUIDString = [[notif userInfo] objectForKey: kCOStoreUUIDStringKey];
//	return [storeUUIDString isEqual: [[[[self persistentRoot] store] UUID] stringValue]];
}

/* This method is called back through distributed notifications in various cases:
   - a commit calling -addRevision:toTrackUUID:
   - a selective undo or redo (this is the same than the previous case since 
     this results in a new commit)
   - an undo or redo calling -undoOnTrackUUID:
   In each case, the track posting the notification can be either the receiver 
   or another instance (in the same or another process) bearing the same UUID.
   For an undo/redo, when the track triggering the notification is the receiver, 
   then we return immediately to prevent updating the currentNodeIndex already 
   updated in -undo and -redo methods.
   When the receiver is not the track posting the notification, the two track 
   instances are not located in the same editing context. */
- (void)currentNodeDidChangeInStore: (NSNotification *)notif
{
    // FIXME: Implement
#if 0
	/* Paranoid check in case something goes wrong and a core object UUID
	   appear in multiple stores.
	   For now, a core object UUID is bound to a single store. Hence a commit
	   track UUID is never in use accross multiple stores (using distinct UUIDs).  */
	if ([self isOurStoreForNotification: notif])
		return;

	NSParameterAssert([[[self UUID] stringValue] isEqual: [notif object]]);

	COEditingContext *context = [[self persistentRoot] parentContext];
	int64_t revNumber = [[[notif userInfo] objectForKey: kCONewCurrentNodeRevisionNumberKey] longLongValue];
	BOOL isBasicUndoRedoFromCurrentContext = (revNumber == [[[self currentNode] revision] revisionNumber]);
	BOOL isCommitFromCurrentContext = (revNumber == [context latestRevisionNumber]);

	/* Distributed notifications are ignored in the cases below: 
	   - -undo or -redo was invoked on the receiver
	   - a tracked object editing context commit (see also -didMakeNewAtRevision:)
	 
	   This method updates the track nodes in the cases below:
	   - -undo or -redo was invoked on another receiver instance in some other editing context
	   - a commit on another tracked object instance in some other editing context
	   - a selective undo
	
	   For each track UUID, this method requires that a single track instance 
	   exists per editing context. */
	if (isBasicUndoRedoFromCurrentContext || isCommitFromCurrentContext)
		return;

	COTrackNode *oldCurrentNode = RETAIN([self currentNode]);

	[self reloadNodes];

	// FIXME: The currentNodeIndex assertion requires that distributed 
	// notifications to be delivered (but the notification center might drop 
	// some notifications under heavy load according to Cocoa API doc)
	assert([[self currentNode] isEqual: oldCurrentNode] == NO);
	assert([self currentNode] != nil);
	assert(revNumber == [[[self currentNode] revision] revisionNumber]);

	/* For a commit in the receiver editing context, no reloading occurs 
	   because the tracked object state matches the revision */
	[[self persistentRoot] reloadAtRevision: [[self currentNode] revision]];

	[self didUpdate];
	RELEASE(oldCurrentNode);
#endif
}

- (BOOL)needsReloadNodes: (NSArray *)currentLoadedNodes
{
	return NO;
}

- (NSArray *)allNodesAndCurrentNodeIndex: (NSUInteger *)aNodeIndex
{
    return [NSArray array];
//	// NOTE: For a new track, -[COSQLStore isTrackUUID:] would return NO
//	
//	COStore *store = [[self persistentRoot] store];
//	return [store nodesForTrackUUID: [self UUID]
//	                    nodeBuilder: self
//	               currentNodeIndex: aNodeIndex
//	                  backwardLimit: NSUIntegerMax
//	                   forwardLimit: NSUIntegerMax];
}

- (NSArray *)provideNodesAndCurrentNodeIndex: (NSUInteger *)aNodeIndex
{
	return [self allNodesAndCurrentNodeIndex: aNodeIndex];
}

- (void)undo
{
    CORevision *revision = [[self currentRevision] parentRevision];
    if (revision == nil)
    {
        return;
    }
    [self setCurrentRevision: revision];
}

- (void)redo
{
    CORevision *currentRevision = [self currentRevision];
    CORevision *revision = [self newestRevision];
    
    if ([currentRevision isEqual: revision])
    {
        return;
    }
    
    while (revision != nil)
    {
        CORevision *revisionParent = [revision parentRevision];
        if ([revisionParent isEqual: currentRevision])
        {
            [self setCurrentRevision: revision];
            return;
        }
        revision = revisionParent;
    }
}
- (COSQLiteStore *) store
{
    return [_persistentRoot store];
}

- (void)discardAllChanges
{
	for (COObject *object in [_objectGraph changedObjects])
	{
		[self discardChangesInObject: object];
	}
	assert([_objectGraph hasChanges] == NO);
}

- (void)discardChangesInObject: (COObject *)object
{
    if (_currentRevisionID != nil)
    {
        COItem *item = [[self store] item: [object UUID]
                             atRevisionID: _currentRevisionID];
        
        [_objectGraph addItem: item];
        [_objectGraph clearChangeTrackingForObject: object];
    }
}

- (void)saveCommitWithMetadata: (NSDictionary *)metadata
{
	ETAssert([[_objectGraph rootObject] isRoot]);
    ETAssert(![self isBranchPersistentRootUncommitted]);
    ETAssert(_currentRevisionID != nil);
    
	COSQLiteStore *store = [self store];
    
    int64_t changeCount = [[_persistentRoot persistentRootInfo] changeCount];
    
	if ([self isBranchUncommitted])
	{
        // N.B. - this only the case when we're adding a new branch to an existing persistent root.
        
        [store createBranchWithUUID: _UUID
                    initialRevision: _currentRevisionID
                  forPersistentRoot: [[self persistentRoot] persistentRootUUID]
                              error: NULL];
        
        [store setMetadata: _metadata
                 forBranch: _UUID
          ofPersistentRoot: [[self persistentRoot] persistentRootUUID]
                     error: NULL];
        
        _isCreated = YES;
    }
    else if (![[[self branchInfo] currentRevisionID] isEqual: _currentRevisionID])
    {
        // This is the case when the user does [self setCurrentRevision: ], and then commits
        
        BOOL ok = [store setCurrentRevision: _currentRevisionID
                               headRevision: nil /* This is the case when we're reverting, so don't update headRevision */
                               tailRevision: nil
                                  forBranch: _UUID
                           ofPersistentRoot: [[self persistentRoot] persistentRootUUID]
                         currentChangeCount: &changeCount
                                      error: NULL];
        ETAssert(ok);
    }
    
    NSArray *changedItemUUIDs = [(NSSet *)[[[_objectGraph changedObjects] mappedCollection] UUID] allObjects];
    if ([changedItemUUIDs count] > 0)
    {
        CORevisionID *revId = [store writeContents: _objectGraph
                                      withMetadata: metadata
                                  parentRevisionID: _currentRevisionID
                                     modifiedItems: changedItemUUIDs
                                             error: NULL];        
        
        BOOL ok = [store setCurrentRevision: revId
                               headRevision: revId
                               tailRevision: nil
                                  forBranch: _UUID
                           ofPersistentRoot: [[self persistentRoot] persistentRootUUID]
                         currentChangeCount: &changeCount
                                      error: NULL];
        ETAssert(ok);
        
        ASSIGN(_currentRevisionID, revId);
    }
	
	[_objectGraph clearChangeTracking];
}

- (void)didMakeInitialCommitWithRevisionID: (CORevisionID *)aRevisionID
{
    ETAssert(_isCreated == NO);
    
    ASSIGN(_currentRevisionID, aRevisionID);
    _isCreated = YES;
    
    [_objectGraph clearChangeTracking];
    
    ETAssert([[_objectGraph changedObjects] count] == 0);
}

- (void)reloadAtRevision: (CORevision *)revision
{
    NSParameterAssert(revision != nil);
    
    // TODO: Use optimized method on the store to get a delta for more performance
    
	id<COItemGraph> aGraph = [[self store] contentsForRevisionID: [revision revisionID]];
    
    [_objectGraph setItemGraph: aGraph];
    
    // FIXME: Reimplement or remove
    //[[self rootObject] didReload];
}

@end
