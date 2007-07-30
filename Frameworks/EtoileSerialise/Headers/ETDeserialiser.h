/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>
#import "ETSerialiser.h"

/**
 * The ETDeserialiserBackend protocol is a formal protocol that must be
 * implemented by deserialiser backends.  
 */
@protocol ETDeserialiserBackend <NSObject>
/**
 * Use the specified URL as the data source.  Returns YES if the URL is of a
 * supported type and can be used for deserialisation, NO otherwise.
 */
- (BOOL) deserialiseFromURL:(NSURL*)aURL;
/**
 * Use the specified data when reading objects to deserialise.  Returns YES if
 * aData contains contains serialised object data in a format
 * understood by the backend.
 */
- (BOOL) deserialiseFromData:(NSData*)aData;
/**
 * Load the specified object.  Objects are stored with a unique ID within the
 * object graph.
 */
- (BOOL) deserialiseObjectWithID:(CORef)aReference;
/**
 * Specify the deserialiser to use.  When deserialiseObjectWithID: is called on
 * the backend, it will call methods in this deserialiser to actually perform
 * the deserialisation.
 */
- (void) setDeserialiser:(id)aDeserialiser;
/**
 * Return the reference of the principle object in the serialised object graph.  
 */
- (CORef) principalObject;
/**
 * Return the name of the class containing the principle object as a C string.
 */
- (char*) classNameOfPrincipalObject;
@end

//TODO: Move this into the implementation file and make it an opaque data type.
typedef struct 
{
	void * startOffset;
	int index;
	char type;
} ETDeserialiserState;

/**
 * <p>Custom deserialiser for a specific structure. </p>
<example>
void * custom_deserialiser(char* varName,
		void * aBlob,
		void * aLocation);
</example>
 * <p>The <code>varName</code> argument contains the name of the variable to
 * be deserialised, as set by the corresponding custom serialiser function.</p>
 * <p>The <code>aBlob</code> argument points </p>
 */
typedef void*(*custom_deserialiser)(char*,void*,void*);

/**
 * Deserialiser.  Performs construction of object graphs based on instructions
 * received from back end.  Each back end is expected to read data representing
 * serialised objects and pass it to an instance of this class to perform the
 * deserialisation.
 */
@interface ETDeserialiser : NSObject {
	/** The backend sending messages to this deserialiser. */
	id<ETDeserialiserBackend> backend;
	/** A mapping between CORef references and loaded objects, used to set
	 * object pointers to the correct value. */
	NSMapTable * loadedObjects;
	/** A mapping between pointers and the CORef references of the objects to
	 * which they should point.  Used to allow allow object a to be loaded
	 * before object b if a contains a pointer to b as an ivar. */
	NSMapTable * objectPointers;
	/** State machine stack. */
	//FIXME: Dynamically resize this.
	ETDeserialiserState states[20];
	/** Offset within the state machine stack of the top */
	int stackTop;
	/** Object currently being deserialised */
	id object;
	/** Flag indicating whether the current object is an invocation.  Used to
	 * to special case (read: ugly hack) deserialisation for invocations. */
	BOOL isInvocation;
	/** The version of the class being loaded.  Used by custom deserialisers to
	 * provide backwards compatibility. */
	int classVersion;
	/** Index of last loaded instance variable.  Used to accelerate lookup of
	 * the next one. */
	int loadedIVar;
	/** List of loaded object.  Iterated over to perform post-deserialisation
	 * tidy-up of loaded objects. */
	NSMutableArray * loadedObjectList;
	/** List of ETInvocationDeserialisers used to deserialise invocations in
	 * the object graph.  These should not be destroyed until after the
	 * invocations have been fired. */
	NSMutableArray * invocations;
}
/**
 * Returns a new deserialiser using the specified backend.
 */
+ (ETDeserialiser*) deserialiserWithBackend:(id<ETDeserialiserBackend>)aBackend;
/**
 * Register a custom deserialiser for a specific type of structure.  If a
 * custom deserialiser is registered for a specific type of structure then this
 * will have responsibility for loading fields in the specified structure
 * delegated to it.
 */
+ (void) registerDeserialiser:(custom_deserialiser)aDeserialiser forStructNamed:(char*)aName;
/**
 * Sets the back end which sends events to this deserialiser.
 */
- (void) setBackend:(id<ETDeserialiserBackend>)aBackend;
/**
 * Restore the principle object from the back end, and any objects referenced
 * by this object, recursively.
 */
- (id) restoreObjectGraph;
//Objects
/**
 * Begin deserialising an object which is an instance of aClass and
 * uniquely identified with aReference within the set of objects for
 * which the current backend instance is responsible.
 */
- (void) beginObjectWithID:(CORef)aReference withClass:(Class)aClass;
/**
 * Indicate that the object currently being loaded is now finished.
 */
- (void) endObject;
/**
 * Set the version of the class responsible for the next set of instance
 * variables to be loaded.  This will be called multiple times for an object
 * which is of a class which inherits from another class with instance
 * variables.  This value will be passed to the object's manual deserialisation
 * method, and can be used to implement deserialisation of older versions (or
 * even newer ones).
 */
- (void) setClassVersion:(int)aVersion;
/**
 * Set the instance variable aName, which is a object reference, to
 * the object referenced by aReference.  This may be deferred until
 * the object is loaded.
 */
- (void) loadObjectReference:(CORef)aReference withName:(char*)aName;
/**
 * Set the reference count of the object referenced by anObjectID to
 * aRefCount.
 */
- (void) setReferenceCountForObject:(CORef)anObjectID to:(int)aRefCount;
//Nested types
/**
 * Begin deserialising a structure.  All calls to the deserialiser between this
 * and the corresponding -endStruct call will be assumed to be fields within
 * the structure.
 */
- (void) beginStruct:(char*)aStructName withName:(char*)aName;
/**
 * End deserialising a C structure.
 */
- (void) endStruct;
/**
 * Begin an array, with the specified length.  All subsequent load commands
 * from the deserialiser until the corresponding -endArray call will be treated
 * as elements of this array.
 */
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
/**
 * End the current array and return to the previous deserialisation mode.
 */
- (void) endArray;
//Intrinsics
/**
 * Set the instance variable aName to the value of aChar.
 */
- (void) loadChar:(char)aChar withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aChar.
 */
- (void) loadUnsignedChar:(unsigned char)aChar withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aShort.
 */
- (void) loadShort:(short)aShort withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aShort.
 */
- (void) loadUnsignedShort:(unsigned short)aShort withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aInt.
 */
- (void) loadInt:(int)aInt withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aInt.
 */
- (void) loadUnsignedInt:(unsigned int)aInt withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aLong.
 */
- (void) loadLong:(long)aLong withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aLong.
 */
- (void) loadUnsignedLong:(unsigned long)aLong withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aLongLong.
 */
- (void) loadLongLong:(long long)aLongLong withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aLongLong.
 */
- (void) loadUnsignedLongLong:(unsigned long long)aLongLong withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aFloat.
 */
- (void) loadFloat:(float)aFloat withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aDouble.
 */
- (void) loadDouble:(double)aDouble withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aClass.
 */
- (void) loadClass:(Class)aClass withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aSelector.
 */
- (void) loadSelector:(SEL)aSelector withName:(char*)aName;
/**
 * Set the instance variable aName to the value of
 * aCString, copying the data.
 */
- (void) loadCString:(char*)aCString withName:(char*)aName;
/**
 * Set the instance variable aName to the value of aBlob,
 * copying the data.
 */
- (void) loadData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName;
@end
