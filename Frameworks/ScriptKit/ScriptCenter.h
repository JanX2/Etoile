#import <Foundation/Foundation.h>

@interface ScriptCenter : NSObject {
	/** Dictionary exported for scripting */
	NSMutableDictionary *dict;
}
/**
 * Returns a singleton instance of this class.
 */
+ (ScriptCenter*) sharedInstance;
/**
 * Enables scripting and publishes the specified dictionary.
 */
- (void) enableScriptingWithObjects:(NSDictionary*) scriptObjects;
/**
 * Enables scripting sharing only the application object.
 */
- (void) enableScripting;
/**
 * Add an object to this applications scripting dictionary.
 */
- (void) scriptObject:(id)anObject withName:(NSString*) aName;
/**
 * Returns the scripting dictionary for the named application.
 */
+ (NSDictionary*) scriptDictionaryForApplication:(NSString*) anApp;
/**
 * Returns the script dictionary for the currently active application.
 */
+ (NSDictionary*) scriptDictionaryForActiveApplication;
@end
