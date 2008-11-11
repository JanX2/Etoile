#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/CoreObject.h>

@interface COGroup (ValuesOfProperty)

/*
 * Returns an array of all of the different values that objects in this group
 * have for aProperty. 
 */
- (NSArray *) valuesOfProperty: (NSString *)aProperty;

@end
