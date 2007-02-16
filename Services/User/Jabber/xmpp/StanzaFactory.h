//
//  StanzaFactory.h
//  Jabber
//
//  Created by David Chisnall on 24/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StanzaFactory : NSObject {
	NSMutableDictionary * tagHandlers;
	NSMutableDictionary * tagValues;
	NSMutableDictionary * namespacedTagHandlers;
	NSMutableDictionary * namespacedTagValues;
}
+ (id) sharedStazaFactory;
- (void) addHandler:(Class)aHandler withValue:(NSString*)aValue forTag:(NSString*)aTag;
- (void) addHandler:(Class)aHandler withValue:(NSString*)aValue forTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;

- (void) addHandler:(Class)aHandler forTag:(NSString*)aTag;
- (void) addValue:(NSString*)aValue forTag:(NSString*)aTag;
- (void) addHandler:(Class)aHandler forTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;
- (void) addValue:(NSString*)aValue forTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;
- (id) parser;
- (Class) handlerForTag:(NSString*)aTag;
- (Class) handlerForTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;
- (NSString*) valueForTag:(NSString*)aTag;
- (NSString*) valueForTag:(NSString*)aTag inNamespace:(NSString*)aNamespace;
@end

