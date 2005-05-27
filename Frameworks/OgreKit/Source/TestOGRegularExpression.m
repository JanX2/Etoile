#include <OgreKit/OGRegularExpression.h>
#include <OgreKit/OGRegularExpressionMatch.h>
#include <UnitKit/UnitKit.h>

@interface TestOGRegularExpression: NSObject <UKTest>
@end

@implementation TestOGRegularExpression
- (void) testBasic
{
  OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"a[^a]*a"];
//  OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"gamma"];
  NSEnumerator *enumerator = [regex matchEnumeratorInString:@"alphabetagammadelta"];
  NSArray *matches = [regex allMatchesInString:@"alphabetagammadelta"];
  UKIntsEqual(3, [matches count]);

  OGRegularExpressionMatch *match = [matches objectAtIndex: 0];;
  UKStringsEqual(@"alpha", [match matchedString]);
  match = [matches objectAtIndex: 1];;
  UKStringsEqual(@"aga", [match matchedString]);
  match = [matches objectAtIndex: 2];;
  UKStringsEqual(@"adelta", [match matchedString]);
}
@end
