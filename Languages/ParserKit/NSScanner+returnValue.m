#include <Foundation/Foundation.h>
#include "NSScanner+returnValue.h"


@implementation NSScanner (ParserKit)
- (id) hexIntegerValue
{
  NSUInteger aInt = 0;
  BOOL scanned = [self scanHexInt: &aInt];
  if (!scanned)
  {
	[NSException raise: @"ParserKit" format: @"Could not parse %@ as hex integer.", [self string]];
  }
  return [NSNumber numberWithUnsignedInteger: aInt];
}
@end
