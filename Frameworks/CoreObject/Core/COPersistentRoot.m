/*
	Copyright (C) 2012 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>, 
	         Eric Wasylishen <ewasylishen@gmail.com>
	Date:  November 2012
	License:  Modified BSD  (see COPYING)
 */

#import "COPersistentRoot.h"
#import "COBranch.h"
#import "COBranch+Private.h"
#import "COEditingContext.h"
#import "COError.h"
#import "COItem.h"
#import "COObject.h"
#import "COObject+Private.h"
#import "COObjectGraphContext.h"
#import "COObjectGraphContext+Private.h"
#import "CORelationshipCache.h"
#import "CORevision.h"
#import "COSerialization.h"
#import "COSQLiteStore.h"
#import "COPersistentRootInfo.h"
#import "COCrossPersistentRootReferenceCache.h"
#import "COPersistentRootInfo.h"
#import "COBranchInfo.h"
#import "COEditingContext+Undo.h"
#import "COEditingContext+Private.h"

NSString * const COPersistentRootDidChangeNotification = @"COPersistentRootDidChangeNotification";

@implementation COPersistentRoot

@synthesize parentContext = _parentContext, UUID = _UUID;
@synthesize branchesPendingDeletion = _branchesPendingDeletion;
@synthesize branchesPendingUndeletion = _branchesPendingUndeletion;

- (id) initWithInfo: (COPersistentRootInfo *)info
cheapCopyRevisionID: (CORevisionID *)cheapCopyRevisionID
   parentBranchUUID: (ETUUID *)aBranchUUID
 objectGraphContext: (COObjectGraphContext *)anObjectGraphContext
      parentContext: (COEditingContext *)aCtxt
{
	if (info != nil)
    {
		INVALIDARG_EXCEPTION_TEST(anObjectGrapContext, anObjectGraphContext == nil);
    }
	if (anObjectGraphContext != nil)
	{
		INVALIDARG_EXCEPTION_TEST(info, info == nil);
		INVALIDARG_EXCEPTION_TEST(anObjectGraphContext, [anObjectGraphContext branch] == nil);
	}
	NILARG_EXCEPTION_TEST(aCtxt);

	SUPERINIT;
    
    _parentContext = aCtxt;
    _savedState =  info;
    _branchForUUID = [[NSMutableDictionary alloc] init];
	_branchesPendingDeletion = [NSMutableSet new];
	_branchesPendingUndeletion = [NSMutableSet new];
    
    if (_savedState != nil)
    {
        _UUID =  [_savedState UUID];
        
        for (COBranchInfo *branchInfo in [[_savedState branchForUUID] allValues])
        {
            [self updateBranchWithBranchInfo: branchInfo];
        }
        
        _currentBranchUUID =  [_savedState currentBranchUUID];
    }
    else
    {
        _UUID =  [ETUUID UUID];
        
        ETUUID *branchUUID = [ETUUID UUID];
        COBranch *branch = [[COBranch alloc] initWithUUID: branchUUID
		                                objectGraphContext: anObjectGraphContext
                                            persistentRoot: self
                                          parentBranchUUID: aBranchUUID
                                parentRevisionForNewBranch: cheapCopyRevisionID];
        
        [_branchForUUID setObject: branch forKey: branchUUID];
        
        _currentBranchUUID =  branchUUID;
        _cheapCopyRevisionID =  cheapCopyRevisionID;
    }

	return self;
}

#if 0
- (NSString *)description
{
	// TODO: Improve the indenting
	NSString *desc = [D([self insertedObjects], @"Inserted Objects",
	                    [self deletedObjects], @"Deleted Objects",
	                    _updatedPropertiesByObject, @"Updated Objects") description];
	/* For Mac OS X, see http://www.cocoabuilder.com/archive/cocoa/197297-who-broke-nslog-on-leopard.html */
	return [desc stringByReplacingOccurrencesOfString: @"\\n" withString: @"\n"];
}
#endif

- (BOOL)isPersistentRoot
{
	return YES;
}

- (COEditingContext *)editingContext
{
	return [self parentContext];
}

