#include "WMDockedAppPanel.h"
#include "WMDialogController.h"
#include "dock.h"

static WMDockedAppPanel *sharedInstance;

@interface WMDockedAppPanel (WMPrivate)
- (void) createInterface;
- (void) cancelButtonAction: (id) sender;
- (void) okButtonAction: (id) sender;
- (void) browseButtonAction: (id) sender;

- (void) updateSettingsPanelIcon;
@end

@implementation WMDockedAppPanel

+ (WMDockedAppPanel *) sharedPanel
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[WMDockedAppPanel alloc] init];
  }
  return sharedInstance;
}

- (id) init
{
  [self createInterface];

  return self;
}

- (void) dealloc
{
  DESTROY(iconView);
  DESTROY(nameField);
  DESTROY(startButton);
  DESTROY(lockButton);

  DESTROY(pathField);
  DESTROY(commandField);
  DESTROY(dndField);
  DESTROY(dndLabel);
  DESTROY(iconField);

  [self setAppIcon: NULL];

  [super dealloc];
}

- (void) createInterface
{
  NSBox *box;
  NSButton *button;
  NSTextField *field;
  NSRect rect;
  NSSize size;
  int button_height = 25;
  size = NSMakeSize(300, 500);
  rect = NSMakeRect(300, 100, size.width, size.height);

  self = [super initWithContentRect: rect
	                  styleMask: (NSTitledWindowMask | NSClosableWindowMask)
			  backing: NSBackingStoreBuffered
			  defer: YES];
  [self setTitle: @"Docked Application Settings"];
  [self setHidesOnDeactivate: NO];

  rect = NSMakeRect(10, size.height-10-64, 64, 64);
  iconView = [[NSImageView alloc] initWithFrame: rect];
  [[self contentView] addSubview: iconView];

  rect = NSMakeRect(NSMaxX(rect)+10, rect.origin.y, 
		  size.width-NSMaxX(rect)-20, rect.size.height);
  nameField = [[NSTextField alloc] initWithFrame: rect];
  [nameField setStringValue: @"App Name"];
  [nameField setSelectable: NO];
  [nameField setBezeled: NO];
  [nameField setDrawsBackground: NO];
  [[self contentView] addSubview: nameField];

  rect = NSMakeRect(10, rect.origin.y-3-button_height, 
		  size.width-20, button_height);
  startButton = [[NSButton alloc] initWithFrame: rect];
  [startButton setButtonType: NSSwitchButton];
  [startButton setStringValue: @"Start when Window Maker is started"];
  [[self contentView] addSubview: startButton];
  
  rect = NSMakeRect(10, rect.origin.y-3-button_height, 
		  size.width-20, button_height);
  lockButton = [[NSButton alloc] initWithFrame: rect];
  [lockButton setButtonType: NSSwitchButton];
  [lockButton setStringValue: @"Lock (prevent accidental removal)"];
  [[self contentView] addSubview: lockButton];

  rect = NSMakeRect(10, rect.origin.y-62, size.width-20, 57);
  box = [[NSBox alloc] initWithFrame: rect];
  [box setTitle: @"Application path and arguments"];
  [[self contentView] addSubview: box];

  pathField = [[NSTextField alloc] initWithFrame: NSMakeRect(3, 3, rect.size.width-20, button_height)];
  [pathField setStringValue: @"path"];
  [box addSubview: pathField];

  DESTROY(box);

  rect = NSMakeRect(10, rect.origin.y-92, rect.size.width, 87);
  box = [[NSBox alloc] initWithFrame: rect];
  [box setTitle: @"Command for middle-click launch"];
  [[self contentView] addSubview: box];

  commandField = [[NSTextField alloc] initWithFrame: NSMakeRect(3, 33, rect.size.width-20, button_height)];
  [commandField setStringValue: @"command"];
  [box addSubview: commandField];

  field = [[NSTextField alloc] initWithFrame: NSMakeRect(3, 3, rect.size.width-20, button_height)];
  [field setStringValue: @"\%s will be replaced with current selection"];
  [field setSelectable: NO];
  [field setBezeled: NO];
  [field setDrawsBackground: NO];
  [box addSubview: field];
  DESTROY(field);

  DESTROY(box);

  rect = NSMakeRect(10, rect.origin.y-92, rect.size.width, 87);
  box = [[NSBox alloc] initWithFrame: rect];
  [box setTitle: @"Command for files dropped with DND"];
  [[self contentView] addSubview: box];

  dndField = [[NSTextField alloc] initWithFrame: NSMakeRect(3, 33, rect.size.width-20, button_height)];
  [dndField setStringValue: @"drag and rop"];
  [box addSubview: dndField];

  field = [[NSTextField alloc] initWithFrame: NSMakeRect(3, 3, rect.size.width-20, button_height)];
#ifdef XDND
  [field setStringValue: @"\%d will be replaced with the file name"];
#else
  [field setStringValue: @"DND support was not compiled in"];
#endif
  [field setSelectable: NO];
  [field setBezeled: NO];
  [field setDrawsBackground: NO];
  [box addSubview: field];
  DESTROY(field);

  DESTROY(box);

  rect = NSMakeRect(10, rect.origin.y-62, size.width-20, 57);
  box = [[NSBox alloc] initWithFrame: rect];
  [box setTitle: @"Icon Image"];
  [[self contentView] addSubview: box];

  iconField = [[NSTextField alloc] initWithFrame: NSMakeRect(3, 3, rect.size.width-20-70, button_height)];
  [iconField setStringValue: @"icon path"];
  [box addSubview: iconField];

  button = [[NSButton alloc] initWithFrame: NSMakeRect(rect.size.width-10-65, 3, 60, button_height)];
  [button setStringValue: @"Browse..."];
  [button setTarget: self];
  [button setAction: @selector(browseButtonAction:)];
  [box addSubview: button];
  DESTROY(button);

  DESTROY(box);

  /* cancel button */
  rect = NSMakeRect(size.width-70-70, 10, 60, button_height);
  button = [[NSButton alloc] initWithFrame: rect];
  [button setStringValue: @"Cancel"];
  [button setTarget: self];
  [button setAction: @selector(cancelButtonAction:)];
  [[self contentView] addSubview: button];
  DESTROY(button);

  /* ok button */
  rect = NSMakeRect(size.width-70, 10, 60, button_height);
  button = [[NSButton alloc] initWithFrame: rect];
  [button setStringValue: @"OK"];
  [button setTarget: self];
  [button setAction: @selector(okButtonAction:)];
  [[self contentView] addSubview: button];
  DESTROY(button);

  [self setDelegate: self];
}

