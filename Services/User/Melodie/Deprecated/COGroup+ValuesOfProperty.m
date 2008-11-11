#import "COGroup+ValuesOfProperty.h"

@implementation COGroup (ValuesOfProperty)

- (NSArray *) valuesOfProperty: (NSString *)aProperty
{
	NSMutableSet *set = [NSMutableSet setWithCapacity:1024];
	FOREACH([self allObjects], object, id)
	{
		if ([object valueForProperty: aProperty] != nil)
			[set addObject: [object valueForProperty: aProperty]];
	}
	FOREACH([self allGroups], group, id)
	{
		if ([group valueForProperty: aProperty] != nil)
			[set addObject: [group valueForProperty: aProperty]];
	}
	return [set allObjects];
}

@end