- (BOOL)isDeleted
{
    if ([[_parentContext persistentRootsPendingUndeletion] containsObject: self])
        return NO;
    
    if ([[_parentContext persistentRootsPendingDeletion] containsObject: self])
        return YES;
    
    if ([[_parentContext deletedPersistentRoots] containsObject: self])
        return YES;    
    
    return NO;
}

- (void)setDeleted: (BOOL)deleted
{
    if (deleted)
    {
        [_parentContext deletePersistentRoot: self];
    }
    else
    {
        [_parentContext undeletePersistentRoot: self];
    }
    [self sendChangeNotification];
}

- (NSDate *)modificationDate
{
	NSDate *maxDate = nil;

	for (COBranch *branch in [self branches])
	{
		NSDate *date = [[branch headRevision] date];

		if (maxDate != nil && [[date earlierDate: maxDate] isEqualToDate: date])
			continue;

		maxDate = date;
	}
	return maxDate;
}

- (NSDate *)creationDate
{
	return [[[self currentBranch] firstRevision] date];
}

- (COBranch *)currentBranch
{
	return [_branchForUUID objectForKey: _currentBranchUUID];
}

- (void)setCurrentBranch: (COBranch *)aBranch
{
    if ([self isPersistentRootUncommitted])
    {
		// TODO: Use a CoreObject exception type
        [NSException raise: NSGenericException
		            format: @"A persistent root must be committed before you "
		                     "can add or change its branches"];
    }

    _currentBranchUUID = [aBranch UUID];
    
    [self updateCrossPersistentRootReferences];
    [self sendChangeNotification];
}

- (COBranch *)editingBranch
{
    if (_editingBranchUUID == nil)
    {
        return [self currentBranch];
    }
    
	return [_branchForUUID objectForKey: _editingBranchUUID];
}

- (void)setEditingBranch: (COBranch *)aBranch
{
    if ([self isPersistentRootUncommitted])
    {
		// TODO: Use a CoreObject exception type
        [NSException raise: NSGenericException
		            format: @"A persistent root must be committed before you "
		                     "can add or change its branches"];
    }

    _editingBranchUUID = [aBranch UUID];
    
    [self sendChangeNotification];
}

- (NSSet *)branches
{
    return [NSSet setWithArray: [[_branchForUUID allValues] filteredCollectionWithBlock:
                                        ^(id obj) { return (BOOL)![obj isDeleted]; }]];
}

- (NSSet *)deletedBranches
{
    return [NSSet setWithArray: [[_branchForUUID allValues] filteredCollectionWithBlock:
                                        ^(id obj) { return (BOOL)[[obj branchInfo] isDeleted]; }]];
}

- (COBranch *)branchForUUID: (ETUUID *)aUUID
{
    return [_branchForUUID objectForKey: aUUID];
}

- (void)deleteBranch: (COBranch *)aBranch
{
    if ([aBranch isBranchUncommitted])
    {
        [_branchForUUID removeObjectForKey: [aBranch UUID]];
    }
	else if ([_branchesPendingUndeletion containsObject: aBranch])
	{
		[_branchesPendingUndeletion removeObject: aBranch];
	}
	else
	{
		[_branchesPendingDeletion addObject: aBranch];
	}
    
    [self updateCrossPersistentRootReferences];
	[self sendChangeNotification];
}

- (void)undeleteBranch: (COBranch *)aBranch
{
    if ([_branchesPendingDeletion containsObject: aBranch])
    {
        [_branchesPendingDeletion removeObject: aBranch];
    }
    else
    {
        [_branchesPendingUndeletion addObject: aBranch];
    }

    [self updateCrossPersistentRootReferences];
	[self sendChangeNotification];
}

- (COObjectGraphContext *)objectGraphContext
{
    return [[self editingBranch] objectGraphContext];
}

- (COSQLiteStore *)store
{
	return [_parentContext store];
}

- (id)rootObject
{
	return [[self objectGraphContext] rootObject];
}

- (void)setRootObject: (COObject *)aRootObject
{
	[[self objectGraphContext] setRootObject: aRootObject];
}

- (COObject *)objectWithUUID: (ETUUID *)uuid
{
	return [[self objectGraphContext] objectWithUUID: uuid];
}

- (NSSet *)branchesPendingInsertion
{
    return [[self branches] filteredCollectionWithBlock:
		                    ^(id obj) { return [obj isBranchUncommitted]; }];
}

