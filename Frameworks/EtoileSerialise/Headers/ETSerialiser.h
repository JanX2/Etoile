/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>

/**
 * CoreObject reference type, used to uniquely identify serialised objects
 * within a serialised object graph.
 */
typedef uint32_t CORef;
/**
 * The ETSerialiserBackend protocol is a formal protocol defining the interface
 * for serialiser backends.  The backend is responsible for storing the data
 * passed to it representing instance variables of objects in a way that can be
 * read by a corresponding deserialiser backend.
 */
@protocol ETSerialiserBackend <NSObject>
//Setup
/**
 * Create a new instance of the back end writing to the specified URL
 */
+ (id) serialiserBackendWithURL:(NSURL*)anURL;
/**
 * Initialise a new instance with the specified URL.
 */
- (id) initWithURL:(NSURL*)anURL;
/**
 * Create a new version stored at the same URL.  How back ends handle multiple
 * versions is up to them.  They can treat the URL as a base, and append a
 * version number to each one, store the data separately within a single file,
 * or any other option. 
 */
- (int) newVersion;
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
 * Sent when an object has been completely serialised.
 */
- (void) endObject;
/**
 * Store a reference to an Objective-C object in the named instance variable.
 * This is equivalent to an id, but is not guaranteed to correspond to an
 * actual memory address either before or after serialisation.
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
 * used by the deserialiser to identify a custom structure deserialiser to use.
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
@end


#define MANUAL_DESERIALISE ((void*)1)
#define AUTO_DESERIALISE ((void*)0)
/**
 * Informal protocol for serialisable objects.  Implement this to manually
 * handle unsupported types.
 */
@interface NSObject (ETSerialisable)
/** 
 * Serialise the named variable with the given serialiser back end.  This
 * method should return YES if manual serialisation has occurred.  Returning NO
 * will cause the serialiser to attempt automatic serialisation.
 */
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend;
/**
 * Load the contents of the named instance variable from the contents of
 * aBlob.  The aVersion parameter indicates the version
 * of the class that serialised this instance variable as returned by +version.
 * This method should return MANUAL_DESERIALISE for cases if it completely
 * deserialises the variable or AUTO_DESERIALISE to cause the deserialiser to
 * automatically deserialise it.  If the deserialiser should load the variable
 * to a different location, it should return a pointer to the location.  An
 * example use of this would be when loading a structure-pointer or dynamic
 * array, where the memory should be allocated prior to deserialisation.
 */
- (void*) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion;
@end

/**
 * Type used for returns from type parser functions and custom structure
 * serialisers.  The size field should be set to the size of the
 * data serialised, and the offset field set to the size of the type
 * representation.  For custom structure serialisers, this will be
 * strlen(@encode(struct {structure name})).
 */
typedef struct 
{
	size_t size;
	unsigned int offset;
} parsed_type_size_t;

/**
 * Function type for custom structure serialisers.  The first argument contains
 * the name of the instance variable containing the structure.  The second
 * contains a pointer to the structure, and the third the back end to use for
 * serialisation.
 *
 * Functions of this form, if registered with the ETSerialiser class, will be
 * used to serialise named structures in objects.
 */
typedef parsed_type_size_t(*custom_serialiser)(char*,void*, id<ETSerialiserBackend>);

/**
 * The ETSerialiser class performs object serialisation.  It extracts the
 * instance variables and translates them into a stream of messages sent to a
 * class implementing the ETSerialiserBackend protocol, which handles the
 * storage of the serialised data.
 */
@interface ETSerialiser : NSObject {
	id<ETSerialiserBackend> backend;
	NSMutableSet * unstoredObjects;
	NSMutableSet * storedObjects;
	Class currentClass;
}
/**
 * Register a custom structure serialiser for the named struct type.
 */
+ (void) registerSerialiser:(custom_serialiser)aFunction forStruct:(char*)aName;
/**
 * Return a new serialiser using a backend of the specified class, writing to
 * the specified URL. 
 */
+ (ETSerialiser*) serialiserWithBackend:(Class)aBackend forURL:(NSURL*)anURL;
/**
 * Create a new version of the object graph.  This instructs the back end to
 * mark a new version.  CORef references are only guaranteed to be unique
 * within a single version.
 */
- (int) newVersion;
/**
 * Serialise the specified object.
 */
- (unsigned long long) serialiseObject:(id)anObject withName:(char*)aName;
@end
