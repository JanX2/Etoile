#import "SyntaxManager.h"
#import "GNUstep.h"

static SyntaxManager *sharedInstance;

@implementation SyntaxManager

/* Private */
- (SyntaxHandler *) syntaxHandler: (NSString *) definition
{
  NSLog(@"definition %@", definition);
  NSString *path = [[NSBundle mainBundle] pathForResource: definition
                                              ofType: @"plist"];
  NSLog(@"%@", path);
  return [[SyntaxHandler alloc] init];
}
/* End of private */

- (SyntaxHandler *) syntaxHandlerForFile: (NSString *) filename
{
  NSString *extension = [[filename pathExtension] lowercaseString];
  NSArray *extensions;
  NSEnumerator *e = [syntax objectEnumerator];
  NSDictionary *dict;
  while ((dict = [e nextObject])) {
    extensions = [[dict objectForKey: @"extensions"] componentsSeparatedByString: @" "];
    if ([extensions containsObject: extension]) {
      NSLog(@"Found %@", [dict objectForKey: @"name"]);
      return [self syntaxHandler: [dict objectForKey: @"file"]];
    }
  }
}

- (SyntaxHandler *) syntaxHandlerForLanguage: (NSString *) lauguage
{
  NSEnumerator *e = [syntax objectEnumerator];
  NSDictionary *dict;
  while ((dict = [e nextObject])) {
    if ([[dict objectForKey: @"name"] isEqualToString: [lauguage lowercaseString]]) {
      return [self syntaxHandler: [dict objectForKey: @"file"]];
    }
  }
}

- (id) init
{
  self = [super init];

  NSString *path = [[NSBundle mainBundle] pathForResource: @"Syntax" 
                                         ofType: @"plist"];
  ASSIGN(syntax, [NSArray arrayWithContentsOfFile: path]);
  if (syntax == nil) {
    NSLog(@"Error: Cannot get syntax file");
    [self dealloc];
    return nil;
  }
  return self;
}

- (void) dealloc
{
  DESTROY(syntax);
  [super dealloc];
}

+ (SyntaxManager *) syntaxManager
{
  if (sharedInstance == nil) {
    sharedInstance = [[SyntaxManager alloc] init];
  } 
  return sharedInstance;
}

@end

