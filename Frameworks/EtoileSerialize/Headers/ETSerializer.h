/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>
#import <EtoileSerialize/ETSerializerBackend.h>
#import <EtoileSerialize/ETObjectStore.h>

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
