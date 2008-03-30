/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>
#import <EtoileSerialize/ETObjectStore.h>

/** 
 * Turn a pointer into a CORef.
 */
//TODO: 64-bit version of this.
#define COREF_FROM_ID(x) ((CORef)(unsigned long)x)
/**
 * CoreObject reference type, used to uniquely identify serialized objects
 * within a serialized object graph.
 */
typedef uint32_t CORef;
/**
 * The ETSerializerBackend protocol is a formal protocol defining the interface
 * for serializer backends.  The backend is responsible for storing the data
 * passed to it representing instance variables of objects in a way that can be
 * read by a corresponding deserializer backend.
 */
@protocol ETSerializerBackend <NSObject>
//Setup
/**
 * Create a new instance of the back end writing to the specified store
 */
+ (id) serializerBackendWithStore:(id<ETSerialObjectStore>)aStore;
/**
 * <init /> 
 * Initialise a new instance with the specified store.
 */
- (id) initWithStore:(id<ETSerialObjectStore>)aStore;
/**
 * Returns the deserializer backend class which is the mirror of this
 * serializer.
 */
+ (Class) deserializer;
/**
 * Returns a deserializer backend instance initialised with the same data
 * source (URL or data) as this serializer.
 */
- (id) deserializer;
/**
 * Perform any initialisation required on the new version.
 */
- (void) startVersion:(int)aVersion;
/**
 * Ensures data has been written.
 */
- (void) flush;
//Objects
/**
 * Store the class version to be associated with the next set of instance
 * variables.
 */
- (void) setClassVersion:(int)aVersion;
/**
 * Begin a new object of the specified class.  All subsequent messages until
 * the corresponding -endObject message should be treated as belonging to this
 * object.
 *
 * Note that unlike structures and arrays, objects will not be nested.
 */
- (void) beginObjectWithID:(CORef)aReference withName:(char*)aName withClass:(Class)aClass;
/**
 * Sent when an object has been completely serialized.
 */
- (void) endObject;
/**
 * Store a reference to an Objective-C object in the named instance variable.
 * This is equivalent to an id, but is not guaranteed to correspond to an
 * actual memory address either before or after serialization.
 */
- (void) storeObjectReference:(CORef)aReference withName:(char*)aName;
/**
 * Increment the reference count for the object with the specified reference.
 */
- (void) incrementReferenceCountForObject:(CORef)anObjectID;
//Nested types
/**
 * Begin storing a structure.  Subsequent messages will correspond to fields in
 * this structure until a corresponding -endStruct message is received.
 *
 * The aStructName stores the name of the structure type.  This is
 * used by the deserializer to identify a custom structure deserializer to use.
 */
- (void) beginStruct:(char*)aStructName withName:(char*)aName;
/**
 * Mark the end of a structure.
 */
- (void) endStruct;
/**
 * Begin an array of the specified length.
 */
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
/**
 * Mark the end of an array.
 */
- (void) endArray;
//Intrinsics
/**
 * Store the value aChar for the instance variable aName.
 */
- (void) storeChar:(char)aChar withName:(char*)aName;
/**
 * Store the value aChar for the instance variable aName.
 */
- (void) storeUnsignedChar:(unsigned char)aChar withName:(char*)aName;
/**
 * Store the value aShort for the instance variable aName.
 */
- (void) storeShort:(short)aShort withName:(char*)aName;
/**
 * Store the value aShort for the instance variable aName.
 */
- (void) storeUnsignedShort:(unsigned short)aShort withName:(char*)aName;
/**
 * Store the value aInt for the instance variable aName.
 */
- (void) storeInt:(int)aInt withName:(char*)aName;
/**
 * Store the value aInt for the instance variable aName.
 */
- (void) storeUnsignedInt:(unsigned int)aInt withName:(char*)aName;
/**
 * Store the value aLong for the instance variable aName.
 */
- (void) storeLong:(long)aLong withName:(char*)aName;
/**
 * Store the value aLong for the instance variable aName.
 */
- (void) storeUnsignedLong:(unsigned long)aLong withName:(char*)aName;
/**
 * Store the value aLongLong for the instance variable aName.
 */
- (void) storeLongLong:(long long)aLongLong withName:(char*)aName;
/**
 * Store the value aLongLong for the instance variable aName.
 */
- (void) storeUnsignedLongLong:(unsigned long long)aLongLong withName:(char*)aName;
/**
 * Store the value aFloat for the instance variable aName.
 */
- (void) storeFloat:(float)aFloat withName:(char*)aName;
/**
 * Store the value aDouble for the instance variable aName.
 */
