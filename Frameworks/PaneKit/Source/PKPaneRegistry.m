/** <title>UKPluginsRegistry</title>

	PKPaneRegistry.m
 
	<abstract>Plugins manager class used to register new plugins and obtain 
    already registered plugins</abstract>
 
	Copyright (C) 2004 Yen-Ju Chen
	Copyright (C) 2004 Uli Kusterer
 
	Author: Yen-Ju Chen
	Author: Uli Kusterer
            Quentin Mathe <qmathe@club-internet.fr>
	Date:   August 2004
 
	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <AppKit/AppKit.h>
#import <PaneKit/PKPaneRegistry.h>
#import <PaneKit/PKPane.h>
#import <PaneKit/CocoaCompatibility.h>
#import "GNUstep.h"

#ifdef HAVE_UKTEST
#import <UnitKit/UnitKit.h>
#endif

#ifdef GNUSTEP
#define APPLICATION_SUPPORT @"ApplicationSupport"
#else /* Cocoa */
#define APPLICATION_SUPPORT @"Application Support"
#endif

static NSFileManager *fm = nil;

/** PKPaneRegistry Description

    <p>Each plugin is represented by an NSMutableDictionary to which you can 
    add your own entries as needed. The keys PKPaneRegistry adds to this 
    dictionary are:</p>
    <deflist>
    <term>bundle</term><desc>NSBundle instance for this plugin.</desc>
    <term>identifier</term><desc>Unique identifier for this plugin (bundle 
    identifier in current implementation)</desc>
    <term>image</term><desc>Icon (NSImage) of the plugin (for display in 
    toolbars etc.)</desc>
    <term>name</term><desc>Display name of the plugin (for display in lists, 
    toolbars etc.)</desc>
    <term>path</term><desc>Full path to the bundle.</desc>
    <term>class</term><desc>NSValue containing pointer to the principal class 
    (type Class) for this bundle, so you can instantiate it.</desc>
    <term>instance</term><desc>If instantiate == YES, this contains an instance 
    of the principal class, instantiated using alloc+init.</desc>
    </deflist>
 */

static PKPaneRegistry *sharedPluginRegistry = nil;

@implementation PKPaneRegistry

/** <p>Returns PKPaneRegistry shared instance (singleton).</p> */
+ (id) sharedRegistry
{
  if (sharedPluginRegistry == nil) {
    sharedPluginRegistry = [[PKPaneRegistry alloc] init];
  }
	
  return sharedPluginRegistry;
}

/* First test to run */
#ifdef HAVE_UKTEST
- (void) test_Init
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    
  UKNotNil(paths);
  UKTrue([paths count] >= 1);
}
#endif

- (id) init
{
  self = [super init];
  if (self == nil)
    return nil;
	
  plugins = [[NSMutableArray alloc] init];
  fm = [NSFileManager defaultManager];
  instantiate = YES;
    
  return self;
}

- (void) dealloc
{
  DESTROY(plugins);
  [super dealloc];
}

#ifdef HAVE_UKTEST
- (void) testLoadPluginOfType
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    
    UKNotNil(bundle);
    UKNotNil(info);

    NSString *supportDir = [[paths objectAtIndex: 0]
        stringByAppendingPathComponent: APPLICATION_SUPPORT];
    BOOL isDir;
    
    UKTrue([fm fileExistsAtPath: supportDir isDirectory:&isDir]);
    UKTrue(isDir);
}
#endif

// FIXME: Implement UTI check support for type parameter.
/** <p>Locates and loads plugin bundles with extension <var>ext</var>.</p>
    <p>Normally this is the only method you need to call to load a plugin.</p> */
- (void) loadPluginsOfType: (NSString *)ext
{
  NSBundle *bundle = [NSBundle mainBundle];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
  NSEnumerator *e = [paths objectEnumerator];
  NSString *path = nil;
  NSString *appName = [[bundle infoDictionary] objectForKey: @"NSExecutable"];
  if (appName == nil)
    appName = [[bundle infoDictionary] objectForKey: @"CFBundleExecutable"];
  NSString *pluginsDir = [[APPLICATION_SUPPORT 
        stringByAppendingPathComponent: appName] 
        stringByAppendingPathComponent: @"PlugIns"];
	
  while ((path = [e nextObject]) != nil)
  {
    [self loadPluginsFromPath: [path stringByAppendingPathComponent: pluginsDir] ofType: ext];
  }
  [self loadPluginsFromPath: [bundle builtInPlugInsPath] ofType: ext];
}