- (NSSet *)branchesPendingUpdate
{
    return [[self branches] filteredCollectionWithBlock:
		                    ^(id obj) { return [obj hasChanges]; }];
}

- (BOOL)hasChanges
{
	if ([_branchesPendingDeletion count] > 0)
        return YES;
    
    if ([_branchesPendingUndeletion count] > 0)
        return YES;

	for (COBranch *branch in [self branches])
	{
		if ([branch isBranchUncommitted])
            return YES;

		if ([branch hasChanges])
			return YES;
	}
	return NO;
}

- (void)discardAllChanges
{
	/* Discard changes in branches */

	for (COBranch *branch in [self branches])
	{
		if ([branch isBranchUncommitted])
			continue;
		
		[branch discardAllChanges];
	}

	/* Clear branches pending insertion */
	
	NSArray *branchesPendingInsertion = [[self branchesPendingInsertion] allObjects];
	
	[_branchForUUID removeObjectsForKeys: (id)[[branchesPendingInsertion mappedCollection] UUID]];
	ETAssert([[self branchesPendingInsertion] isEmpty]);

	/* Clear other pending changes */

	[_branchesPendingDeletion removeAllObjects];
	[_branchesPendingUndeletion removeAllObjects];

	ETAssert([self hasChanges] == NO);
}

#pragma mark Committing Changes
#pragma mark -

- (BOOL)commitWithIdentifier: (NSString *)aCommitDescriptorId
					metadata: (NSDictionary *)additionalMetadata
				   undoTrack: (COUndoTrack *)undoTrack
                       error: (NSError **)anError
{
	NILARG_EXCEPTION_TEST(aCommitDescriptorId);
	INVALIDARG_EXCEPTION_TEST(additionalMetadata, [additionalMetadata containsKey: aCommitDescriptorId] == NO);

	NSMutableDictionary *metadata =
		[D(aCommitDescriptorId, kCOCommitMetadataIdentifier) mutableCopy];

	if (additionalMetadata != nil)
	{
		[metadata addEntriesFromDictionary: additionalMetadata];
	}
	return [_parentContext commitWithMetadata: metadata
		          restrictedToPersistentRoots: A(self)
								withUndoTrack: undoTrack
	                                    error: anError];
}

- (BOOL)commit
{
	// TODO: Should call -commitWithIdentifier:metadata:undoTrack:error:
	return [self commitWithType: nil shortDescription: nil];
}

// TODO: Remove
- (BOOL)commitWithType: (NSString *)type
      shortDescription: (NSString *)shortDescription
{
	NSString *commitType = type;
	
	if (type == nil)
	{
		commitType = @"Unknown";
	}
	if (shortDescription == nil)
	{
		shortDescription = @"";
	}
	return [self commitWithMetadata: D(shortDescription, @"shortDescription", commitType, @"type")];
}

- (BOOL)commitWithMetadata: (NSDictionary *)metadata
{
	return [_parentContext commitWithMetadata: metadata
                  restrictedToPersistentRoots: A(self)
								withUndoTrack: nil
	                                    error: NULL];
}

- (BOOL)isPersistentRootUncommitted
{
    return _savedState == nil;
}

