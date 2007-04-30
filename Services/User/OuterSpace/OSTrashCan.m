#import "OSTrashCan.h"
#import "OSTrashNode.h"
#import "OSObjectFactory.h"
#import <XWindowServerKit/XFunctions.h>

@implementation OSTrashCan

/* Private */
/* It check whether a directory exists, if not, create it, and return YES.
   Return NO if it cannot create one */
- (BOOL) directoryExistsOrCreatedAtPath: (NSString *) p
{
  BOOL isDir = NO;

  if ([fm fileExistsAtPath: p isDirectory: &isDir]) 
  {
    return isDir;
  } 
  else 
  {
    return [fm createDirectoryAtPath: p attributes: nil];
  }
}

/* Return an unique name based on path, 
 * only return the last path component including extension. */
- (NSString *) uniqueNameForFile: (NSString *) string
{
  /* Try original name first */
  NSString *name = [string lastPathComponent];
  NSString *p = [trashFilesPath stringByAppendingPathComponent: name];

  if ([fm fileExistsAtPath: p] == NO) 
  {
    return name;
  }

  /* Come up an unique name */
  int i;
  NSString *ext = [name pathExtension];

  name = [name stringByDeletingPathExtension];

  for (i = 0; i < 10000; i++) 
  {
    p = [NSString pathWithComponents: [NSArray arrayWithObjects:
		trashFilesPath, name, 
		[NSString stringWithFormat: @"_%d", i], ext, nil]];
    if ([fm fileExistsAtPath: p] == NO) 
    {
      return [p lastPathComponent];
    }
  }

  /* Cannot find unique name */
  return nil;
}

/* End of Private */

/* This should be smart enought to know some of the files may be
 * used by other application at the same time. Does file system block
 * removing files because of that ? */
- (void) emptyTrashCan: (id) sender
{
  int result = NSRunAlertPanel(_(@"Empty Trash Can !!"),
	_(@"Are you sure to empty trash can ? Files in trash can will be deleted forever, \nand this application is considered as unstable, which may have seriously side affect."),
	_(@"No, Do Not Empty Trash Can"), _(@"Yes, Empty Trash Can Now"),
	nil, nil);

  if (result == NSAlertAlternateReturn) 
  {
    /* To make things easy, we remove subdirectories and recreate new onw */
    /* Let do some basic check before we really remove file */
    NSString *home = NSHomeDirectory();
    NSArray *array  = [NSArray arrayWithObjects:
		home, @"", @"/", @"/usr", @"/bin", @"/sbin", nil];

    if ([array containsObject: trashFilesPath]) 
    {
      NSLog(@"Internal Error: trashFilesPath is one of these directory: %@", 
								array);
    }
    if ([array containsObject: trashInfoPath]) 
    {
      NSLog(@"Internal Error: trashInfoPath is one of these directory: %@", 
								array);
    }
    if ([trashFilesPath hasPrefix: home] == NO) 
    {
      NSLog(@"Internal Error: trashFilesPath is not under home directory: %@", 
								home);
    }
    if ([trashInfoPath hasPrefix: home] == NO) 
    {
      NSLog(@"Internal Error: trashInfoPath is not under home directory: %@", 
								home);
    }

    /* We stop removing if any of them fails */
    if ([fm removeFileAtPath: trashFilesPath handler: nil] == NO) 
    {
      NSLog(@"Internal Error: Cannot remove %@", trashFilesPath);
      return;
    } 
    else 
    {
      if ([fm createDirectoryAtPath: trashFilesPath 
				  attributes: nil] == NO)
      {
	NSLog(@"Internal Error: Cannot create %@", trashFilesPath);
	return;
      }
    }
    if ([fm removeFileAtPath: trashInfoPath handler: nil] == NO) 
    {
      NSLog(@"Internal Error: Cannot remove %@", trashInfoPath);
      return;
    } 
    else 
    {
      if ([fm createDirectoryAtPath: trashInfoPath 
				  attributes: nil] == NO)
      {
	NSLog(@"Internal Error: Cannot create %@", trashInfoPath);
	return;
      }
    }
    /* We ask ourself to refresh */
    [self refresh];
  }
}

- (void) recoverAllFiles: (id) sender
{
  NSLog(@"Recover all files");
  NSEnumerator *e = [[fm directoryContentsAtPath: trashFilesPath] 
                                                      objectEnumerator];
  NSString *name = nil;
  while ((name = [e nextObject])) {
    NSString *p = [[trashInfoPath stringByAppendingPathComponent: name] 
                                 stringByAppendingPathExtension: @"trashinfo"];
    OSTrashNode *info = [[OSTrashNode alloc] initWithContentsOfFile: p];

    /* move the file back */
    NSString *w = [trashFilesPath stringByAppendingPathComponent: name];
    if ([fm movePath: w toPath: [info path] handler: nil] == NO) 
    {
      NSLog(@"Cannot recover file %@ from %@", [info path], w);
    } 
    else 
    {
      if ([fm removeFileAtPath: p handler: nil] == NO) 
      {
         NSLog(@"Cannot remove %@", p);
      }
    }
    DESTROY(info);
  }

  /* Let do a final check */
  if ([[fm directoryContentsAtPath: trashFilesPath] count] > 0)  
  {
    NSLog(@"trashFilesPath is not empty: %@", trashFilesPath);
  }
  if ([[fm directoryContentsAtPath: trashInfoPath] count] > 0)  
  {
    NSLog(@"trashInfoPath is not empty: %@", trashInfoPath);
  }
}

- (void) recoverSelectedFiles: (id) sender
{
  NSLog(@"Recover selected files: Do nothing now.");
}



/* Override */

