#import "LKAST.h"
#import "LKCompiler.h"

@class LKSubclass;
@class LKCategory;
@class SCKSourceCollection;

/**
 * AST node representing a module - a set of classes and categories compiled
 * together.
 */
@interface LKModule : LKAST
{
  /** Classes defined in this module. */
  NSMutableArray *classes;
  /** Categories defined in this module. */
  NSMutableArray *categories;
  /** Current pragmas */
  NSMutableDictionary *pragmas;
  /** Manually-specified method types. */
  NSMutableDictionary *typeOverrides;
}
/**
 * Return a new autoreleased module.
 */
+ (id) module;
/**
 * Returns the source collection used for resolving symbols that are not
 * visible at run time.
 */
+ (SCKSourceCollection*)sourceCollection;
/**
 * Add compile-time pragmas.
 */
- (void) addPragmas: (NSDictionary*)aDict;
/**
 * Add a new class to this module.
 */
- (void) addClass: (LKSubclass*)aClass;
/**
 * Add a new category to this module.
 */
- (void) addCategory: (LKCategory*)aCategory;
/**
 * Returns YES if this selector is used with two or more types.
 */
- (BOOL)isSelectorPolymorphic: (NSString*)methodName;
/**
 * Returns the type that should be used for a given selector.
 */
- (const char*) typeForMethod:(NSString*)methodName;
/**
 * Returns the classes in this module
 */
- (NSArray*) allClasses;
/**
 * Returns the categories in this module
 */
- (NSArray*) allCategories;
/**
 * Returns the pragmas in this module
 */
- (NSDictionary*) pragmas;
@end

/**
 * Notification posted when new classes have been compiled.
 */
extern NSString *LKCompilerDidCompileNewClassesNotification;
