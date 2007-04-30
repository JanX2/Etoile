#import "OSObjectFactory.h"
#import "OSBitmapImageNode.h"
#import "OSBundleNode.h"
#import "OSApplications.h"

static OSObjectFactory *sharedInstance; 

@implementation OSObjectFactory
- (id <OSObject>) objectAtPath: (NSString *) path
{
  BOOL matchPrefix = NO;
  BOOL matchExt = NO;
  NSEnumerator *oe, *e = [prototypes objectEnumerator];
  id <OSObject> object = nil;
  Class cls;
  NSArray *prefix = nil;
  NSArray *ext = nil;
  NSString *temp = nil;
  while ((object = [e nextObject]))
  {
    matchPrefix = NO;
    matchExt = NO;
    cls = [object class];
    prefix = [cls prefix];
    ext = [cls pathExtension];
    if (prefix)
    {
      oe = [prefix objectEnumerator];
      while ((temp = [oe nextObject]))
      {
        matchPrefix = [path hasPrefix: temp];
        if (matchPrefix == YES)
          break;
      }
    }
    if (ext)
    {
      oe = [ext objectEnumerator];
      while ((temp = [oe nextObject]))
      {
        matchExt = [[path pathExtension] isEqualToString: temp];
        if (matchExt == YES)
          break;
      }
    }
    if ((matchPrefix && matchExt) ||
        ((prefix == nil) && matchExt) ||
        ((ext == nil) && matchPrefix))
    {
      id <OSObject> o = [[cls alloc] init];
      if ([o isKindOfClass: [OSNode class]])
      {
        [(OSNode *)o setPath: path];
      }
      else if ([o isKindOfClass: [OSVirtualNode class]])
      {
        [(OSVirtualNode *)o setPathRepresentation: path];
      }
      return AUTORELEASE(o);
    }
  }
  /* Default Object */
  /* match can be YES or NO here. So we don't check here */
  OSNode *o = [[OSNode alloc] init];
  [o setPath: path];
  return AUTORELEASE(o);
}

- (id) init
{
  self = [super init];

  /* Default objects */
  /* NOTE: order matters here because some objects may 
     have overlapping prefix */
  prototypes = [[NSMutableArray alloc] init];
  [prototypes addObject: AUTORELEASE([[OSTrashCan alloc] init])];
  [prototypes addObject: AUTORELEASE([[OSApplications alloc] init])];
  [prototypes addObject: AUTORELEASE([[OSBitmapImageNode alloc] init])];
  [prototypes addObject: AUTORELEASE([[OSBundleNode alloc] init])];
  [prototypes addObject: AUTORELEASE([[OSNode alloc] init])];

  return self;
}

- (void) dealloc
{
  DESTROY(prototypes);
  [super dealloc];
}

- (OSNode *) homeObject
{
  return [self objectAtPath: NSHomeDirectory()];
}

- (OSApplications *) applications
{
  return AUTORELEASE([[OSApplications alloc] init]);
}

- (OSTrashCan *) trashCan
{
  return AUTORELEASE([[OSTrashCan alloc] init]);
}

+ (OSObjectFactory *) defaultFactory
{
  if (sharedInstance == nil)
    sharedInstance = [[OSObjectFactory alloc] init];
  return sharedInstance;
}

@end