/* We need to check last modification date in Trash/files/ */
- (BOOL) needsUpdate
{
  NSDate *date = [[fm fileAttributesAtPath: trashFilesPath traverseLink: NO]
                                   objectForKey: NSFileModificationDate];
  if ((lastModificationDate == nil) ||
      ([lastModificationDate isEqualToDate: date] == NO))
  {
    ASSIGN(lastModificationDate, date);
    return YES;
  }
  return NO;
}

- (NSArray *) children
{
  if ([self hasChildren] == NO)
    return nil;

  if (([self needsUpdate] == YES) || (children == nil))
  {
    /* We check the Trash/files/ */
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSEnumerator *e = [[fm directoryContentsAtPath: trashFilesPath] objectEnumerator];
    NSString *p = nil;
    while ((p = [e nextObject]))
    {
      /* Check hidden files */
      if (([p hasPrefix: @"."] == YES) && (setHidden == YES))
        continue;

      p = [trashFilesPath stringByAppendingPathComponent: p];
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

/* We take all OSNode */
- (BOOL) willAcceptChild: (id <OSObject>) child error: (unsigned int *) error
{ 
  /* It would automatically be true. If not, it is a bug */
  if ([self hasChildren] == NO)
  {
    NSLog(@"Internal Error: trash can is not a directory");
    if (error)
      *error = OSObjectNotAllowedActionError;
    return NO; 
  } 

  /* If it is a virtual node, we deny it.
     A virtual node should make a OSNode and pass it instead of pass its own.
     Override for special node, ex. trash can. */ 
  if ([child isKindOfClass: [OSNode class]] == NO)
  {
    if (error)
      *error = OSObjectNotAllowedActionError;
    return NO;
  }
  return YES;
}


/* Move file in files/ and write .trashinfo in info/ */
- (BOOL) doAcceptChild: (id <OSObject>) child move: (BOOL) isMoving
                 error: (unsigned int *) error
{
  if ([child isKindOfClass: [OSNode class]] == NO) 
    return NO;

  NSString *p = [(OSNode *)child path];

  /* Find an unique name */
  NSString *name = [self uniqueNameForFile: p];
  if (name == nil) 
  {
    int result = NSRunAlertPanel(_(@"Trash can is full !"),
	_(@"Trash can cannot add this file. Do you want to empty trash can now ? "),
	_(@"Yes, Empty Trash Can Now and Continue"), _(@"No, Abort"), 
	nil, nil);

    if (result == NSAlertDefaultReturn) 
    {
      [self emptyTrashCan: self];

      /* Get name again */
      name = [self uniqueNameForFile: p];
      if (name == nil) 
      {
	/* Something is not right. Warn and quit */
	NSRunAlertPanel(_(@"Internal Error !"),
		_(@"Trash can cannot find an unique name even it is empty."),
		_(@"Quit"), nil, nil, nil);
	// NOTE: should we quit ?
	[NSApp terminate: self];
      }
    } 
    else 
    {
      /* Abort */
      return NO;
    }
  }
  /* Get unique name here. Write .trashinfo file */
  OSTrashNode *info = [[OSTrashNode alloc] init];
  [info setOriginalPath: p];
  [info setDeletionDate: [NSCalendarDate calendarDate]];

  /* Move file */
  NSString *to = [trashFilesPath stringByAppendingPathComponent: name];
  if ([fm movePath: p toPath: to handler: nil]) 
  {
    [info setPath: to];
    /* Write .trashinfo */
    if ([info writeTrashInfo] == NO) 
    {
      /* move the file back */
      if ([fm movePath: to toPath: p handler: nil] == NO) 
      {
	NSLog(@"Cannot move file back. Totally failed");
	return NO;
      }
    }
  } 
  else 
  {
    NSLog(@"Cannot move file into trash can: %@", p);
    return NO;
  }
  DESTROY(info);
  return YES;
}

/* When child is taken away, we remove corresponding .trashinfo */
- (void) doTakeAwayChild: (id <OSObject>) child move: (BOOL) flag
{
  /* We only deal with moving since copying does nothing to us. */
  if (flag)
  {
    /* child must be OSNode. Otherwise, it is a bug */
    if ([child isKindOfClass: [OSTrashNode class]] == NO)
    {
      NSLog(@"Internal Error: child is not an OSTrashNode");
      return;
    }

    [(OSTrashNode *) child removeTrashInfo];
  }
}

- (NSImage *) icon
{
  NSImage *image = [NSImage imageNamed: @"Recycler"];
  if (image)
    return image;
  return [super icon];
}

- (id) init
{
  self = [super init];

  /* Make sure all paths exist */
  ASSIGN(trashCanPath,
         [XDGDataHomePath() stringByAppendingPathComponent: @"Trash"]);
  ASSIGN(trashFilesPath, 
	 [trashCanPath stringByAppendingPathComponent: @"files"]);
  ASSIGN(trashInfoPath, 
	 [trashCanPath stringByAppendingPathComponent: @"info"]);
  [self setPath: trashCanPath];

  BOOL success = [self directoryExistsOrCreatedAtPath: trashCanPath];
  if (success) 
  {
    success = [self directoryExistsOrCreatedAtPath: trashFilesPath];
    if (success) 
    {
      success = [self directoryExistsOrCreatedAtPath: trashInfoPath];
    }
  } 

  if (success == NO) 
  {
    NSRunAlertPanel(_(@"Failed to directory !"),
		_(@"TrashCan cannot create directory in the home directory"),
		_(@"Quit"), nil, nil, nil);
    [NSApp terminate: nil];
  }
  return self;
}

- (void) dealloc
{
  DESTROY(trashFilesPath);
  DESTROY(trashInfoPath);
  [super dealloc];
}

@end