// FIXME: Implement UTI check support for type parameter.
/** <p>Finds plugins within <var>folder</var> path which are identified by an 
    extension matching <var>ext</var>. Finally loads these plugins by calling 
    -loadPluginForPath:.</p> */
- (void) loadPluginsFromPath: (NSString *)folder ofType: (NSString *)ext
{
  NSDirectoryEnumerator *e = [fm enumeratorAtPath: folder];
  NSString *fileName = nil;
	
  while ((fileName = [e nextObject]) != nil )
  {
    [e skipDescendents];  /* Ignore subfolders and don't search in packages. */
		
    /* Skip invisible files: */
    if ([fileName characterAtIndex: 0] == '.')
      continue;
		
    /* Only process ones that have the right suffix: */
    if ([[fileName pathExtension] isEqualToString: ext] == NO)
      continue;
		
    NS_DURING
      /* Get path, bundle and display name: */
      NSString *path = [folder stringByAppendingPathComponent: fileName];
			
      [self loadPluginForPath: path];
            
    NS_HANDLER
            
      NSLog(@"Error while listing PrefPane: %@", localException);
            
    NS_ENDHANDLER
  }
}

#ifdef HAVE_UKTEST
- (void) testLoadPluginForPath
{
    NSArray *paths;
    NSString *path;
#ifdef GNUstep
    paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
    path = [[paths objectAtIndex: 0] stringByAppendingPathComponent: @"PreferencePanes/PrefPaneExample.prefPane"];
#else
    paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, YES);
    path = [[paths objectAtIndex: 0] stringByAppendingPathComponent: @"PreferencePanes/Appearance.prefPane"];
#endif
    NSBundle *bundle = [NSBundle bundleWithPath: path];
    NSDictionary *info = [bundle infoDictionary];
    int lastCount = [plugins count];
    BOOL isDir;
    
    UKTrue([fm fileExistsAtPath: path isDirectory: &isDir]);
    UKNotNil(bundle);
    UKNotNil(info);
    //UKTrue([[info allKeys] containsObject: NAME_ENTRY]);
    
    [self loadPluginForPath: path];
    
    UKTrue(instantiate);
    UKIntsEqual([plugins count], lastCount + 1);
    
#if 0
    UKTrue([[pluginPaths allKeys] containsObject: path]);
        
    info = [pluginPaths objectForKey: path];
    UKNotNil(info);
    UKTrue([[info allKeys] containsObject: @"bundle"]);
    UKTrue([[info allKeys] containsObject: @"image"]);
    UKTrue([[info allKeys] containsObject: @"name"]);
    UKTrue([[info allKeys] containsObject: @"path"]);
    UKTrue([[info allKeys] containsObject: @"class"]);
#endif
}
#endif

/** <p>Loads the plugin bundle located at <var>path</var>, checks it conforms to 
    <em>Plugin schema</em> stored in the related bundle property list.
    </p>
    <p>Every property list values associated to Plugin schema are put in a
    dictionary which represents a plugin object; eventual validity errors
    may be reported each time a value is read in NSBundle description values
    returned by -infoDictionary.</p> */
