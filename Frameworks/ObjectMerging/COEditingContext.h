#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class COStore, CORevision, COObject, COCommitTrack;

/**
 * An object context is like a working copy in a revision control system.
 *
 * It queues changes and then attempts to commit them to the store.
 */
@interface COEditingContext : NSObject
{
	@private
	COStore *_store;
	int64_t _maxRevisionNumber;

	ETModelDescriptionRepository *_modelRepository;

	NSMutableDictionary *_rootObjectRevisions; // UUID of root object -> revision mapping
	NSMutableDictionary *_rootObjectCommitTracks; // UUID of root object -> commit track

	NSMutableDictionary *_instantiatedObjects; // UUID -> COObject mapping
	NSMutableSet *_insertedObjects;
	NSMutableSet *_deletedObjects;
	/**
	 * Note: never modify directly; call -markObjectDamaged/-markObjectUndamaged instead.
	 * Otherwise the cached value in COObject won't be updated.
	 */
	NSMapTable *_updatedPropertiesByObject; // Updated object -> updated properties
}

/** @taskunit Accessing the current context */

/** 
 * Returns the context that should be used when none is provided.
 *
 * Factories that create persistent instances in EtoileUI will use this method. 
 * As an example, see -[ETLayoutItemFactory compoundDocument]. 
 */
+ (COEditingContext *)currentContext;
/** 
 * Sets the context that should be used when none is provided.
 *
 * See also +currentContext. 
 */
+ (void)setCurrentContext: (COEditingContext *)aCtxt;

/** @taskunit Creating a new context */

/**
 * Returns a new autoreleased context initialized with the store located at the 
 * given URL, and with no upper limit on the max revision number.
 *
 * See also -initWithStore:maxRevisionNumber: and -[COStore initWithURL:].
 */
+ (COEditingContext *)contextWithURL: (NSURL *)aURL;

/**
 * Initializes a context which persists its content in the given store.
 */
- (id)initWithStore: (COStore *)store;

/**
 * <init />
 * Initializes a context which persists its content in the given store, 
 * fixing the maximum revision number that can be loaded of an object.
 *
 * If the store is nil, the context content is not persisted.
 *
 * If maxRevisionNumber is zero, then there is no upper limit on the revision 
 * that can be loaded.
 */
- (id)initWithStore: (COStore *)store maxRevisionNumber: (int64_t)maxRevisionNumber;
/**
 * Initializes the context with no store. 
 * As a result, the context content is not persisted.
 */
- (id)init;

/** @taskunit Store and Metamodel Access */

/**
 * Returns the store for which the editing context acts a working copy.
 */
- (COStore *)store;
/**
 * Returns the model description repository, which holds the metamodel that 
 * describes all the persistent objects editable in the context.
 */
- (ETModelDescriptionRepository *)modelRepository;
/**
 * Returns the class bound to the entity description in the model repository.
 */
- (Class)classForEntityDescription: (ETEntityDescription *)desc;

/** @taskunit Object Access and Loading */

/** 
 * Returns the object identified by the UUID, by loading it to its last revision 
 * when no instance managed by the receiver is present in memory.
 *
 * When the UUID doesn't correspond to a persistent object, returns nil.
 *
 * When the object is a inner object, the last revision is the one that is tied  
 * to its root object last revision.
 *
 * See also -objectWithUUID:atRevision: and -loadedObjectForUUID:.
 */
- (COObject *)objectWithUUID: (ETUUID *)uuid;
/** 
 * Returns the object identified by the UUID, by loading it to the given 
 * revision when no instance managed by the receiver is present in memory.
 *
 * When the UUID doesn't correspond to a persistent object, returns nil.
 *
 * For a nil revision, the object is loaded is loaded at its last revision.
 *
 * When the object is a inner object, the last revision is the one that is tied  
 * to its root object last revision. 
 *
 * When the object is already loaded, and its revision is not the requested 
 * revision, raises an invalid argument exception.
 *
 * See also -loadedObjectForUUID:. */
- (COObject *)objectWithUUID: (ETUUID *)uuid atRevision: (CORevision *)revision;

/**
 * Returns the objects presently managed by the receiver in memory.
 *
 * Faults can be included among the returned objects.
 */
- (NSSet *)loadedObjects;
/**
 * Returns the root objects presently managed by the receiver in memory.
 *
 * Faults can be included among the returned objects.
 *
 * The returned objects are a subset of -loadedObjects.
 */
- (NSSet *)loadedRootObjects;
/** Returns the object identified by the UUID if presently loaded in memory. 
 *
 * When the object is not loaded, or when there is no persistent object that 
 * corresponds to this UUID, returns nil.
 */
- (id)loadedObjectForUUID: (ETUUID *)uuid;

/** @taskunit Pending Changes */

