#import "OSApplications.h"
#import "OSObjectFactory.h"
#import "OSBundleNode.h"
#import <IconKit/IconKit.h>

static NSString *identifier = @"Applications"; //@"/VIRTUAL_OBJECT/Applications"
static NSArray *prefix;

@implementation OSApplications
/* Private */
- (NSArray *) allGNUstepApplications
{
  NSFileManager *fm = [NSFileManager defaultManager];
  OSObjectFactory *factory = [OSObjectFactory defaultFactory];
  NSArray *paths = NSStandardApplicationPaths();
  NSMutableArray *all = [[NSMutableArray alloc] init];
  int i, j;
  for (i = 0; i < [paths count]; i++)
  {
    NSString *path = [paths objectAtIndex: i];
    NSArray *array = [fm directoryContentsAtPath: path];
    for (j = 0; j < [array count]; j++)
    {
      NSString *p = [path stringByAppendingPathComponent: [array objectAtIndex: j]];
      id <OSObject> o = [factory objectAtPath: p];
      if (o)
      {
	if ([o isKindOfClass: [OSBundleNode class]] == NO)
	  NSLog(@"Internal Error: Not a GNUstep application");
        [all addObject: o];
      }
    }
  }
  return AUTORELEASE(all);
}

/* End of Private */
- (void) refresh
{
  /* This should be all gnustep applications */
  NSArray *gsapps = [self allGNUstepApplications];
#if 0
  /* We reuse node so that some setting */
  NSMutableArray *array = [[NSMutableArray alloc] init];
  int i, index;
  for (i = 0; i < [gsapps count]; i++)
  {
    index = [apps indexOfObject: [gsapps objectAtIndex: i]];
    if (index == NSNotFound)
    {
      [array addObject: [gsapps objectAtIndex: i]];
    }
    else
    {
      [array addObject: [apps objectAtIndex: index]];
    }
  }
  [apps removeAllObjects];
  [apps addObjectsFromArray: array];
  DESTROY(array);
#else 
  [apps removeAllObjects];
  [apps addObjectsFromArray: gsapps];
#endif
}

- (NSImage *) icon
{
  return [[IKIcon iconWithIdentifier: @"application-x-executable"] image];
}

- (NSString *) name
{
  return @"Applications";
}

- (NSImage *) preview
{
  return [self icon];
}

- (BOOL) hasChildren
{
  return YES;
}

- (NSArray *) children
{
  if (apps == nil)
  {
    apps = [[NSMutableArray alloc] init];
    [self refresh];
  }
  return apps;
}

- (id) init
{
  self = [super init];
  [self setPathRepresentation: identifier];
  return self;
}

- (void) dealloc
{
  DESTROY(apps);
  [super dealloc];
}

+ (NSArray *) prefix
{
  if (prefix == nil)
    prefix = [[NSArray alloc] initWithObjects: identifier, nil];
  return prefix;
}


@end

