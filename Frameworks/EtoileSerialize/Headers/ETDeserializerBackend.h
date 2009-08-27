/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>
#import <EtoileSerialize/ETUtility.h>

/**
 * The ETDeserializerBackend protocol is a formal protocol that must be
 * implemented by deserializer backends.  
 */
@protocol ETDeserializerBackend <NSObject>

/**
 * Use the specified store as the data source.  Returns YES if the store is of
 * a supported type and can be used for deserialization, NO otherwise.
 */
- (BOOL) deserializeFromStore:(id)store;

/**
 * Use the specified data when reading objects to deserialize.  Returns YES if
 * aData contains contains serialized object data in a format
 * understood by the backend.
 */
- (BOOL) deserializeFromData:(NSData*)aData;

/**
 * Set the branch from which to deserialize.
 */
- (BOOL) setBranch:(NSString*)aBranch;

/**
 * Jump to the specified version.  Returns -1 if the specified version does not
 * exist, otherwise returns the requested version.
 */
- (int) setVersion:(int)aVersion;

/**
 * Load the specified object.  Objects are stored with a unique ID within the
 * object graph.
 */
- (BOOL) deserializeObjectWithID:(CORef)aReference;

/**
 * Load the principal object of the stored object graph.
 */
- (BOOL) deserializePrincipalObject;

/**
  * Handle the deserialization of data identified by an unknown type.
  * TODO: Probably make it a delegate method of the backend.
  */
- (BOOL) deserializeData:(char*)obj withTypeChar:(char)type;
/**
 * Specify the deserializer to use.  When deserializeObjectWithID: is called on
 * the backend, it will call methods in this deserializer to actually perform
 * the deserialization.
 */
- (void) setDeserializer:(id)aDeserializer;
/**
 * Return the reference of the principle object in the serialized object graph.  
 */
- (CORef) principalObject;
/**
 * Return the name of the class containing the principle object as a C string.
 */
- (char*) classNameOfPrincipalObject;
@end