- (void) cancelButtonAction: (id) sender
{
  [self setAppIcon: NULL];
  [self close];
}

- (void) okButtonAction: (id) sender
{
  NSString *path = [iconField stringValue];
  if (!wIconChangeImageFile(aicon->icon, (char*)[path cString]))
  {
    NSString *s = [NSString stringWithFormat: @"Could not open specified icon file: %@", path];
    int result = NSRunAlertPanel(@"Error", s, @"OK", @"Ignore", nil);
    if (result == NSAlertDefaultReturn)
    {
      return;
    }
  }
  else
  {
    if (aicon == aicon->icon->core->screen_ptr->clip_icon)
      wClipIconPaint(aicon);
    else
      wAppIconPaint(aicon);

    wDefaultChangeIcon(aicon->dock->screen_ptr, aicon->wm_instance,
		    aicon->wm_class, (char*)[path cString]);
  }

  path = [pathField stringValue];

  if (aicon->command)
    wfree(aicon->command);

  if (path && [path length] > 0)
  {
    aicon->command = wstrdup((char*)[path cString]);
  }
  else
  {
    aicon->command = NULL;
  }

  if (!aicon->wm_class && !aicon->wm_instance && aicon->command
		  && strlen(aicon->command) > 0)
  {
    aicon->forced_dock = 1;
  }

  path = [commandField stringValue];

  if (aicon->paste_command)
    wfree(aicon->paste_command);

  if (path && [path length] > 0)
  {
    aicon->paste_command = wstrdup((char*)[path cString]);
  }
  else
  {
    aicon->paste_command = NULL;
  }

#ifdef XDND
  path = [dndField stringValue];

  if (aicon->dnd_command)
    wfree(aicon->dnd_command);

  if (path && [path length] > 0)
  {
    aicon->dnd_command = wstrdup((char*)[path cString]);
  }
  else
  {
    aicon->dnd_command = NULL;
  }
#endif

  aicon->auto_launch = [startButton state];
  aicon->lock = [lockButton state];

  [self setAppIcon: NULL]; 
  [self close];
}

