#include "NSInvocation+pkextention.h"
#include <Foundation/NSValue.h>
@implementation NSInvocation (pkextention)
- (id) returnValueAsObject {
  id object;
  [self getReturnValue: &object];
  return object;
}

- (id)returnValueAsBool {
	BOOL returnValue = NO;
	[self getReturnValue: &returnValue];

	return [NSNumber numberWithBool: returnValue];
}
@end
