#import "OSFolderWindow.h"
#import "OSDistributedView.h"
#import "OSObjectFactory.h"
#import "OSNode.h"
#import "OSVirtualNode.h"
#import "OSTrashCan.h"
#import <InspectorKit/InspectorKit.h>

#define SHELF_HEIGHT 80
#define PATH_HEIGHT 20
#define BOTTOM_BAR_HEIGHT 15
#define SPACE 3

/* [NSApp is not reliable */
static NSMutableArray *windowList;

@implementation OSFolderWindow
/* Private */
- (void) _switchType: (OSViewType) t
{
  NSRect rect = [[self contentView] frame];
  // FIXME: there is a 1 pixel shift.
  rect.size.width = NSMaxX(rect);
  rect.origin.x = 0;
  rect.origin.y = BOTTOM_BAR_HEIGHT;
  rect.size.height -= (SHELF_HEIGHT+SPACE+PATH_HEIGHT+SPACE+BOTTOM_BAR_HEIGHT);

  if (scrollView == nil)
  {
    scrollView = [[NSScrollView alloc] initWithFrame: rect];
    [scrollView setAutoresizesSubviews: NO];
    [scrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    [scrollView setHasVerticalScroller: YES];
    [scrollView setHasHorizontalScroller: YES];
    [[self contentView] addSubview: scrollView];
  }
 
  switch(t) 
  {
    case OSDistributedViewType:
      {
        view = [[OSDistributedView alloc] initWithFrame: rect];
        [(OSDistributedView *)view setDataSource: self];
        [(OSDistributedView *)view setDelegate: self];
      }
      break;
    case OSBrowserViewType:
      NSLog(@"Internal Error: Not implemented");
      break;
    case OSTableViewType:
      NSLog(@"Internal Error: Not implemented");
      break;
    default:
      NSLog(@"Internal Error: Shounldn't be here");
  }
  [scrollView setDocumentView: view];
  RELEASE(view);
}

/* Return NO to stop all rest file operation */ 
- (BOOL) _put: (id <OSObject>) child into: (id <OSObject>) parent 
         move: (BOOL) flag
{
  unsigned int error = 0;
  if ([parent doAcceptChild: child move: flag error: &error])
  {
    /* We notify parent that its child is taken away */
    [parent doTakeAwayChild: child move: flag];
    return YES;
  }
  else
  {
    switch (error) {
      case OSObjectIdenticalObjectError:
      {
	int result = NSRunAlertPanel(_(@"File exists !!"),
	               _(@"Do you want to replace existing files ?"),
	               _(@"Replace"), _(@"Skip"), _(@"Abort"), nil);
	if (result == NSAlertDefaultReturn)
	{
	  /* We move files to trash can first */
	  NSLog(@"FIXME: work on trash can");
	}
	else if (result == NSAlertAlternateReturn)
	{
	  /* We return YES so that the next file operation can proceed */
	  return YES;
	}
	else if (result == NSAlertOtherReturn)
	{
	  /* We return NO to stop file operation */
	  return NO;
	}
	/* NSAlertErrorReturn */
      }
      default:
        // Do nothing
	break;
    }
  }

  /* Parent cannot take this child */
  NSLog(@"Internal Error: File operation fails.");
  return NO;
}

/* End of Private */
- (void) trashCanAction: (id) sender
{
  /* We always put trash can in new window 
     because users usually only it to drag out files. 
     It is easier to have a separated window for that. */
  OSTrashCan *trashCan = [factory trashCan];
  OSFolderWindow *window = [OSFolderWindow windowForObject: trashCan
                                     createNewIfNotExisted: YES];
  if (window)
    [window makeKeyAndOrderFront: self];
}

/* Override */
- (void) orderFront: (id) sender
{
  if (object == nil)
  {
    /* Use home as default object */
    OSNode *node = [factory homeObject];
    [self setObject: node];
  }
  if (view == nil)
  {
    [self _switchType: [self type]];
  }
  [super orderFront: sender];
}

- (void) close
{
  [windowList removeObject: self];
  [super close];
}

/* Accessories */

- (void) setObject: (id <OSObject>) o
{
  if ([object isEqual: o])
    return;

  ASSIGN(object, o);
  NSString *p = nil;
  if ([object isKindOfClass: [OSNode class]])
  {
    p = [(OSNode *)object path];
  }
  else if ([object isKindOfClass: [OSVirtualNode class]])
  {
    p = [(OSVirtualNode *)object pathRepresentation];
  }
  if (p)
  {
    [self setTitle: p];
    /* Let's see whether it match rootPath */
    DESTROY(rootPath);
    int i;
    for (i = 0; i < [rootPaths count]; i++)
    {
      NSString *prefix = [rootPaths objectAtIndex: i];
      if ([p hasPrefix: prefix])
      {
	ASSIGN(rootPath, [prefix stringByDeletingLastPathComponent]);
	break;
      }
    }
    if (rootPath && [p hasPrefix: rootPath])
    {
      [pathView setPrefix: rootPath];
      [pathView setPath: [p substringFromIndex: [rootPath length]]];
    }
    else
    {
      [pathView setPrefix: @"/"];
      [pathView setPath: p];
    }
  }

  [view setNeedsDisplay: YES];
}

- (id <OSObject>) object
{
  return object;
}


- (void) setType: (OSViewType) t
{
  if ((view == nil) || (type != t))  {
    [self _switchType: t];
  }
  type = t;
}

- (OSViewType) type
{
  return type;
}

- (void) setRootPath: (NSString *) path
{
  ASSIGN(rootPath, path);
}

- (NSString *) rootPath
{
  return rootPath;
}

- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
{
  self = [super initWithContentRect: contentRect
		          styleMask: aStyle
		            backing: bufferingType
		              defer: flag];

  NSRect rect = NSMakeRect(0, NSHeight(contentRect)-SHELF_HEIGHT,
                           NSWidth(contentRect)-SHELF_HEIGHT-SPACE, 
                           SHELF_HEIGHT);
  shelfView = [[OSShelfView alloc] initWithFrame: rect];
  [shelfView setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
  [shelfView setDelegate: self];
  [[self contentView] addSubview: shelfView];
  RELEASE(shelfView);

  rect.origin.x = NSMaxX(rect);
  rect.size.width = SHELF_HEIGHT;
  trashCanView = [[OSTrashCanView alloc] initWithFrame: rect];
  [trashCanView setAutoresizingMask: NSViewMinXMargin | NSViewMinYMargin];
  [trashCanView setTarget: self];
  [trashCanView setAction: @selector(trashCanAction:)];
  [[self contentView] addSubview: trashCanView];
  RELEASE(trashCanView);

  rect.size.width = NSWidth(contentRect);
  rect.size.height = PATH_HEIGHT;
  rect.origin.y -= (PATH_HEIGHT+SPACE);
  rect.origin.x = 0;
  pathView = [[OSPathView alloc] initWithFrame: rect];
  [pathView setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
  [pathView setDelegate: self];
  [[self contentView] addSubview: pathView];
  RELEASE(pathView);

  /* Keep a copy of root objects */
  factory = [OSObjectFactory defaultFactory];
  [shelfView addObject: [factory homeObject]];
  [shelfView addObject: [factory applications]];
  [shelfView addObject: [NSNull null]];

  /* Order matters here because prefix may overlapping.
     For example, home and trash can */
  rootPaths = [[NSMutableArray alloc] init];
  [rootPaths addObject: [[factory trashCan] path]];
  [rootPaths addObject: [[factory homeObject] path]];
  [rootPaths addObject: [[factory applications] pathRepresentation]];

  /* We keep track of windows */
  if (windowList == nil)
    windowList = [[NSMutableArray alloc] init];
  [windowList addObject: self];

  return self;
}

- (void) dealloc
{
  DESTROY(object);
  DESTROY(rootPath);
  DESTROY(rootPaths);
  /* Do not release view. It is retained by NSWindow */
  [super dealloc];
}

/* Data source for distributed view */
- (unsigned int) numberOfObjectsInDistributedView: (OSDistributedView *) view
{
  /* Object may return -1 if it is not existed */
  if ([object hasChildren]) {
    return [[object children] count];
  }
  return 0;
}

- (id) distributedView: (OSDistributedView *) view 
         objectAtIndex: (int) index
{
  return [[object children] objectAtIndex: index];
}

- (BOOL) distributedView: (OSDistributedView *) view
         writeObjectsWithIndexes: (NSIndexSet *) indexSet
         toPasteboard: (NSPasteboard *) pboard
{
  /* Extract index */
  unsigned int i, count = [indexSet count];
  unsigned int *indexes = malloc(sizeof(unsigned int)*count);
  unsigned int result = [indexSet getIndexes: indexes maxCount: count inIndexRange: NULL];
  if (result != count)
  {
    NSLog(@"Internal Error: Inconsistent number of indexes");
    if (indexes)
    {
      free(indexes);
      indexes = NULL;
    }
    return NO;
  }

  NSMutableArray *selectedChildren = AUTORELEASE([[NSMutableArray alloc] init]);
  id <OSObject> child = nil;
  for (i = 0; i < count; i++)
  {
    /* We ask object which children are allowed to be dragged */
    child = [[object children] objectAtIndex: indexes[i]];
    if ([object willTakeAwayChild: child])
      [selectedChildren addObject: child];
  }

  if ((selectedChildren == nil) || ([selectedChildren count] < 1))
    return NO;

  NSMutableArray *paths = AUTORELEASE([[NSMutableArray alloc] init]);
  for (i = 0; i < [selectedChildren count]; i++)
  {
    child = [selectedChildren objectAtIndex: i];
    /* We deal with OSNode for now */
    if ([child isKindOfClass: [OSNode class]])
    {
      [paths addObject: [(OSNode *) child path]];
    }
    // FIXME: we need to handle virtual object, especially if dropping
    // target is external application.
  }
  if (indexes)
  {
    free(indexes);
    indexes = NULL;
  }
  
  if ([paths count] > 0)
  {
    [pboard setPropertyList: paths forType: NSFilenamesPboardType];
    return YES;
  }
  else
  {
    return NO;
  }
}

- (BOOL) distributedView: (OSDistributedView *) view
         validateDrop: (id <NSDraggingInfo>) info
         onObject: (id) target
{
  NSPasteboard *pboard = [info draggingPasteboard];
  if ([[pboard types] containsObject: NSFilenamesPboardType])
  {
    id <OSObject> source = nil;
    id property = [pboard propertyListForType: NSFilenamesPboardType];
    /* It may comes from other applications. Check all classes */
    if ([property isKindOfClass: [NSArray class]])
    {
      /* We go through all sources. Some of them might not be allowed.
         As long as there is one allowed, we return YES.
         NOTE: it is better that all children are allowed or not.
         It is a designed issue */
      NSEnumerator *e = [(NSArray *)property objectEnumerator];
      NSString *p = nil;
      while ((p = [e nextObject]))
      {
        source = [factory objectAtPath: p];
        if (target == nil)
        {
          /* Empty space. Add into myself */
          if ([object willAcceptChild: source error: NULL] == YES)
            return YES;
        }
        else
        {
          if ([target willAcceptChild: source error: NULL] == YES)
          {
            return YES;
          }
        }
      }
      return NO;
    }
    else if ([property isKindOfClass: [NSString class]])
    {
      source = [factory objectAtPath: (NSString *) property];
      if (target == nil)
      {
        /* Empty space. Add into myself */
        return [object willAcceptChild: source error: NULL];
      }
      else
      {
        return [target willAcceptChild: source error: NULL];
      }
    }
    else
    {
      /* We do not deal with dictionary for now. 
         Could check -allValues though. */
    }
  }
  return NO;
}

// FIXME: should we have a visual notification when one of the drop failed ?
- (BOOL) distributedView: (OSDistributedView *) view
         acceptDrop: (id <NSDraggingInfo>) info
         onObject: (id) target; // target can be nil if on empty space
{
  NSPasteboard *pboard = [info draggingPasteboard];
  NSDragOperation mask = [info draggingSourceOperationMask];
  BOOL success = NO;

  if ([[pboard types] containsObject: NSFilenamesPboardType])
  {
    NSArray *files = [pboard propertyListForType: NSFilenamesPboardType];
    NSEnumerator *e = [files objectEnumerator];
    NSString *path = nil;
    id <OSObject> child = nil;
    /* For some reason, mask may come here as Move|Copy,
       even in OSDistributedView, we exlusively set either Move or Copy,
       not both. So we check Move first, then Copy. */
    if (mask & NSDragOperationMove)
    {
      //NSLog(@"Move %@", files);
      while ((path = [e nextObject]))
      {
	child = [factory objectAtPath: path];
	if (target)
	{
	  success = [self _put: child into: target move: YES];
	  if (success == NO)
	    break; /* We stop operation here */
	}
	else
	{
	  success = [self _put: child into: object move: YES];
	  if (success == NO)
	    break; /* We stop operation here */
	}
      }
    }
    else if (mask & NSDragOperationCopy)
    {
      //NSLog(@"Copy %@", files);
      while ((path = [e nextObject]))
      {
	child = [factory objectAtPath: path];
	if (target)
	{
	  success = [self _put: child into: target move: NO];
	  if (success == NO)
	    break; /* We stop operation here */
	}
	else
	{
	  success = [self _put: child into: object move: NO];
	  if (success == NO)
	    break; /* We stop operation here */
	}
      }
    }
  }
  else
  {
    success = NO;
  }

  /* We refresh on target */
  if (target)
    [target refresh];
  else
    [object refresh];

  return success;
}

/* Delegate for distributed view */
- (void) distributedView: (OSDistributedView *) view 
              openObject: (id <OSObject>) o inNewWindow: (BOOL) flag
{
  OSFolderWindow *window = nil;
  if ([o hasChildren])
  {
    if (flag)
    {
      /* Open in new window */
      window = [OSFolderWindow windowForObject: o
                         createNewIfNotExisted: YES];
      if (window)
        [window makeKeyAndOrderFront: self];
    } 
    else
    {
      /* We check whether window with o exists. If so, order it front */
      window = [OSFolderWindow windowForObject: o
                         createNewIfNotExisted: NO];
      if (window)
	[window makeKeyAndOrderFront: self];
      else
        [self setObject: o];
    }
  }
  else
  {
    if ([o respondsToSelector: @selector(doLaunching)])
    {
      if ([(NSObject *)o doLaunching] == NO)
      {
        NSRunAlertPanel(_(@"Object Fails to Open"),
	    _(@""), _(@"OK"), nil, nil, nil);
      }
    }
  }
}

- (void) distributedView: (OSDistributedView *) view 
        didSelectObjects: (NSArray *) objects
{
  /* Let show last selection for now */
  OSNode *node = [objects lastObject];
  if ([node isKindOfClass: [OSNode class]])
  {
    [[Inspector sharedInspector] displayPath: [node path]];
  }
}

/* Delegate for OSPathView */
- (void) pathView: (OSPathView *) view selectedPath: (NSString *) path
{
  id <OSObject> o = [factory objectAtPath: path];
  if (o) 
  {
    OSFolderWindow *window = [OSFolderWindow windowForObject: o
                                       createNewIfNotExisted: NO];
    if (window)
      [window makeKeyAndOrderFront: self];
    else
      [self setObject: o];
  }
  else
  {
    NSLog(@"Internal Error: cannot find object for %@", path);
  }
}

/* Delegate for OSShelfView */
- (void) shelfView: (OSShelfView *) view objectClicked: (id <OSObject>) o
{
  OSFolderWindow *window = [OSFolderWindow windowForObject: o
                                     createNewIfNotExisted: NO];
  if (window)
    [window makeKeyAndOrderFront: self];
  else
    [self setObject: o];
}

+ (OSFolderWindow *) windowForObject: (id <OSObject>) object
               createNewIfNotExisted: (BOOL) flag;
{
  /* Find existing window */
  if (object == nil)
    object = [[OSObjectFactory defaultFactory] homeObject];

  NSPoint point = NSMakePoint(200, 200);
  NSEnumerator *e = [windowList objectEnumerator];
  OSFolderWindow *window = nil;
  while ((window = [e nextObject]))
  {
    if ([window isKindOfClass: [OSFolderWindow class]])
    {
      if ([[window object] isEqual: object])
        return window;
      point.x += 40;
      point.y -= 40;
    }
  }

  if (flag)
  {
    /* No window found */
    NSRect rect;
    rect.origin = point;
    rect.size = NSMakeSize(500, 400);
    window = [[OSFolderWindow alloc] initWithContentRect: rect
                             styleMask: NSTitledWindowMask |
                                     NSResizableWindowMask |
                                     NSClosableWindowMask
                            backing: NSBackingStoreBuffered
                              defer: NO];
    [window setReleasedWhenClosed: YES];
    if (object)
      [window setObject: object];
    return window;
  }
  return nil;
}

@end