- (void) browseButtonAction: (id) sender
{
  NSString *path = [[WMDialogController sharedController] 
	  iconChooserDialogWithInstance: [NSString stringWithCString: aicon->wm_instance]
          class: [NSString stringWithCString: aicon->wm_class]]; 
  if (path)
  {
    [iconField setStringValue: path];
    [self updateSettingsPanelIcon];
  }
}

- (void) setAppIcon: (WAppIcon *) icon
{
  if (icon)
  {
    if (aicon && (aicon != icon))
    {
      /* remove old one */
      aicon->editing = 0;
    }
    aicon = icon;
    aicon->editing = 1;

    /* name */
    if (aicon->wm_class && strcmp(aicon->wm_class, "DockApp") == 0)
    {
      [nameField setStringValue: [NSString stringWithCString: aicon->wm_instance]];
    }
    else
    {
      [nameField setStringValue: [NSString stringWithCString: aicon->wm_class]];
    }

    /* autolaunch & lock */
    [startButton setState: (aicon->auto_launch ? NSOnState : NSOffState)];
    [lockButton setState: (aicon->lock ? NSOnState : NSOffState)];

    /* commands */
    [pathField setStringValue: [NSString stringWithCString: aicon->command]];
    [commandField setStringValue: [NSString stringWithCString: aicon->paste_command]];
#ifdef XDND
    [dndField setEnabled: YES];
    [dndField setStringValue: [NSString aicon->dnd_command]];
#else
    [dndField setEnabled: NO];
    [dndField setEditable: NO];
    [dndField setSelectable: NO];
    [dndField setStringValue: @""];
#endif

    /* icon */
    char *path = wDefaultGetIconFile(aicon->dock->screen_ptr, 
		    aicon->wm_instance, aicon->wm_class, True);
    if (path && path[0] != 0)
    {
      [iconField setStringValue: [NSString stringWithCString: path]];
      [self updateSettingsPanelIcon];
    }
    else
    {
      [iconField setStringValue: @""];
      [iconView setImage: nil];
    }

  }
  else
  {
    if (aicon)
    {
      aicon->editing = 0; 
      aicon = NULL;
    }
  }
}

- (WAppIcon *) appIcon
{
  return aicon;
}

- (void) updateSettingsPanelIcon
{
  NSString *file = [iconField stringValue];
  if (file == nil)
  {
    [iconView setImage: nil];
  }
  else
  {
    char *path;
    path = FindImage(wPreferences.icon_path, (char*)[file cString]);
    NSString *p = [NSString stringWithCString: path];

    if (!path) {
      NSLog(@"Warning: could not find icon %@, used in a docked application", file);
      [iconView setImage: nil];
      return;
    }
    else
    {
      if ([[p pathExtension] compare: @"XPM" options: NSCaseInsensitiveSearch] == NSOrderedSame)
      {
	/* GNUstep cannot handle XPM */
        return;
      }
      else
      {
        NSImage *image = [[NSImage alloc] initWithContentsOfFile: p];
	[iconView setImage: image];
	DESTROY(image);
      }
    }
    wfree(path);
  }
}

/** delegate */
- (void) windowWillClose: (NSNotification *) not
{
  [self setAppIcon: NULL];
}

@end

