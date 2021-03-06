#import <Foundation/NSObject.h>

@class NSString;
@class NSAttributedString;
@class SCKSourceLocation;
@class NSMutableArray;
@class NSMutableDictionary;

/**
 * SCKProgramComponent is an abstract class representing properties of some
 * component of a program.  This includes classes, functions, methods, and so
 * on.
 *
 * Program components in SourceCodeKit can be obtained both by runtime
 * introspection and by parsing source code.  
 */
@interface SCKProgramComponent : NSObject
/**
 * The name of this program component.
 */
@property (nonatomic, retain) NSString *name;
/**
 * The location where the component is defined, if visible.  
 */
@property (nonatomic, retain) SCKSourceLocation *definition;
/**
 * The location where the component is declared, if visible.  
 */
// FIXME: We should allow multiple declaration locations.
@property (nonatomic, retain) SCKSourceLocation *declaration;
/**
 * Documentation associated with this object.  This may be generated by an IDE,
 * extracted from headers, or read from some external source.
 */
@property (nonatomic, retain) NSAttributedString *documentation;
/**
 * The parent of this component.  
 */
@property (nonatomic, unsafe_unretained) SCKProgramComponent *parent;
@end

/**
 * A program component with a type.
 */
@interface SCKTypedProgramComponent : SCKProgramComponent
/** Objective-C type encoding of the component. */
@property (retain, nonatomic) NSString *typeEncoding;
@end

@interface SCKBundle : SCKProgramComponent
/**
 * All of the public symbols exported by the bundle.
 */
@property (retain, nonatomic) NSMutableArray *classes;
@property (retain, nonatomic) NSMutableArray *functions;
@end

@interface SCKClass : SCKProgramComponent
@property (nonatomic, unsafe_unretained) SCKClass *superclass;
@property (nonatomic, readonly, retain) NSMutableArray *subclasses;
@property (nonatomic, readonly, retain) NSMutableDictionary *categories;
@property (nonatomic, readonly, retain) NSMutableDictionary *methods;
@property (nonatomic, readonly, retain) NSMutableArray *ivars;
@property (nonatomic, readonly, retain) NSMutableArray *properties;
@property (nonatomic, readonly, retain) NSMutableArray *macros;
- (id) initWithClass: (Class)cls;
@end

@interface SCKCategory : SCKProgramComponent
@property (nonatomic, readonly, retain) NSMutableDictionary *methods;
@end

@interface SCKMethod : SCKTypedProgramComponent
@property (nonatomic) BOOL isClassMethod;
@end

@interface SCKIvar : SCKTypedProgramComponent
@end

@interface SCKFunction : SCKTypedProgramComponent
@end

@interface SCKGlobal : SCKTypedProgramComponent
@end

@interface SCKProperty : SCKTypedProgramComponent
@end

@interface SCKMacro : SCKTypedProgramComponent
@end

/**
 * Enumerated type value.  This encapsulates the name and value of the
 * enumeration value.  
 */
@interface SCKEnumerationValue : SCKProgramComponent
/**
 * Returns the value of the enumeration.
 */
@property long long longLongValue;
/**
 * The name of the enumeration.
 */
@property (nonatomic, retain) NSString *enumerationName;
@end

@interface SCKEnumeration : SCKTypedProgramComponent
/**
 * Array of SCKEnumerationValue instances that describe the values in this
 * enumeration.
 */
@property (nonatomic, retain) NSMutableDictionary *values;
@end
