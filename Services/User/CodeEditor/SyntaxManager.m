#import "SyntaxManager.h"
#import "SyntaxHandler.h"
#import "GNUstep.h"

static SyntaxManager *sharedInstance;

@implementation SyntaxManager

/* Private */
- (SyntaxHandler *) syntaxHandler: (NSString *) def
{
  NSLog(@"definition %@", def);
  NSString *path = [[NSBundle mainBundle] pathForResource: def
                                              ofType: @"plist"];
  NSLog(@"%@", path);
  NSDictionary *definition = [NSDictionary dictionaryWithContentsOfFile: path];
  SyntaxHandler *handler = [[SyntaxHandler alloc] init];
  NSString *s, *s1;
  NSMutableArray *ma;
  NSMutableDictionary *md;

  /* Single line comment */
  ma = [[NSMutableArray alloc] init];
  s = [definition objectForKey: @"firstSingleLineComment"];
  if ([s length]) {
    [ma addObject: s];
  }
  s = [definition objectForKey: @"secondSingleLineComment"];
  if ([s length]) {
    [ma addObject: s];
  }
  [handler setSingleLineCommentToken: AUTORELEASE([ma copy])];
  DESTROY(ma);

  /* Multiple line comment */
  md = [[NSMutableDictionary alloc] init];
  s = [definition objectForKey: @"beginFirstMultiLineComment"];
  s1 = [definition objectForKey: @"endFirstMultiLineComment"];
  if ([s length]) {
    [md setObject: s1 forKey: s];
  }
  s = [definition objectForKey: @"beginSecondMultiLineComment"];
  s1 = [definition objectForKey: @"endSecondMultiLineComment"];
  if ([s length]) {
    [md setObject: s1 forKey: s];
  }
  [handler setMultipleLinesCommentToken: AUTORELEASE([md copy])];
  DESTROY(md);

  /* String */
  ma = [[NSMutableArray alloc] init];
  s = [definition objectForKey: @"firstString"];
  if ([s length]) {
    [ma addObject: s];
  }
  s = [definition objectForKey: @"secondString"];
  if ([s length]) {
    [ma addObject: s];
  }
  [handler setStringToken: AUTORELEASE([ma copy])];
  DESTROY(ma);

  return AUTORELEASE(handler);
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

