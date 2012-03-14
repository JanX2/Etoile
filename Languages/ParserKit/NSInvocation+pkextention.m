#include "NSInvocation+pkextention.h"
@implementation NSInvocation (pkextention)
- (id) returnValueAsObject {
  id object;
  [self getReturnValue: &object];
  return object;
}
@end
