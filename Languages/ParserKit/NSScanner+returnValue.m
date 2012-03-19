#include "NSScanner+returnValue.h"
#include <Foundation/NSException.h>


@implementation NSScanner (ParserKit)
- (NSUInteger) hexIntegerValue
{
  NSUInteger aInt = 0;
  BOOL scanned = [self scanHexInt: &aInt];
  if (!scanned)
  {
	[NSException raise: @"ParserKit" format: @"Could not parse %@ as hex integer.", [self string]];
  }
  return aInt;
}
@end
