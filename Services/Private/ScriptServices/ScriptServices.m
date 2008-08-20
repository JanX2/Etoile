#include <AppKit/AppKit.h>

@interface ScriptServices : NSObject

- (void) run: (NSPasteboard *) bp
    userData: (NSString *) script
       error: (NSString **) err;

@end

@implementation ScriptServices

- (void) run: (NSPasteboard *) pboard
    userData: (NSString *) script
       error: (NSString **) error
{
  /* Let's find the script first */
  NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
  NSArray *services = [infoDict objectForKey: @"NSServices"];
  NSEnumerator *e = [services objectEnumerator];
  NSDictionary *service = nil;
  while ((service = [e nextObject]))
  {
    if ([[service objectForKey: @"NSUserData"] isEqualToString: script])
    {
      NSArray *sendTypes = [service objectForKey: @"NSSendTypes"];
      NSString *type = [[pboard types] firstObjectCommonWithArray: sendTypes];
      if (type == nil)
      {
        *error = [NSString stringWithFormat: @"Cannot find usable pasteboard type for %@", sendTypes];
        return;
      }
      id value = nil;
      if ([type isEqualToString: NSStringPboardType])
      {
        value = [pboard stringForType: type];
      }
      else
      {
        value = [pboard dataForType: type];
      }
      if (value == nil)
      {
        *error = [NSString stringWithFormat: @"Cannot retrieve data for %@", type];
        return;
      }
//      NSLog(@"Run %@ with %@", script, value);

      NSTask *task = [[NSTask alloc] init];
      [task setLaunchPath: script];
      [task setStandardOutput: [NSPipe pipe]];
      [task setEnvironment: [[NSProcessInfo processInfo] environment]];

      if ([[script lastPathComponent] hasPrefix: @"_"])
      {
        /* Use pipe */
        [task setStandardInput: [NSPipe pipe]];
      }
      else
      {
        /* Use parameter */
        [task setArguments: [NSArray arrayWithObjects: value, nil]];
      }

      [task launch];
      if ([[script lastPathComponent] hasPrefix: @"_"])
      {
        /* Use pipe */
NSLog(@"Write Data to Pipe");
        NSFileHandle *writeHandle = [[task standardInput] fileHandleForWriting];
        [writeHandle writeData: [value dataUsingEncoding: NSUTF8StringEncoding]];
        [writeHandle closeFile];
      }

      /* Return here is there is no return value */
      if ([service objectForKey: @"NSReturnTypes"] == nil)
      {
        [task waitUntilExit]; /* It seems to allow clean exit of scripts */
        return;
      }

NSLog(@"Waiting Result...");
      NSFileHandle *readHandle = [[task standardOutput] fileHandleForReading];

      /* Wait until all data is read */
      NSMutableData *result = [[NSMutableData alloc] init];
      while(1)
      {
        NSData *d = [readHandle availableData];
        if ([d length] == 0)
        {
          break;
        }
        [result appendData: d];
      }
/* Seems unnecessary 
      if ([task isRunning] == NO)
      {
        NSData *d = [readHandle availableData];
        [result appendData: d];
      }
*/
      NSString *resultString = [[NSString alloc] initWithData: result encoding: NSUTF8StringEncoding];
      NSLog(@"result '%@'", resultString);

      [pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
      [pboard setString: resultString forType: NSStringPboardType];
      DESTROY(resultString);
      DESTROY(result);
      DESTROY(task);
      return;
    }
  }

  *error = [NSString stringWithFormat: @"Cannot find script %@", script];
  return;
}

- (void) updateScripts
{
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL isDir = NO;
  NSMutableArray *paths = [[NSMutableArray alloc] init];
  NSMutableArray *allScripts = [[NSMutableArray alloc] init];
  NSMutableArray *allPLists = [[NSMutableArray alloc] init];

  NSLog(@"Update Scripts...");

  /* Find all scripts */
  [paths addObject: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"Scripts"]];

  NSArray *ps = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES);
  NSEnumerator *e = [ps objectEnumerator];
  NSString *p = nil;
  while ((p = [e nextObject]))
  {
    [paths addObject: [p stringByAppendingPathComponent: [[NSProcessInfo processInfo] processName]]];
  }

  e = [paths objectEnumerator];
  p = nil;
  while ((p = [e nextObject]))
  {
    if ([fm fileExistsAtPath: p isDirectory: &isDir] && isDir)
    {
      NSArray *contents = [fm directoryContentsAtPath: p];
      int i;
      for (i = 0; i < [contents count]; i++)
      {
        NSString *component = [contents objectAtIndex: i];
        if ([[component pathExtension] isEqualToString: @"plist"])
          continue;
        NSString *fp = [p stringByAppendingPathComponent: component];
        if ([fm fileExistsAtPath: fp isDirectory: &isDir] && (isDir == NO))
        {
          [allScripts addObject: fp];
        }
      }
    }
  }

  e = [allScripts objectEnumerator];
  p = nil;
  while ((p = [e nextObject]))
  {
    NSMutableString *name = AUTORELEASE([[[p lastPathComponent] stringByDeletingPathExtension] mutableCopy]);
    [name replaceOccurrencesOfString: @"_" withString: @" " options: 0 range: NSMakeRange(0, [name length])];
    [name trimSpaces];

    NSLog(@"Processing %@ ... ", name);

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
      [[NSProcessInfo processInfo] processName], @"NSPortName",
      @"run", @"NSMessage",
      [NSArray arrayWithObjects: NSStringPboardType, nil], @"NSSendTypes",
      [NSDictionary dictionaryWithObject: name forKey: @"default"], @"NSMenuItem",
      p, @"NSUserData",
      nil];

    if ([[p stringByDeletingPathExtension] hasSuffix: @"_"])
    {
      [dict setObject: [NSArray arrayWithObjects: NSStringPboardType, nil] forKey: @"NSReturnTypes"];
    }

    /* Do we have custom property list */
    NSString *t = [[p stringByDeletingPathExtension] stringByAppendingPathExtension: @"plist"];
    if ([fm fileExistsAtPath: t isDirectory: &isDir] && (isDir == NO))
    {
      NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile: t];
      if (d)
      {
        id value = nil;
        value = [d objectForKey: @"NSSendTypes"];
        if (value)
        {
          [dict setObject: value forKey: @"NSSendTypes"];
        }
        value = [d objectForKey: @"NSReturnTypes"];
        if (value)
        {
          [dict setObject: value forKey: @"NSReturnTypes"];
        }
        value = [d objectForKey: @"NSMenuItem"];
        if (value)
        {
          [dict setObject: value forKey: @"NSMenuItem"];
        }
        value = [d objectForKey: @"NSKeyEquivalent"];
        if (value)
        {
          [dict setObject: value forKey: @"NSKeyEquivalent"];
        }
      }
    }
