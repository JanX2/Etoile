#include <Foundation/Foundation.h>
#include "NSString+append.h"

@implementation NSMutableString  (ParserKit)
- (id)appendCharacter: (id)aCharacter
{
  unichar c = [aCharacter shortValue];
  [self appendString: [NSString stringWithCharacters: &c length: 1]];
  return self;
}
@end
