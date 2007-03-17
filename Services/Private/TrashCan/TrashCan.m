#import "TrashCan.h"
#import "TrashInfo.h"
#import <XWindowServerKit/XFunctions.h>

static TrashCan *sharedInstance;

@implementation TrashCan

/* Private */
/* It check whether a directory exists, if not, create it, and return YES.
   Return NO if it cannot create one */
- (BOOL) directoryExistsOrCreatedAtPath: (NSString *) path
{
  BOOL isDir = NO;
  if ([fileManager fileExistsAtPath: path isDirectory: &isDir]) {
    return isDir;
  } else {
    return [fileManager createDirectoryAtPath: path attributes: nil];
  }
}

/* Return an unique name based on path, 
 * only the last path component including extension. */
- (NSString *) uniqueNameForFile: (NSString *) path
{
  /* Try original name first */
  NSString *name = [path lastPathComponent];
  NSString *p = [trashFilesPath stringByAppendingPathComponent: name];
  if ([fileManager fileExistsAtPath: p] == NO) {
    return name;
  }
  /* Come up an unique name */
  NSString *ext = [name pathExtension];
  name = [name stringByDeletingPathExtension];
  int i;
  for (i = 0; i < 10000; i++) {
    p = [NSString pathWithComponents: [NSArray arrayWithObjects:
              trashFilesPath, name, 
              [NSString stringWithFormat: @"_%d", i], ext, nil]];
    if ([fileManager fileExistsAtPath: p] == NO) {
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
  if (result == NSAlertAlternateReturn) {
    /* To make things easy, we remove subdirectories and recreate new onw */
    /* Let do some basic check before we really remove file */
    NSString *home = NSHomeDirectory();
    NSArray *array  = [NSArray arrayWithObjects:
         home, @"", @"/", @"/usr", @"/bin", @"/sbin", nil];
    if ([array containsObject: trashFilesPath]) {
      NSLog(@"Internal Error: trashFilesPath is one of these directory: %@", array);
    }
    if ([array containsObject: trashInfoPath]) {
      NSLog(@"Internal Error: trashInfoPath is one of these directory: %@", array);
    }
    if ([trashFilesPath hasPrefix: home] == NO) {
      NSLog(@"Internal Error: trashFilesPath is not under home directory: %@", home);
    }
    if ([trashInfoPath hasPrefix: home] == NO) {
      NSLog(@"Internal Error: trashInfoPath is not under home directory: %@", home);
    }
    /* We stop removing if any of them fails */
    if ([fileManager removeFileAtPath: trashFilesPath handler: nil] == NO) 
    {
      NSLog(@"Internal Error: Cannot remove %@", trashFilesPath);
      return;
    } 
    else 
    {
      if ([fileManager createDirectoryAtPath: trashFilesPath 
                                  attributes: nil] == NO)
      {
        NSLog(@"Internal Error: Cannot create %@", trashFilesPath);
        return;
      }
    }
    if ([fileManager removeFileAtPath: trashInfoPath handler: nil] == NO) 
    {
      NSLog(@"Internal Error: Cannot remove %@", trashInfoPath);
      return;
    } 
    else 
    {
      if ([fileManager createDirectoryAtPath: trashInfoPath 
                                  attributes: nil] == NO)
      {
        NSLog(@"Internal Error: Cannot create %@", trashInfoPath);
        return;
      }
    }
  }
}

- (void) recoverAllFiles: (id) sender
{
  NSLog(@"Recover all files");
  NSEnumerator *e = [[fileManager directoryContentsAtPath: trashFilesPath] objectEnumerator];
  NSString *name = nil;
  while ((name = [e nextObject])) {
    NSString *p = [[trashInfoPath stringByAppendingPathComponent: name] stringByAppendingPathExtension: @"trashinfo"];
    TrashInfo *ti = [[TrashInfo alloc] initWithContentsOfFile: p];
    /* move the file back */
    NSString *w = [trashFilesPath stringByAppendingPathComponent: name];
    if ([fileManager movePath: w toPath: [ti path] handler: nil] == NO) {
      NSLog(@"Cannot recover file %@ from %@", [ti path], w);
    } else {
      if ([fileManager removeFileAtPath: p handler: nil] == NO) {
         NSLog(@"Cannot remove %@", p);
      }
    }
  }
  /* Let do a final check */
  if ([[fileManager directoryContentsAtPath: trashFilesPath] count] > 0)  {
    NSLog(@"trashFilesPath is not empty: %@", trashFilesPath);
  }
  if ([[fileManager directoryContentsAtPath: trashInfoPath] count] > 0)  {
    NSLog(@"trashInfoPath is not empty: %@", trashInfoPath);
  }
}

- (void) recoverSelectedFiles: (id) sender
{
  NSLog(@"Recover selected files: Do nothing now.");
}

/* Move file in files/ and write .trashinfo in info/ */
- (void) writeFiles: (NSArray *) files
{
//  NSLog(@"%@", files);
  NSEnumerator *e = [files objectEnumerator];
  NSString *p = nil;
  while ((p = [e nextObject])) {
    /* Find an unique name */
    NSString *name = [self uniqueNameForFile: p];
    if (name == nil) {
      int result = NSRunAlertPanel(_(@"Trash can is full !"),
             _(@"Trash can cannot add this file. Do you want to empty trash can now ? "),
             _(@"Yes, Empty Trash Can Now and Continue"), _(@"No, Abort"), nil, nil);
      if (result == NSAlertDefaultReturn) {
        [self emptyTrashCan: self];
        /* Get name again */
        name = [self uniqueNameForFile: p];
        if (name == nil) {
          /* Something is not right. Warn and quit */
          NSRunAlertPanel(_(@"Internal Error !"),
             _(@"Trash can cannot find an unique name even it is empty."),
             _(@"Quit Trash Can"), nil, nil, nil);
          [NSApp terminate: self];
        }
      } else {
        /* Abort */
        return;
      }
    }
    /* Get unique name here. Write .trashinfo file */
    //NSLog(@"%@ (%@)", p, name);
    TrashInfo *ti = [[TrashInfo alloc] init];
    [ti setPath: p];
    [ti setDeletionDate: [NSCalendarDate calendarDate]];
    //NSLog(@"%@ %@", [ti path], [ti deletionDate]);
    /* Move file */
    NSString *t = [trashFilesPath stringByAppendingPathComponent: name];
    if ([fileManager movePath: p toPath: t handler: nil]) {
      /* Write .trashinfo */
      NSString *w = [[trashInfoPath stringByAppendingPathComponent: name] stringByAppendingPathExtension: @"trashinfo"];
      if ([ti writeToFile: w] == NO) {
        NSLog(@"Write .trashinfo failed");
        /* move the file back */
        if ([fileManager movePath: t toPath: p handler: nil] == NO) {
          NSLog(@"Cannot move file back. Totally failed");
        }
      }
    } else {
      NSLog(@"Cannot move file into trash can: %@", p);
    }
    DESTROY(ti);
  }
}

- (void) applicationWillFinishLaunching: (NSNotification *) not
{
  /* Shared */
  fileManager = [NSFileManager defaultManager];

  /* We move appIcon on level up so that it stay on top of all window. */
  appIcon = [NSApp iconWindow];
  [appIcon setLevel: NSNormalWindowLevel+1];

  iconView = [[TrashCanView alloc] initWithFrame: NSMakeRect(8, 8, 48, 48)];
  [iconView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
//  [iconView setImage: [NSImage imageNamed: @"GNUstep"]];
  [[appIcon contentView] addSubview: iconView];
  AUTORELEASE(iconView);

  /* We build menu for app icon */
  NSMenu *menu = [[NSMenu alloc] initWithTitle: _(@"TrashCan")];
  [menu addItemWithTitle: _(@"Empty Trash")
                  action: @selector(emptyTrashCan:)
           keyEquivalent: nil];
  [menu addItemWithTitle: _(@"Recover all files")
                  action: @selector(recoverAllFiles:)
           keyEquivalent: nil];
#if 0
  [menu addItemWithTitle: _(@"Recover selected files")
                  action: @selector(recoverSelectedFiles:)
           keyEquivalent: nil];
#endif
  [menu addItemWithTitle: _(@"Quit")
                  action: @selector(terminate:)
           keyEquivalent: nil];
  [iconView setMenu: menu];
  DESTROY(menu);
                  
  /* check the existance of trash directory */
  ASSIGN(trashCanPath, [XDGDataHomePath() stringByAppendingPathComponent: @"Trash"]);
  ASSIGN(trashFilesPath, [trashCanPath stringByAppendingPathComponent: @"files"]);
  ASSIGN(trashInfoPath, [trashCanPath stringByAppendingPathComponent: @"info"]);
  BOOL success = [self directoryExistsOrCreatedAtPath: trashCanPath];
  if (success) {
    success = [self directoryExistsOrCreatedAtPath: trashFilesPath];
    if (success) {
      success = [self directoryExistsOrCreatedAtPath: trashInfoPath];
    }
  } 

  if (success == NO) {
    NSRunAlertPanel(_(@"Failed to directory !"),
             _(@"TrashCan cannot create directory in the home directory"),
             _(@"Quit"), nil, nil, nil);
    [NSApp terminate: nil];
  }
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
}

- (void) applicationWillTerminate: (NSNotification *) not
{
}

- (id) init
{
  self = [super init];

  return self;
}

- (void) dealloc
{
  DESTROY(trashCanPath);
  DESTROY(trashFilesPath);
  DESTROY(trashInfoPath);
  [super dealloc];
}

+ (TrashCan *) sharedTrashCan
{
  if (sharedInstance == nil) {
    sharedInstance = [[TrashCan alloc] init];
  }
  return sharedInstance;
}
@end