//    NSLog(@"dict %@", dict);
    [allPLists addObject: dict];
    DESTROY(dict);
  }

  NSMutableDictionary *infoDict = AUTORELEASE([[[NSBundle mainBundle] infoDictionary] mutableCopy]);
  [infoDict setObject: allPLists forKey: @"NSServices"];

#ifdef GNUSTEP
  p = [[NSBundle mainBundle] pathForResource: @"Info-gnustep" ofType: @"plist"];
  [infoDict writeToFile: p atomically: YES];
#else
  NSLog(@"Not implement in Cocoa");
#endif

  DESTROY(allPLists);
  DESTROY(allScripts);
  DESTROY(paths);

  /* Update Services */
  ps = NSSearchPathForDirectoriesInDomains(GSToolsDirectory, NSSystemDomainMask, YES);
  if ([ps count])
  {
    p = [[ps objectAtIndex: 0] stringByAppendingPathComponent: @"make_services"];
    NSTask *task = [NSTask launchedTaskWithLaunchPath: p arguments: nil];
  }
}

- (void) applicationDidFinishLaunching: (NSNotification *) not
{
  [NSApp setServicesProvider: self];
}

@end

int main(int argc, char** argv)
{
  CREATE_AUTORELEASE_POOL(x);
  ScriptServices *services = [[ScriptServices alloc] init];

  NSArray *args = [[NSProcessInfo processInfo] arguments];
  if ([args containsObject: @"--update"])
  {
    /* If there is one running already, let's stop it */
    id appProxy = [NSConnection rootProxyForConnectionWithRegisteredName: [[NSProcessInfo processInfo] processName] host: @""];
    if (appProxy)
    {
      NS_DURING
        [appProxy terminate: nil];
      NS_HANDLER
        /* Error occurs because application is terminated
         * and connection dies. */
      NS_ENDHANDLER
    }
    
    [services updateScripts];
  }
  else
  {
    [NSApplication sharedApplication];
    [NSApp setDelegate: services];
    [NSApp run];
  }

  DESTROY(services);
  DESTROY(x);
  exit(0);
}


