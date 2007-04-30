#import "OSVirtualNode.h"

@implementation OSVirtualNode
+ (NSArray *) prefix
{
  return nil;
}

+ (NSArray *) pathExtension
{
  return nil;
}

- (void) refresh
{
}

- (NSString *) name
{
  return [[self pathRepresentation] lastPathComponent];
}

- (NSImage *) icon
{
  return nil;
}

- (NSImage *) preview
{
  return nil;
}

- (BOOL) hasChildren
{
  return NO;
}

- (NSArray *) children
{
  return nil;
}

- (NSComparisonResult) caseInsensitiveCompare: (id <OSObject>) object
{
  if (object == nil)
    return NSOrderedAscending;
  return [[self name] caseInsensitiveCompare: [object name]];
}

- (void) setPathRepresentation: (NSString *) rep
{
  ASSIGN(pathRep, rep);
}

- (NSString *) pathRepresentation;
{
  return pathRep;
}

- (id) init
{
  if ([self isMemberOfClass: [OSVirtualNode class]])
  {
    [NSException raise: @"OSVirtualNode is used"
                format: @"Do not use OSVirtualNode. Subclass it"];
    [self dealloc];
    return nil;
  }
  return [super init];
}

- (void) dealloc
{
  DESTROY(pathRep);
  [super dealloc];
}

- (unsigned int) hash
{
  return [pathRep hash];
}

- (BOOL) isEqual: (id) o
{
  if ([o isKindOfClass: [self class]] == NO)
  {
    return NO;
  }
  OSVirtualNode *other = (OSVirtualNode *) o;
  return [[self pathRepresentation] isEqualToString: [other pathRepresentation]];
}

- (NSString *) description
{
  return pathRep;
}

- (BOOL) willTakeAwayChild: (id <OSObject>) child
{
  return NO;
}

- (void) doTakeAwayChild: (id <OSObject>) child move: (BOOL) flag
{
}

- (BOOL) willAcceptChild: (id <OSObject>) child error: (unsigned int *) error
{
  if (error)
    *error = OSObjectNotAllowedActionError;
  return NO;
}

- (BOOL) doAcceptChild: (id <OSObject>) child move: (BOOL) isMoving
                 error: (unsigned int *) error
{
  if (error)
    *error = OSObjectNotAllowedActionError;
  return NO;
}

@end