- (void) storeDouble:(double)aDouble withName:(char*)aName;
/**
 * Store the value aClass for the instance variable aName.
 */
- (void) storeClass:(Class)aClass withName:(char*)aName;
/**
 * Store the value aChar for the instance variable aName.
 */
- (void) storeSelector:(SEL)aSelector withName:(char*)aName;
/**
 * Store the value aCString for the instance variable
 * aName.  The backend should ensure it copies the string, rather
 * than simply retaining a reference to it.
 */
- (void) storeCString:(const char*)aCString withName:(char*)aName;
/**
 * Store the value aBlob for the instance variable aName.
 * The data should be copied by the backend.
 */
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName;
/**
 * Stores an UUID reference for the instance variable aName. 
 */
- (void) storeUUID: (char *)uuid withName: (char *)aName;
@end


#define MANUAL_DESERIALISE ((void*)1)
#define AUTO_DESERIALISE ((void*)0)

/**
 * Type used for returns from type parser functions and custom structure
 * serializers.  The size field should be set to the size of the
 * data serialized, and the offset field set to the size of the type
 * representation.  For custom structure serializers, this will be
 * strlen(@encode(struct {structure name})).
 */
typedef struct 
{
	size_t size;
	unsigned int offset;
} parsed_type_size_t;

/**
 * Function type for custom structure serializers.  The first argument contains
 * the name of the instance variable containing the structure.  The second
 * contains a pointer to the structure, and the third the back end to use for
 * serialization.
 *
 * Functions of this form, if registered with the ETSerializer class, will be
 * used to serialize named structures in objects.
 */
typedef parsed_type_size_t(*custom_serializer)(char*,void*, id<ETSerializerBackend>);

/**
 * The ETSerializer class performs object serialization.  It extracts the
 * instance variables and translates them into a stream of messages sent to a
 * class implementing the ETSerializerBackend protocol, which handles the
 * storage of the serialized data.
 */
@interface ETSerializer : NSObject {
	id<ETSerializerBackend> backend;
	id store;
	NSMutableSet * unstoredObjects;
	NSMutableSet * storedObjects;
	Class currentClass;
	/** Version of the object currently being written */
	int objectVersion;
	/** Name of the current branch */
	NSString *branch;
}
/**
 * Register a custom structure serializer for the named struct type.
 */
+ (void) registerSerializer:(custom_serializer)aFunction forStruct:(char*)aName;
/**
 * Return a new serializer using a backend of the specified class, writing to
 * the specified URL. 
 */
+ (ETSerializer*) serializerWithBackend:(Class)aBackendClass forURL:(NSURL*)anURL;
/**
 * Create a new version of the object graph stored at -URL. CORef references are 
 * only guaranteed to be unique within a single version. 
 * By default this class stores a serialized object graph in a directory with 
 * the following layout:
 * 
 * How other object stores handle the storage layout and multiple versions is up 
 * to subclasses. They can treat the URL as a base, and append a version number 
 * to each one, store the data separately within a single record or file, or any 
 * other option. 
 */
- (int) newVersion;
/**
 * Creates a new version of the object graph with the specified version number.
 */
- (int) setVersion:(int)aVersion;
/**
 * Serialize the specified object.
 */
- (unsigned long long) serializeObject:(id)anObject withName:(char*)aName;
/**
 * Add an object to the queue of unstored objects if we haven't loaded it yet,
 * or increment its reference count if we have.
 */ 
- (void) enqueueObject:(id)anObject;
/**
 * Returns the size of the value to be stored for the object at the given 
 * address and known by instance variable aName.
 */
- (size_t) storeObjectFromAddress:(void*) anAddress withName:(char*) aName;
/**
 * Retrieves the back end used by this serializer.
 */
- (id<ETSerializerBackend>) backend;
@end
/**
 * Informal protocol for serializable objects.  Implement this to manually
 * handle unsupported types.
 */
@interface NSObject (ETSerializable)
/** 
 * Serialize the named variable with the given serializer back end.  This
 * method should return YES if manual serialization has occurred.  Returning NO
 * will cause the serializer to attempt automatic serialization.
 */
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer;
/**
 * Load the contents of the named instance variable from the contents of
 * aBlob.  The aVersion parameter indicates the version
 * of the class that serialized this instance variable as returned by +version.
 * This method should return MANUAL_DESERIALISE for cases if it completely
 * deserializes the variable or AUTO_DESERIALISE to cause the deserializer to
 * automatically deserialize it.  If the deserializer should load the variable
 * to a different location, it should return a pointer to the location.  An
 * example use of this would be when loading a structure-pointer or dynamic
 * array, where the memory should be allocated prior to deserialization.
 */
- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion;
@end
