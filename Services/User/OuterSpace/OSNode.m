#import <IconKit/IconKit.h>
#import "OSNode.h"
#import "OSObjectFactory.h"

@implementation OSNode
/* Private */
/* End of Private */

- (BOOL) needsUpdate
{
  NSDate *date = [[fm fileAttributesAtPath: path traverseLink: NO]
                                   objectForKey: NSFileModificationDate];
  if ((lastModificationDate == nil) || 
      ([lastModificationDate isEqualToDate: date] == NO))
  {
    ASSIGN(lastModificationDate, date);
    return YES;
  }
  return NO;
}

- (void) refresh
{
  DESTROY(lastModificationDate);
  /* NOTE: Should we call -children once to rebuild cache ? */
}

- (id) init
{
  self = [super init];
  fm = [NSFileManager defaultManager];
  isDirectory = NO;
  setHidden = YES;
  isExisted = NO;
  return self;
}

- (void) dealloc
{
  DESTROY(children);
  DESTROY(path);
  [super dealloc];
}

- (void) setPath: (NSString *) p
{
  ASSIGN(path, [p stringByStandardizingPath]);
  isExisted = [fm fileExistsAtPath: path isDirectory: &isDirectory];
}

- (NSString *) path
{
  return path;
}

- (NSString *) name
{
  return [path lastPathComponent];
}

- (NSImage *) icon
{
  NSImage *image = nil;
  if (path)
    image = [[IKIcon iconForFile: path] image];
  if (image == nil)
  {
    if ([self hasChildren] == YES)
      image = [NSImage imageNamed: @"common_Folder"];
    else
      image = [NSImage imageNamed: @"common_Unknown"];
  }
  return image;
}

- (NSImage *) preview
{
  return [self icon];
}

- (BOOL) hasChildren
{
  return isDirectory;
}

- (NSArray *) children
{
  if ([self hasChildren] == NO)
    return nil;

  if (([self needsUpdate] == YES) || (children == nil))
  {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSEnumerator *e = [[fm directoryContentsAtPath: [self path]] objectEnumerator];
    NSString *p = nil;
    while ((p = [e nextObject]))
    {
      /* Check hidden files */
      if (([p hasPrefix: @"."] == YES) && (setHidden == YES))
	continue;

      p = [[self path] stringByAppendingPathComponent: p];
      OSNode *node = [[OSObjectFactory defaultFactory] objectAtPath: p];
      [array addObject: node];
    }
    if ([array count] > 1)
    {
      ASSIGN(children, 
         [array sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]);
    }
    else
    {
      ASSIGN(children, array);
    }
    DESTROY(array);
  }
  return children;
}

- (unsigned int) hash
{
  return [path hash];
}

- (BOOL) isEqual: (id) o
{
  if ([o isKindOfClass: [self class]] == NO)
  {
    return NO;
  }
  OSNode *other = (OSNode *) o;
  return [[self path] isEqualToString: [other path]];
}

- (void) showHiddenFiles: (BOOL) flag
{
  setHidden = flag;
}

- (BOOL) isHiddenFilesShown
{
  return setHidden;
}

- (NSComparisonResult) caseInsensitiveCompare: (id <OSObject>) object
{
  if (object == nil)
    return NSOrderedAscending;
  if ([object name] == nil) {
    NSLog(@"Error: no name: %@", [(OSNode *)object path]);
  }
  return [[self name] caseInsensitiveCompare: [object name]];
}

- (NSString *) description
{
  return path;
}

- (BOOL) willTakeAwayChild: (id <OSObject>) child
{
  return YES;
}

- (void) doTakeAwayChild: (id <OSObject>) child move: (BOOL) flag
{
}

/* For physical node, we need to deal with name conflict if there is any */
- (BOOL) willAcceptChild: (id <OSObject>) child error: (unsigned int *) error
{
  OSNode *node = nil;
  NSString *p = nil;

  if ([self hasChildren] == NO)
  {
    if (error)
      *error = OSObjectNotAllowedActionError;
    return NO;
  }
  /* If it is a virtual node, we deny it (?).
     A virtual node should make a OSNode and pass it instead of pass its own.
     Override for special node, ex. trash can. */
  if ([child isKindOfClass: [OSNode class]] == NO)
  {
    if (error)
      *error = OSObjectNotAllowedActionError;
    return NO;
  }

  /* Let's see whether we have a files with the same name.
     We use NSFileManager because it is faster and more reliable ?
     The child should contain its original path. So we only compare
     the lastPathComponent. */
  node = (OSNode *) child;
  p = [[self path] stringByAppendingPathComponent: [[node path] lastPathComponent]];
  if ([fm fileExistsAtPath: p])
  {
    if (error)
      *error = OSObjectIdenticalObjectError;
    return NO;
  }
  
  return YES;
}

/* If it fails, return NO with error. 
   We do not deal with error handling here.
   Whoever calls this method should deal with error and calls this again.
 */
- (BOOL) doAcceptChild: (id <OSObject>) child move: (BOOL) isMoving
                 error: (unsigned int *) error
{
  if ([self hasChildren] == NO)
  {
    if (error)
      *error = OSObjectNotAllowedActionError;
    return NO;
  }

  /* We deal with both OSVirtualNode and OSNode here */
  OSNode *source = nil;
  NSString *targetPath = nil, *sourcePath = nil;
  /* First, let's get the node */
  if (isMoving)
  {
    if ([child respondsToSelector: @selector(willStartMoving)])
      source = [(NSObject *)child willStartMoving];
    else
      source = child;
  }
  else
  {
    if ([child respondsToSelector: @selector(willStartCopying)])
      source = [(NSObject *)child willStartCopying];
    else
      source = child;
  }

  if ((source != nil) && [source isKindOfClass: [OSNode class]])
  {
    sourcePath = [source path];
  }
  else
  {
    /* We cannot deal with OSVirtualNode or nil */
    if (error)
      error = OSObjectNotExistingOnFileSystemError;
    return NO;
  }

  if ((sourcePath != nil) && [fm fileExistsAtPath: sourcePath])
  {
    targetPath = [[self path] stringByAppendingPathComponent: 
                                        [sourcePath lastPathComponent]];

    /* Let's check whether a file already exist in target path */
    if ([fm fileExistsAtPath: targetPath])
    {
      if (error)
 	*error = OSObjectIdenticalObjectError;
      return NO;
    }

    if (isMoving)
    {
      NSLog(@"Will move %@ to %@", sourcePath, targetPath);
      if ([fm movePath: sourcePath toPath: targetPath handler: nil])
      {
        if ([child respondsToSelector: @selector(didFinishMoving)])
          [(NSObject *)child didFinishMoving];
        return YES;
      }
      NSLog(@"Failed moving");
    }
    else
    {
      NSLog(@"Will copy %@ to %@", sourcePath, targetPath);
      if ([fm copyPath: sourcePath toPath: targetPath handler: nil])
      {
        if ([child respondsToSelector: @selector(didFinishCopying)])
          [(NSObject *)child didFinishCopying];
        return YES;
      }
    }

    /* If it falls down here, it means copying or moving failed */
    if (error)
      *error = OSObjectFileSystemOperationFailedError;
    return NO;
  }
  else
  {
    if (error)
      error = OSObjectNotExistingOnFileSystemError;
    return NO;
  }

  if (error)
    *error = OSObjectUnknownError;
  return NO;
}

+ (NSArray *) prefix
{
  return nil;
}

+ (NSArray *) pathExtension
{
  return nil;
}

@end
