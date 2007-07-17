#import <Foundation/Foundation.h>
#import "ETSerialiser.h"

@implementation NSInvocation (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend
{
	if(strcmp(aVariable, "_info") == 0)
	{
		//TODO: Actually serialise this
		NSLog(@"Not actually serialising _info");
		return YES;
	}
	return [super serialise:aVariable using:aBackend];
}
@end
