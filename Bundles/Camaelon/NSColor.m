#import <AppKit/AppKit.h>

@implementation NSColor (rows)

+ (NSColor*) rowBackgroundColor
{
	return systemColorWithName(@"rowBackgroundColor");
}

+ (NSColor*) rowTextColor
{
	return systemColorWithName(@"rowTextColor");
}

+ (NSColor*) selectedRowBackgroundColor
{
	return [NSColor colorWithCalibratedRed: 0.7 green: 0.7 blue: 0.8 alpha: 1.0];
}
/*
+ (NSColor*) selectedControlColor
{
	return [NSColor greenColor];
}
*/

+ (NSColor*) selectedRowTextColor
{
	return systemColorWithName(@"selectedRowTextColor");
}

@end
