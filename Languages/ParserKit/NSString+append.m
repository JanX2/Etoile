#include "NSString+append.h"

@implementation NSMutableString  (ParserKit)
- (void)appendCharacter: (const unichar)aCharacter
{
  [self appendString: [NSString stringWithCharacters: &aCharacter length: 1]];
}
@end
