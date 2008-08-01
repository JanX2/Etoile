//
//  StanzaFactory.h
//  Jabber
//
//  Created by David Chisnall on 24/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * The StanzaFactory class is a base class, subclassed to provide iq, presence and
 * message stanza factories.  When parsing an XMPP stanza, the classes used to 
 * parse the children and the keys with which they should be returned to the 
 * parent node are defined in one of these subclasses.
 *
 * The StanzaFactory class should be treated as abstract.
 *
 * Every occurrence of the word 'Value' in this class should be replaced with 'Key'
 * by someone who has some spare time.
 */
@interface StanzaFactory : NSObject {
	NSMutableDictionary * tagHandlers;
	NSMutableDictionary * tagValues;
	NSMutableDictionary * namespacedTagHandlers;
	NSMutableDictionary * namespacedTagValues;
}
/**
 * Returns the singleton stanza factory.  
 */
+ (id) sharedStazaFactory;
/**
 * Add a handler for a given child tag.  When parsing encounters a tag with the 
 * specified name, the given class will be instantiated and the value it returns
 * will be passed to the handler identified by aValue.
 */
- (void) addHandler:(Class)aHandler withValue:(NSString*)aValue forTag:(NSString*)aTag;
/**
 * In cases where the same tag exists in a number of namespaces, this variant can
 * be used to differentiate between them.
 */
- (void) addHandler:(Class)aHandler withValue:(NSString*)aValue forTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;

/**
 * Add a handler independent of the key used to return it to the parent.
 */
- (void) addHandler:(Class)aHandler forTag:(NSString*)aTag;
/**
 * Set the key used to return a value to the parent, without setting a 
 * corresponding handler class.
 */
- (void) addValue:(NSString*)aValue forTag:(NSString*)aTag;
/**
 * Add a namespace-specific handler.
 */
- (void) addHandler:(Class)aHandler forTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;
/**
 * Add a namespace-specific key.
 */
- (void) addValue:(NSString*)aValue forTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;
/**
 * Always returns nil.  Not entirely sure why this is here...
 */
- (id) parser;
/**
 * Returns the handler for a specified (un-namespaced) XML tag.
 */
- (Class) handlerForTag:(NSString*)aTag;
/**
 * Returns the handler for a specified XML tag in the given namespace.
 */
- (Class) handlerForTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;
/**
 * Returns the key for a specified XML tag.
 */
- (NSString*) valueForTag:(NSString*)aTag;
/**
 * Returns the key for a specified XML tag in the given namespace.
 */
- (NSString*) valueForTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;
@end

