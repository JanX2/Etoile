#include <OgreKit/OGRegularExpression.h>
#include <OgreKit/OGRegularExpressionMatch.h>
#include <UnitKit/UnitKit.h>

@interface TestOGRegularExpression: NSObject <UKTest>
@end

@implementation TestOGRegularExpression
- (void) testBasic
{
  OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"a[^a]*a"];
  NSArray *matches = [regex allMatchesInString:@"alphabetagammadelta"];
  UKIntsEqual(3, [matches count]);

  OGRegularExpressionMatch *match = [matches objectAtIndex: 0];;
  UKStringsEqual(@"alpha", [match matchedString]);
  match = [matches objectAtIndex: 1];;
  UKStringsEqual(@"aga", [match matchedString]);
  match = [matches objectAtIndex: 2];;
  UKStringsEqual(@"adelta", [match matchedString]);

  regex = [OGRegularExpression regularExpressionWithString:@"^pa.*d.*$"];
  matches = [regex allMatchesInString:@"panda"];
  UKIntsEqual(1, [matches count]);

  match = [matches objectAtIndex: 0];;
  UKStringsEqual(@"panda", [match matchedString]);
}

- (void) testSubstring
{
  OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"(\\d+):(\\d+)"];
  NSArray *matches = [regex allMatchesInString: @"Time: 12:34am"];
  UKIntsEqual(1, [matches count]);
  OGRegularExpressionMatch *match = [matches objectAtIndex: 0];
  UKIntsEqual(0, [match index]);
  UKIntsEqual(3, [match count]);
  UKStringsEqual(@"12:34", [match substringAtIndex: 0]);
  UKStringsEqual(@"12", [match substringAtIndex: 1]);
  UKStringsEqual(@"34", [match substringAtIndex: 2]);
  UKStringsEqual(@"Time: ", [match prematchString]);
  UKStringsEqual(@"am", [match postmatchString]);
}

- (void) testReplacement
{
  /* Swap first and second substring */
  OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString: @"(\\d+):(\\d+)"];
  NSString *replace = [regex replaceFirstMatchInString: @"Time: 12:34am"
                      withString: @"\\2:\\1"];
  UKStringsEqual(@"Time: 34:12am", replace);
}

@end