/** 
 * Returns the new objects added to the context with -insertObject: and to be 
 * added to the store on the next commit.
 *
 * After a commit, returns an empty set.
 */
- (NSSet *)insertedObjects;
/** 
 * Returns the objects whose properties have been edited in the context and to 
 * be updated in the store on the next commit.
 *
 * After a commit, returns an empty set.
 */
- (NSSet *)updatedObjects;
/**
 * Returns the UUIDs of the objects updated since the last commit. See -updatedObjects.
 */
- (NSSet *)updatedObjectUUIDs;
/**
 * Returns whether the object has been updated since the last commit. See 
 * -updatedObjects.
 *
 * Won't return YES if the object has just been inserted or deleted.
 */
- (BOOL)isUpdatedObject: (COObject *)anObject;
/** 
 * Returns the objects deleted in the context with -deleteObject: and to be 
 * deleted in the store on the next commit.
 *
 * After a commit, returns an empty set.
 *
 * Doesn't include newly inserted or deleted objects.
 */
- (NSSet *)deletedObjects;
/** 
 * Returns the union of the inserted, updated and deleted objects. See 
 * -insertedObjects, -updatedObjects and -deletedObjects.
 *
 * After a commit, returns an empty set.
 */
- (NSSet *)changedObjects;
/**
 * Returns whether any object has been inserted, deleted or updated since the 
 * last commit.
 *
 * See also -changedObjects.
 */
- (BOOL)hasChanges;

/** @taskunit Object Insertion */

/**
 * Creates a new instance of the given entity name (assigning the instance a new UUID)
 * and returns the object.
 *
 * The new instance is a root object.
 *
 * See also -insertObjectWithEntityName:rootObject:.
 */
- (id)insertObjectWithEntityName: (NSString *)aFullName;
/**
 * Creates a new instance of the given entity name (assigning the instance a new UUID)
 * under the specified root object and returns the object. 
 *
 * The entity name must correspond to the COObject class or a subclass. Thereby 
 * returned objects will be COObject class or subclass instances in all cases.
 *
 * When rootObject is nil, the new instance is a root object.
 * 
 * This is the factory method for COObject class hierarchy.
 */
- (id)insertObjectWithEntityName: (NSString *)aFullName rootObject: (COObject *)rootObject;
/**
 * Creates a new instance of the given class (assigning the instance a new UUID)
 * and returns the object.
 *
 * When rootObject is nil, the new instance is a root object.
 *
 * See also -insertObjectWithEntityName:rootObject:.
 */
- (id)insertObjectWithClass: (Class)aClass rootObject: (COObject *)rootObject;
/**
 * Copies an object from another context into this context.
 *
 * The copy refers to the same underlying persistent object (same UUID).
 */
- (id)insertObject: (COObject *)sourceObject;
/**
 * Creates a copy of an object (assigning it a new UUID), including copying
 * all strongly contained objects (composite properties).
 */
- (id)insertObjectCopy: (COObject *)sourceObject;

/** @taskunit Object Deletion */

/**
 * Schedules the object to be deleted both in memory and in store on the next 
 * commit.
 */
- (void)deleteObject: (COObject *)anObject;

/** @taskunit Committing Changes */

/**
 * Commits the current changes to the store.
 */
- (void)commit;
/**
 * Commits the current changes to the store with some basic metadatas.
 *
 * The descriptions will be visible at the UI level when browsing the history.
 */
- (void)commitWithType: (NSString *)type
      shortDescription: (NSString *)shortDescription
       longDescription: (NSString *)longDescription;

/** @taskunit Private */

- (id)insertObject: (COObject *)sourceObject withRelationshipConsistency: (BOOL)consistency newUUID: (BOOL)newUUID;
- (void)commitWithMetadata: (NSDictionary *)metadata;

@end


@interface COEditingContext (PrivateToCOObject)

- (void) markObjectDamaged: (COObject*)obj forProperty: (NSString*)aProperty;
- (void) markObjectUndamaged: (COObject*)obj;
- (void) loadObject: (COObject*)obj;
- (void) loadObject: (COObject*)obj atRevision: (CORevision*)aRevision;
- (CORevision*)revisionForObject: (COObject*)object;
- (COCommitTrack*)commitTrackForObject: (COObject*)object;
- (COObject*) objectWithUUID: (ETUUID*)uuid entityName: (NSString*)name atRevision: (CORevision*)revision;
- (COObject*) objectWithUUID: (ETUUID*)uuid entityName: (NSString*)name;
@end



@interface COEditingContext (Rollback)

// Manipulation of the editing context itself - rather than the store

- (void) discardAllChanges;
- (void) discardAllChangesInObject: (COObject*)object;

/**
  * Reload the object at a new revision.
  */
- (void)reloadRootObjectTree: (COObject*)object
                  atRevision: (CORevision*)revision;

@end