- (void)saveCommitWithMetadata: (NSDictionary *)metadata
               transactionUUID: (ETUUID *)transactionUUID
{
	// FIXME: This also rejects changes during undeleted->deleted transition,
	// while COBranch's equivelant doesn't. Probably should allow changes
	// to be combined with delet sion in a single commit; change that
	// and add tests for that.
	if ([self hasChanges] && self.isDeleted)
	{
		[NSException raise: NSGenericException
					format: @"Attempted to commit changes to deleted persistent root %@", self];
	}
	
    _lastTransactionUUID =  transactionUUID;
    
	ETAssert([[self rootObject] isRoot]);
    
	COSQLiteStore *store = [_parentContext store];
    //CORevisionID *revId;
    
	if ([self isPersistentRootUncommitted])
	{		
        ETAssert([self editingBranch] != nil);
        ETAssert([self editingBranch] == [self currentBranch]);
        
        if (_cheapCopyRevisionID == nil)
        {
            _savedState = [store createPersistentRootWithInitialItemGraph: [[self editingBranch] objectGraphContext]
                                                                     UUID: [self UUID]
                                                               branchUUID: [[self editingBranch] UUID]
                                                         revisionMetadata: metadata
                                                                    error: NULL];
        }
        else
        {
			// Committing a cheap copy, so there must be a parent branch
			ETUUID *parentBranchUUID = [[[self editingBranch] parentBranch] UUID];
			ETAssert(parentBranchUUID != nil);
			
            _savedState = [store createPersistentRootWithInitialRevision: _cheapCopyRevisionID
																	UUID: _UUID
															  branchUUID: [[self editingBranch] UUID]
														parentBranchUUID: parentBranchUUID
																   error: NULL];
        }
        ETAssert(_savedState != nil);
		CORevisionID *initialRevID = [[_savedState currentBranchInfo] currentRevisionID];
		ETAssert(initialRevID != nil);

        [_parentContext recordPersistentRootCreation: self
		                         atInitialRevisionID: initialRevID];
        
        
        //revId = [[info currentBranchInfo] currentRevisionID];
        
        // N.B., we don't call -saveCommitWithMetadata: on the branch,
        // because the store call -createPersistentRootWithInitialContents:
        // handles creating the initial branch.
        
        [[self editingBranch] didMakeInitialCommitWithRevisionID: initialRevID];
	}
    else
    {
        // Commit changes in our branches
        
        // N.B. Don't use -branches because that only returns non-deleted branches
        for (COBranch *branch in [_branchForUUID allValues])
        {
            [branch saveCommitWithMetadata: metadata];
        }
        
        // Commit a change to the current branch, if needed.
        // Needs to be done after because the above loop may create the branch
        if (![[_savedState currentBranchUUID] isEqual: _currentBranchUUID])
        {
            ETAssert([store setCurrentBranch: _currentBranchUUID
                           forPersistentRoot: [self UUID]
                                       error: NULL]);
            [_parentContext recordPersistentRoot: self
                                setCurrentBranch: [self currentBranch]
                                       oldBranch: [self branchForUUID: [_savedState currentBranchUUID]]];
        }
        
        // N.B.: Ugly, the ordering of changes needs to be carefully controlled
        for (COBranch *branch in [_branchForUUID allValues])
        {
            [branch saveDeletion];
        }
    }

	ETAssert([[self branchesPendingInsertion] isEmpty]);
	[_branchesPendingDeletion removeAllObjects];
	[_branchesPendingUndeletion removeAllObjects];
}

- (COPersistentRootInfo *)persistentRootInfo
{
    return _savedState;
}

- (void)reloadPersistentRootInfo
{
    COPersistentRootInfo *newInfo =
		[[self store] persistentRootInfoForUUID: [self UUID]];
    if (newInfo != nil)
    {
        _savedState =  newInfo;
    }
}

- (void)didMakeNewCommit
{
	[self reloadPersistentRootInfo];
	
	for (COBranch *branch in [self branches])
	{
		[branch updateRevisions];
	}
}

- (COBranch *)makeBranchWithLabel: (NSString *)aLabel
                       atRevision: (CORevision *)aRev
                     parentBranch: (COBranch *)aParent
{
    COBranch *newBranch = [[COBranch alloc] initWithUUID: [ETUUID UUID]
	                                  objectGraphContext: nil
                                          persistentRoot: self
                                        parentBranchUUID: [aParent UUID]
                              parentRevisionForNewBranch: [aRev revisionID]];
    
    [newBranch setMetadata: D(aLabel, @"COBranchLabel")];
    
    [_branchForUUID setObject: newBranch forKey: [newBranch UUID]];
    
    return newBranch;
}

- (COBranch *)makeBranchWithUUID: (ETUUID *)aUUID
                        metadata: (NSDictionary *)metadata
                      atRevision: (CORevision *)aRev
                    parentBranch: (COBranch *)aParent
{
    COBranch *newBranch = [[COBranch alloc] initWithUUID: aUUID
                                      objectGraphContext: nil
                                          persistentRoot: self
                                        parentBranchUUID: [aParent UUID]
                              parentRevisionForNewBranch: [aRev revisionID]];
    
    if (metadata != nil)
    {
        [newBranch setMetadata: metadata];
    }
    
    [_branchForUUID setObject: newBranch forKey: [newBranch UUID]];
    
    return newBranch;
}

