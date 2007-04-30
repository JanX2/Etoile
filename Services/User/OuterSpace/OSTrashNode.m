#import "OSTrashNode.h"

@implementation OSTrashNode

- (BOOL) hasChildren
{
  return NO;
}

- (void) setPath: (NSString *) p
{
  [super setPath: p];

  NSString *name = [[p lastPathComponent] stringByDeletingPathExtension];
  ASSIGN(trashInfoPath, [[[[[p stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"info"] stringByAppendingPathComponent: name] stringByAppendingPathExtension: @"trashinfo"]);
}

- (void) setOriginalPath: (NSString *) string
{
  /* Keep a copy in NSURL */
  ASSIGN(url, [NSURL fileURLWithPath: string]);

  if ([url isFileURL] == NO) 
  {
    NSLog(@"Not a URL conformed path: %@", string);
  }
}

- (NSString *) originalPath
{
  return [url path];
}

/* Exact string for 'DeletionDate' key (YYYYMMDDThhmmss) */
- (void) setDeletionDate: (NSCalendarDate *) d
{
  ASSIGN(date, d);
}

- (NSCalendarDate *) deletionDate
{
  return date;
}

- (id) init
{
  self = [super init];
  lines = [[NSMutableArray alloc] init];
  return self;
}

- (id) initWithContentsOfFile: (NSString *) p
{
  BOOL success = YES;
  NSString *s;
  int i = 0;

  self = [self init];
  [lines addObjectsFromArray: [[NSString stringWithContentsOfFile: p] 
                                           componentsSeparatedByString: @"\n"]];
  if ([lines count] < 3) 
  {
    NSLog(@"Cannot read trash info or it contains less than 3 lines: %@", p);
    success = NO;
  } 

  if (success) 
  {
    /* First line must be '[Trash Info]' */
    s = [lines objectAtIndex: 0];

    if ([[s stringByTrimmingSpaces] isEqualToString: @"[Trash Info]"] == NO) 
    {
      NSLog(@"First line is not [Trash Info]");
      success = NO;
    } 
    else 
    {
      /* Remove first line here */
      [lines removeObject: s];
    }
  }

  if (success) 
  {
    /* Find path or deletion date and remove it */
    for (i = 0; i < [lines count]; i++) 
    {
      s = [lines objectAtIndex: i];

      /* Only the first 'Path' or 'DeletionDate' are accepted */
      /* We do not modify s here (trim space)
       * because we need it to remove object */
      if ((url == nil) && [[s stringByTrimmingSpaces] hasPrefix: @"Path"]) 
      {
	RETAIN(s);
	[lines removeObject: s];
	i--;
	AUTORELEASE(s);
	s = [[s componentsSeparatedByString: @"="] lastObject];
	[self setOriginalPath: [s stringByTrimmingSpaces]];
	continue;
      } 

      if ((date == nil) && 
	  [[s stringByTrimmingSpaces] hasPrefix: @"DeletionDate"]) 
      {
	RETAIN(s);
	[lines removeObject: s];
	i--;
	AUTORELEASE(s);
	s = [[[s componentsSeparatedByString: @"="] lastObject] 
						stringByTrimmingSpaces];
	[self setDeletionDate: [NSCalendarDate dateWithString: s
					calendarFormat: @"%Y%m%dT%H%M%S"]];
	continue;
      }
    }
  }

  if ((url == nil) || (date == nil)) 
  {
    NSLog(@"Cannot get original path or deletion date");
    success = NO;
  }

  if (success) 
  {
    return self;
  } 
  else  
  {
    [self dealloc];
    return nil;
  }
}

- (void) dealloc
{
  DESTROY(lines);
  DESTROY(url);
  DESTROY(date);
  [super dealloc];
}

- (BOOL) writeTrashInfo
{
  NSString *s = nil;
  [lines insertObject: @"[Trash Info]" atIndex: 0];

  s = [NSString stringWithFormat: @"Path=%@", [self originalPath]];
  [lines insertObject: s atIndex: 1];

  s = [NSString stringWithFormat: @"DeletionDate=%@", 
	[[self deletionDate] descriptionWithCalendarFormat: @"%Y%m%dT%H%M%S"]];
  [lines insertObject: s atIndex: 2];
  //NSLog(@"lines %@", lines);

  NSMutableString *output = AUTORELEASE([[NSMutableString alloc] init]);
  NSEnumerator *e = [lines objectEnumerator];

  while ((s = [e nextObject])) 
  {
    [output appendString: s];
    [output appendString: @"\n"];
  }

  return [output writeToFile: trashInfoPath atomically: YES];
}

- (BOOL) removeTrashInfo
{
  return [fm removeFileAtPath: trashInfoPath handler: nil];
}

@end