- (NSMutableDictionary *) loadPluginForPath: (NSString *)path
{
  /* Find existed one */
  NSMutableDictionary *info = [[self loadedPlugins] objectWithValue: path forKey: @"path"];;
	
  /* Not found */
  NSBundle *bundle = [NSBundle bundleWithPath: path];
  NSString *identifier;
  NSImage *image;
  NSString *name;
        
  /* We retrieve plugin's name */
        
  name = [[bundle infoDictionary] objectForKey: @"CFBundleName"];
        
  if (name == nil)
    name = [[bundle infoDictionary] objectForKey: @"ApplicationName"];
  if (name == nil)
    name = [[bundle infoDictionary] objectForKey: @"NSExecutable"];
  if (name == nil)
    name = @"Unknown";
        
  /* We retrieve plugin's identifier */
        
  identifier = [bundle bundleIdentifier];
        
  if (identifier == nil)
  {
    NSLog(@"Plugin %@ is missing an identifier, it may be impossible to use it.", name);

    identifier = path; /* When no identifier is available, falling back on path otherwise. */
  }
       
  /* Get icon, falling back on file icon when needed, or in worst case using our app icon: */
  NSString *iconFileName = [[bundle infoDictionary] objectForKey: @"NSPrefPaneIconFile"];
  NSString *iconPath = nil;
		
  if(iconFileName == nil)
    iconFileName = [[bundle infoDictionary] objectForKey: @"NSIcon"];
  if(iconFileName == nil)
    iconFileName = [[bundle infoDictionary] objectForKey: @"ApplicationIcon"];
  if(iconFileName == nil)
    iconFileName = [[bundle infoDictionary] objectForKey: @"CFBundleIcon"];

  if (iconFileName != nil) 
    iconPath = [bundle pathForImageResource: iconFileName];
            
  if (iconPath == nil)
  {
    image = [NSImage imageNamed: @"NSApplicationIcon"];
  }
  else
  {
    image = [[[NSImage alloc] initWithContentsOfFile: iconPath] autorelease];
  }
        
  /* When image loading has failed, we skip image. */
  /* Add a new entry for this pane to our list: */
    info = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
			bundle, @"bundle", 
            		identifier, @"identifier", 
			name, @"name", 
			path, @"path",
  [NSValue valueWithPointer: [bundle principalClass]], @"class", 
                        nil];

  if (image) {
    [info setObject: image forKey: @"image"];
  }

  if (instantiate)
  {
    id obj = [[[bundle principalClass] alloc] init];
            
    [info setObject: AUTORELEASE(obj) forKey: @"instance"];
  }
  [plugins addObject: info];
	
  return info;
}

#ifdef HAVE_UKTEST
- (void) testLoadedPlugins
{
    //UKNotNil([self loadedPlugins]);
}
#endif

/** <p>Returns the currently registered plugins (loaded by the way).</p> 
    <p><code>Nil</code> is returned when no plugins have been registered.</p> */
- (NSArray *) loadedPlugins
{
  if ([plugins count] > 0)
  {
    return plugins;
  }
  else
  {
    return nil;
  }
}

/** <p>Returns <code>instantiate</code> value.</p>
    <p>Read -setInstantiate: documentation to learn more.</p> */
- (BOOL)  instantiate
{
  return instantiate;
}

/** <p>Sets <var>instantiate</var> value to YES if you want to have 
    plugins main class automatically instantiated when they are loaded.</p> */
- (void) setInstantiate: (BOOL)n
{
  instantiate = n;
}

/** <p>Loads the plugin bundle located at <var>path</var>, 
    checks it conforms to
    <em>Plugin schema</em> stored in the related bundle property list.</p>
    <p>Every property list values associated to <em>Plugin schema</em> 
    are put in a
    dictionary to be used as plugin object, eventual validity errors
    are reported each time a value is read in NSBundle description values
    returned by -infoDictionary.</p> */
- (id) paneAtPath: (NSString *) path
{
  NSMutableDictionary *info = [[self loadedPlugins] objectWithValue: path forKey
: @"path"];
    
  /* We check whether the plugin is already loaded. When it isn't, we try
     to load it. */
  // NOTE: We may check plugin conforms to preference pane schema. In case of
  // invalidity, it would be reloaded. For now, we only check the plugin 
  // availability.
  if (info == nil)
    info = [self loadPluginForPath: path];
    
  id pane = [info objectForKey: @"instance"];
        
  if (pane == nil)
  {
//    NSString *type = [[info objectForKey: @"path"] pathExtension];
                
    Class mainClass = [[info objectForKey: @"class"] pointerValue];
    pane = [[[mainClass alloc] initWithBundle: [info objectForKey: @"bundle"]]
 autorelease];
                
    [info setObject: pane forKey: @"instance"];
  }

   /* Make sure the main view is loaded */
  if ([pane mainView] == nil)
    [pane loadMainView];
    
  return pane;
}

- (id) paneWithIdentifier: (NSString *) identifier
{
  NSMutableDictionary *plugin = [[self loadedPlugins] objectWithValue: identifier forKey: @"identifier"];
  id instance = [plugin objectForKey: @"instance"];
  if (instance) {
    return instance;
  }

  return [self paneAtPath: [plugin objectForKey: @"path"]];
}

- (void) addPlugin: (NSDictionary *) dict
{
  // FIXME: Should we check each value to be valid ?
  if ([dict objectForKey: @"identifier"] == nil)
    return;

  NSString *identifier = [dict objectForKey: @"identifier"];
  if (identifier) {
    [plugins addObject: dict];
  }
}

@end