- (CORevision *)currentRevision
{
    return [[self editingBranch] currentRevision];
}

- (void)setCurrentRevision: (CORevision *)revision
{
    [[self editingBranch] setCurrentRevision: revision];
}

- (CORevision *)headRevision
{
    return [[self editingBranch] headRevision];
}

- (void)setHeadRevision: (CORevision *)revision
{
    [[self editingBranch] setHeadRevision: revision];
}

- (void)updateBranchWithBranchInfo: (COBranchInfo *)branchInfo
{
    COBranch *branch = [_branchForUUID objectForKey: [branchInfo UUID]];
    
    if (branch == nil)
    {
        branch = [[COBranch alloc] initWithUUID: [branchInfo UUID]
                             objectGraphContext: nil
                                 persistentRoot: self
                               parentBranchUUID: [branchInfo parentBranchUUID]
                     parentRevisionForNewBranch: nil];
        
        [_branchForUUID setObject: branch forKey: [branchInfo UUID]];
    }
    else
    {
        [branch updateWithBranchInfo: branchInfo];
    }
}

- (void)storePersistentRootDidChange: (NSNotification *)notif
                       isDistributed: (BOOL)isDistributed
{
    ETUUID *notifTransaction = [ETUUID UUIDWithString:
		[[notif userInfo] objectForKey: kCOPersistentRootTransactionUUID]];
    if ([_lastTransactionUUID isEqual: notifTransaction])
    {
//        NSLog(@"----Ignoring update notif %@ %d", _lastTransactionUUID, (int)isDistributed);
        return;
    }
//    NSLog(@"++++Not Ignoring update notif (%@, %@, %d)", _lastTransactionUUID, notifTransaction, (int)isDistributed);
    
    COPersistentRootInfo *info =
		[[self store] persistentRootInfoForUUID: [self UUID]];
    _savedState =  info;
    
    for (ETUUID *uuid in [info branchUUIDs])
    {
        COBranchInfo *branchInfo = [info branchInfoForUUID: uuid];
        [self updateBranchWithBranchInfo: branchInfo];
    }
    
    _currentBranchUUID =  [_savedState currentBranchUUID];
    _lastTransactionUUID = notifTransaction;
    
	// TODO: Remove or support
    //[self sendChangeNotification];
}

- (void)updateCrossPersistentRootReferences
{
    NSArray *objs = [[_parentContext crossReferenceCache] affectedObjectsForChangeInPersistentRoot: [self UUID]];
    
    for (COObject *obj in objs)
    {
        [obj updateCrossPersistentRootReferences];
    }
    
    // TODO: May need something like this?
//    for (COBranch *branch in [_branchForUUID allValues])
//    {
//        COObjectGraphContext *graph = [branch objectGraphContext];
//        for (COObject *obj in [graph allObjects])
//        {
//            NSArray *persistentRoots = [[_parentContext crossReferenceCache] referencedPersistentRootUUIDsForObject: obj];
//            for (ETUUID *persistentRootUUID in persistentRoots)
//            {
//                COPersistentRoot *persistentRoot = [_parentContext persistentRootForUUID: persistentRootUUID];
//                for (COBranch *otherBranch in [persistentRoot->_branchForUUID allValues])
//                {
//                    COObjectGraphContext *otherGraph = [otherBranch objectGraphContext];
//                    [[otherGraph rootObject] updateCrossPersistentRootReferences];                    
//                }
//            }
//        }
//    }
}

- (void)sendChangeNotification
{
    [[NSNotificationCenter defaultCenter]
		postNotificationName: COPersistentRootDidChangeNotification
		              object: self];
}

- (COObjectGraphContext *)objectGraphContextForPreviewingRevision: (CORevision *)aRevision
{
    COObjectGraphContext *ctx = [[COObjectGraphContext alloc]
		initWithModelRepository: [[self editingContext] modelRepository]];
    id <COItemGraph> items = [[self store] itemGraphForRevisionID: [aRevision revisionID]];

    [ctx setItemGraph: items];

    return ctx;
}

@end
