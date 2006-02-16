#include "WMDialogController.h"
#include "WMApplication.h"
#include "screen.h"

#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif

static WMDialogController *sharedInstance;

@implementation WMDialogController

+ (WMDialogController *) sharedController
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[WMDialogController alloc] init];
  }
  return sharedInstance;
}

/** window delegate **/
/* Must use this way to stop modal.
 * It won't work properly otherwise
 */
- (void) windowWillClose: (NSNotification *) not
{
  if ([not object] == inputPanel)
  {
    [NSApp stopModal];
  }
  else if ([not object] == exitPanel)
  {
    [NSApp stopModal];
  }
  else if ([not object] == chooserPanel)
  {
    [NSApp stopModal];
  }
}

/******* icon chooser *******/
- (int) browser: (NSBrowser *) sender numberOfRowsInColumn: (int) column
{
  /* This is called before browserAction */
  switch(column) {
    case 0:
    {
      return [directories count];
    }
    case 1:
    {
      /* Cache icons. Hope it is not too heavy.
       * if directory does not exist,
       * don't raise message as WindowMaker.
       * Simply show empty.
       */
      {
        int row = [browser selectedRowInColumn: 0];
        NSFileManager *manager = [NSFileManager defaultManager];
	NSString *p = [[directories objectAtIndex: row] stringByExpandingTildeInPath];
	BOOL isDir;
	if ([manager fileExistsAtPath: p isDirectory: &isDir] && isDir)
	{
	  ASSIGN(icons, [manager directoryContentsAtPath: p]);
	  return [icons count];
	}
	else
	{
	  DESTROY(icons);
	  return 0;
	}
      }
    }
  }
  return 0;
}

- (NSString *) browser: (NSBrowser *) sender titleOfColumn: (int) column
{
  switch(column) {
    case 0:
      return @"Directories";
    case 1:
      return @"Icons";
  }
  return @"";
}

- (void) browser: (NSBrowser *) sender
         willDisplayCell: (id) cell
	 atRow: (int) row
	 column: (int) column
{
  switch(column) {
    case 0:
    {
      [cell setStringValue: [directories objectAtIndex: row]];
      [cell setLeaf: NO];
      return;
    }
    case 1:
    {
      [cell setStringValue: [icons objectAtIndex: row]];
      [cell setLeaf: YES];
      return;
    }
  }
}

- (void) browserAction: (id) sender
{
  int selectedColumn = [browser selectedColumn];
  switch(selectedColumn) {
    case 0:
    {
      int row = [browser selectedRowInColumn: 0];
      ASSIGN(iconPath, [directories objectAtIndex: row]);
      [chooserOKButton setEnabled: NO];
      break;
    }
    case 1:
    {
      int row0 = [browser selectedRowInColumn: 0];
      int row1 = [browser selectedRowInColumn: 1];
      ASSIGN(iconPath, [[directories objectAtIndex: row0] stringByAppendingPathComponent: [icons objectAtIndex: row1]]);
      /* preview icon */
      NSFileManager *manager = [NSFileManager defaultManager];
      BOOL isDir;
      if ([manager fileExistsAtPath: iconPath isDirectory: &isDir] && isDir == NO)
      {
        NSImage *image = [[NSImage alloc] initWithContentsOfFile: iconPath];
        [iconView setImage: image];
	[chooserOKButton setEnabled: YES];
      }
      else
      {
	DESTROY(iconPath);
	[iconView setImage: nil];
	[chooserOKButton setEnabled: NO];
      }
      break;
    }
  }
  if (iconPath)
    [iconField setStringValue: iconPath];
}

- (void) chooserCancelButtonAction: (id) sender
{
  modal = NO;
  chooserResponse = NSAlertAlternateReturn;
  [chooserPanel close];
}

- (void) chooserOkButtonAction: (id) sender
{
  modal = NO;
  chooserResponse = NSAlertDefaultReturn;
  [chooserPanel close];
}

- (NSString *) iconChooserDialogWithInstance: (NSString *) instance
                           class: (NSString *) class
{
  if (chooserPanel == nil)
  {
    NSButton *button;
    NSTextField *field;

    chooserPanel = [[NSPanel alloc] initWithContentRect: NSMakeRect(300, 300, 409, 300)
                                          styleMask: NSTitledWindowMask
		                          backing: NSBackingStoreBuffered
		                          defer: YES];

    browser = [[NSBrowser alloc] initWithFrame: NSMakeRect(10, 70, 320, 220)];
    [browser setHasHorizontalScroller: NO];
    [browser setMaxVisibleColumns: 2];
    [browser setAllowsEmptySelection: NO];
    [browser setAllowsMultipleSelection: NO];
    [browser setDelegate: self];
    [browser setTarget: self];
    [browser setAction: @selector(browserAction:)];
    [[chooserPanel contentView] addSubview: browser];
    RELEASE(browser);

    iconView = [[NSImageView alloc] initWithFrame: NSMakeRect(335, 150, 64, 64)];

    [[chooserPanel contentView] addSubview: iconView];

    field = [[NSTextField alloc] initWithFrame: NSMakeRect(10, 40, 80, 25)];
    [field setStringValue: @"File Name:"];
    [field setSelectable: NO];
    [field setBezeled: NO];
    [field setDrawsBackground: NO];
    [[chooserPanel contentView] addSubview: field];
    DESTROY(field);

    iconField = [[NSTextField alloc] initWithFrame: NSMakeRect(100, 40, 280, 25)];
    [iconField setEnabled: NO];
    [iconField setSelectable: NO];
    [iconField setEditable: NO];
    [[chooserPanel contentView] addSubview: iconField];
    RELEASE(iconField);

    // Cancel
    button = [[NSButton alloc] initWithFrame: NSMakeRect(250, 10, 50, 25)];
    [button setStringValue: @"Cancel"];
    [button setTarget: self];
    [button setAction: @selector(chooserCancelButtonAction:)];
    [[chooserPanel contentView] addSubview: button];
    DESTROY(button);

    chooserOKButton = [[NSButton alloc] initWithFrame: NSMakeRect(310, 10, 50, 25)];
    [chooserOKButton setStringValue: @"OK"];
    [chooserOKButton setTarget: self];
    [chooserOKButton setAction: @selector(chooserOkButtonAction:)];
    [chooserOKButton setEnabled: NO];
    [[chooserPanel contentView] addSubview: chooserOKButton];
    RELEASE(chooserOKButton);

    [chooserPanel setDelegate: self];
  }

  /* Prevent running modal again */
  if (modal == YES)
    return nil;

  NSString *paths = [NSString stringWithCString: wPreferences.icon_path];
  ASSIGN(directories, [paths componentsSeparatedByString: @":"]);

  [chooserPanel setTitle: [NSString stringWithFormat: @"Icon Chooser[%@.%@]", instance, class]];

  modal = YES;
  [NSApp runModalForWindow: chooserPanel];

  if (chooserResponse == NSAlertDefaultReturn)
    return iconPath;
  else // Cancelled
    return nil;

}


/******** message dialog ***********/

- (int) messageDialogWithTitle: (NSString *) title
                       message: (NSString *) message
                 defaultButton: (NSString *) defaultButton
               alternateButton: (NSString *) alternateButton
                   otherButton: (NSString *) otherButton
{
  return NSRunAlertPanel(title, message, 
		  defaultButton, alternateButton, otherButton, nil);
}

/********* Exit Panel ***********/

- (void) exitCancelButtonAction: (id) sender
{
  modal = NO;
  exitResponse = NSAlertAlternateReturn;
  [exitPanel close];
}

- (void) exitOkButtonAction: (id) sender
{
  modal = NO;
  exitResponse = NSAlertDefaultReturn;
  [exitPanel close];
}

- (void) exitKillButtonAction: (id) sender
{
  modal = NO;
  exitResponse = NSAlertOtherReturn;
  [exitPanel close];
}

- (void) setSaveState: (id) sender
{
  wPreferences.save_session_on_exit = [saveStateButton state];
  NSLog(@"%d", wPreferences.save_session_on_exit);
}

- (int) exitDialogWithTitle: (NSString *) title
                    message: (NSString *) message
              defaultButton: (NSString *) defButton
            alternateButton: (NSString *) altButton
                otherButton: (NSString *) othButton
{
  if (exitPanel == nil)
  {
    exitPanel = [[NSPanel alloc] initWithContentRect: NSMakeRect(300, 300, 300, 200)
                                          styleMask: NSTitledWindowMask
		                          backing: NSBackingStoreBuffered
		                          defer: YES];

    exitTitle = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 150, 260, 30)];
    [exitTitle setSelectable: NO];
    [exitTitle setBezeled: NO];
    [exitTitle setDrawsBackground: NO];
    [[exitPanel contentView] addSubview: exitTitle];
    AUTORELEASE(exitTitle);

    exitMessage = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 90, 260, 50)];
    [exitMessage setSelectable: NO];
    [exitMessage setBezeled: NO];
    [exitMessage setDrawsBackground: NO];
    [[exitPanel contentView] addSubview: exitMessage];
    AUTORELEASE(exitMessage);

    saveStateButton = [[NSButton alloc] initWithFrame: NSMakeRect(20, 50, 200, 20)];
    [saveStateButton setTitle: @"Save workspace state"];
    [saveStateButton setButtonType: NSSwitchButton];
    [saveStateButton setState: wPreferences.save_session_on_exit];
    [saveStateButton setTarget: self];
    [saveStateButton setAction: @selector(setSaveState:)];
    [[exitPanel contentView] addSubview: saveStateButton];
    AUTORELEASE(saveStateButton);

    exitOtherButton = [[NSButton alloc] initWithFrame: NSMakeRect(50, 20, 40, 20)];
    [exitOtherButton setTarget: self];
    [exitOtherButton setAction: @selector(exitKillButtonAction:)];
    [[exitPanel contentView] addSubview: exitOtherButton];
    AUTORELEASE(exitOtherButton);

    exitAlternateButton = [[NSButton alloc] initWithFrame: NSMakeRect(100, 20, 40, 20)];
    [exitAlternateButton setTarget: self];
    [exitAlternateButton setAction: @selector(exitCancelButtonAction:)];
    [[exitPanel contentView] addSubview: exitAlternateButton];
    AUTORELEASE(exitAlternateButton);

    exitDefaultButton = [[NSButton alloc] initWithFrame: NSMakeRect(150, 20, 40, 20)];
    [exitDefaultButton setTarget: self];
    [exitDefaultButton setAction: @selector(exitOkButtonAction:)];
    [[exitPanel contentView] addSubview: exitDefaultButton];
    AUTORELEASE(exitDefaultButton);

    [exitPanel setDelegate: self];
  }

  [exitTitle setStringValue: title];
  [exitMessage setStringValue: message];
  [exitDefaultButton setStringValue: defButton];
  [exitAlternateButton setStringValue: altButton];
  [exitOtherButton setStringValue: othButton];

  /* Prevent running modal again */
  if (modal == YES)
    return WAPRAlternate;

  if (title)
  {
    [exitTitle setHidden: NO];
    [exitTitle setStringValue: title];
  }
  else
  {
    [exitTitle setHidden: YES];
  }

  if (message)
  {
    [exitMessage setHidden: NO];
    [exitMessage setStringValue: message];
  }
  else
  {
    [exitMessage setHidden: YES];
  }

  if (defButton)
  {
    [exitDefaultButton setHidden: NO];
    [exitDefaultButton setStringValue: defButton];
  }
  else
  {
    [exitDefaultButton setHidden: YES];
  }

  if (altButton)
  {
    [exitAlternateButton setHidden: NO];
    [exitAlternateButton setStringValue: altButton];
  }
  else
  {
    [exitAlternateButton setHidden: YES];
  }

  if (othButton)
  {
    [exitOtherButton setHidden: NO];
    [exitOtherButton setStringValue: othButton];
  }
  else
  {
    [exitOtherButton setHidden: YES];
  }

  modal = YES;
  [NSApp runModalForWindow: exitPanel];

  return exitResponse;
}

/********* Input Panel ************/

- (void) inputCancelButtonAction: (id) sender
{
  modal = NO;
  inputResponse = NSRunAbortedResponse;
  [inputPanel close];
}

- (void) inputOkButtonAction: (id) sender
{
  modal = NO;
  inputResponse = NSRunStoppedResponse;
  [inputPanel close];
}

- (NSString *) inputDialogWithTitle: (NSString *) title
                            message: (NSString *) message
                               text: (NSString *) text
{
  if (inputPanel == nil)
  {
    inputPanel = [[NSPanel alloc] initWithContentRect: NSMakeRect(300, 300, 300, 200)
                                          styleMask: NSTitledWindowMask
		                          backing: NSBackingStoreBuffered
		                          defer: YES];

    NSButton *button;
   
    inputTitle = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 150, 260, 30)];
    [inputTitle setSelectable: NO];
    [inputTitle setBezeled: NO];
    [inputTitle setDrawsBackground: NO];
    [inputTitle setStringValue: title];
    [[inputPanel contentView] addSubview: inputTitle];
    AUTORELEASE(inputTitle);

    inputMessage = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 90, 260, 50)];
    [inputMessage setSelectable: NO];
    [inputMessage setBezeled: NO];
    [inputMessage setDrawsBackground: NO];
    [inputMessage setStringValue: message];
    [[inputPanel contentView] addSubview: inputMessage];
    AUTORELEASE(inputMessage);

    inputField  = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 50, 260, 30)];
    [inputField setEditable: YES];
    [inputField setSelectable: YES];
    [inputField setBezeled: YES];
    [[inputPanel contentView] addSubview: inputField];
    AUTORELEASE(inputField);

    button = [[NSButton alloc] initWithFrame: NSMakeRect(100, 20, 40, 20)];
    [button setStringValue: @"Cancel"];
    [button setTarget: self];
    [button setAction: @selector(inputCancelButtonAction:)];
    [[inputPanel contentView] addSubview: button];
    DESTROY(button);

    button = [[NSButton alloc] initWithFrame: NSMakeRect(150, 20, 40, 20)];
    [button setStringValue: @"OK"];
    [button setTarget: self];
    [button setAction: @selector(inputOkButtonAction:)];
    [[inputPanel contentView] addSubview: button];
    DESTROY(button);

    [inputPanel setDelegate: self];
  }

  /* Prevent running modal again */
  if (modal == YES)
    return nil;

  if (title)
  {
    [inputTitle setHidden: NO];
    [inputTitle setStringValue: title];
  }
  else
  {
    [inputTitle setHidden: YES];
  }

  if (message)
  {
    [inputMessage setHidden: NO];
    [inputMessage setStringValue: message];
  }
  else
  {
    [inputMessage setHidden: YES];
  }

  if (text)
    [inputField setStringValue: text];
  else
    [inputField setStringValue: @""];


  modal = YES;
  [NSApp runModalForWindow: inputPanel];

  switch(inputResponse) {
    case NSRunStoppedResponse:
      {
        NSString *result = [inputField stringValue];
        if (result && [result length])
          return result;
      }
    default:
      return nil;
  }
  return nil;
}

- (void) showInfoPanel: (id) sender
{
  if (infoPanel == nil)
  {
    infoPanel = [[NSPanel alloc] initWithContentRect: NSMakeRect(300, 300, 425, 300)
                                          styleMask: (NSTitledWindowMask |
		                                    NSClosableWindowMask
		                                   )
		                          backing: NSBackingStoreBuffered
		                          defer: YES];
    [infoPanel  setTitle: @"Info"];

    int i;
    NSMutableString *string = AUTORELEASE([[NSMutableString alloc] init]);
    WScreen *scr = NULL;
    int screenNumber = WMCurrentScreen();
    NSLog(@"screenNumber %d", screenNumber);

    /* Visual */
    if (wScreenCount > 0)
    {
      NSArray *visuals = [NSArray arrayWithObjects: 
	    @"StaticGray", @"GrayScale", @"StaticColor", 
	      @"PseudoColor", @"TrueColor", @"DirectColor",
	    nil];
      /* FIXME: don't know how to get WScreen 
       * without assuming 0 as screen number. */
      scr = wScreenWithScreenNumber(screenNumber);
      int index = scr->w_visual->class;
      if (scr && (index < [visuals count]))
      {
	[string appendFormat: @"Using visual 0x%x: %@ %ibpp ", (unsigned)scr->w_visual->visualid, [visuals objectAtIndex: scr->w_visual->class], scr->w_depth];
	switch (scr->w_depth) {
	  case 15:
	    [string appendString: @"32 thousand colors\n"];
	    break;
	  case 16:
	    [string appendString: @"64 thousand colors\n"];
	    break;
	  case 24:
	  case 32:
	    [string appendString: @"16 million colors\n"];
	    break;
	  default:
	    [string appendFormat: @"%d colors\n", 1<<scr->w_depth];
	}
      }
    }

#if defined(HAVE_MALLOC_H) && defined(HAVE_MALLINFO)
    {
      /* Memory usage */
      struct mallinfo ma = mallinfo();
      [string appendFormat: @"Total allocated memory: %i kB.\nTotal memory in use: %i kB.\n", (ma.arena+ma.hblkhd)/1024, (ma.uordblks+ma.hblkhd)/1024];
    }
#endif

    /* image formats */
    [string appendString: @"Supported image format: "];
    char **strl = RSupportedFileFormats();
    for (i = 0; strl[i]!=NULL; i++) {
      [string appendFormat: @"%s ", strl[i]];
    }
    [string appendString: @"\n"];

    /* Additional */
    [string appendString: @"Additional support for:"];
#ifdef NETWM_HINTS
    [string appendString: @" WMSPEC"];
#endif
#ifdef MWM_HINTS
    [string appendString: @" MWM"];
#endif
    [string appendString: @"\n"];

    /* Sound */
    if (wPreferences.no_sound) {
      [string appendString: @"Sound disabled\n"];
    } else {
      [string appendString: @"Sound enabled\n"];
    }

#ifdef VIRTUAL_DESKTOP
    if (wPreferences.vdesk_enable)
      [string appendString: @"VirtualDesktop enabled\n"];
    else
      [string appendString: @"VirtualDesktop disabled\n"];
#endif

    if (scr) {
#ifdef XINERAMA

#ifdef SOLARIS_XINERAMA
      [string appendString: @"Solaris "];
#endif
      [string appendString: @"Xinerama: "];
      {
        [string appendFormat: @"%d heads found.", scr->xine_info.count];
      }
#endif
    }

    NSTextField *field = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 20, 385, 260)];
    [field setSelectable: NO];
    [field setBezeled: NO];
    [field setDrawsBackground: NO];
    [field setStringValue: string];
    [[infoPanel contentView] addSubview: field];
    DESTROY(field);
  }
  [infoPanel makeKeyAndOrderFront: self];
}

- (void) showLegalPanel: (id) sender
{
  if (legalPanel == nil)
  {
    legalPanel = [[NSPanel alloc] initWithContentRect: NSMakeRect(300, 300, 500, 300)
                                          styleMask: (NSTitledWindowMask |
		                                    NSClosableWindowMask
		                                   )
		                          backing: NSBackingStoreBuffered
		                          defer: YES];
    [legalPanel  setTitle: @"legal"];
    NSTextField *field = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 20, 460, 260)];

    [field setSelectable: NO];
    [field setBezeled: YES];
    [field setDrawsBackground: NO];
    [field setStringValue: 
      @"   Window Maker is free software; you can redistribute if and/or\n" \
      @"modify it under the terms of the GNU General Public License as\n" \
      @"published by the Free Software Foundation; either version 2 of the\n" \
      @"License, or (at your option) any later version.\n\n" \
      @"   Window Maker is distributed in the hope that it will be useful,\n" \
      @"but WITHOUT ANY WARRANTY; without even the implied warranty\n" \
      @"of MERCHANTABILIGY of FITNESS FOR A PARTICULAR PURPOSE.\n" \
      @"See the GNU General Public License for more defaults.\n\n" \
      @"   You should have received a copy of the GNU General Public\n" \
      @"License along with this program; if not, write to the Free Software\n" \
      @"Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA\n" \
      @"02111-1307, USA."];
    [[legalPanel contentView] addSubview: field];
    DESTROY(field);
  }
  [legalPanel makeKeyAndOrderFront: self];
}

- (void) showGNUstepPanel: (id) sender
{
  if (aboutGNUstepPanel == nil)
  {
    aboutGNUstepPanel = [[NSPanel alloc] initWithContentRect: NSMakeRect(300, 300, 425, 300)
                                          styleMask: (NSTitledWindowMask |
		                                    NSClosableWindowMask
		                                   )
		                          backing: NSBackingStoreBuffered
		                          defer: YES];
    [aboutGNUstepPanel  setTitle: @"About GNUstep"];
    NSTextField *field = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 260, 180, 30)];
    [field setSelectable: NO];
    [field setBezeled: NO];
    [field setDrawsBackground: NO];
    [field setStringValue: @"GNUstep"];
    [[aboutGNUstepPanel contentView] addSubview: field];
    DESTROY(field);

    field = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 20, 385, 220)];
    [field setSelectable: NO];
    [field setBezeled: NO];
    [field setDrawsBackground: NO];
    [field setStringValue: @"Window Maker is part of the GNUstep project.\n" \
	    		@"The GNUstep project aims to create a free\n" \
			@"implementation of the OpenStep(tm) specification\n" \
			@"which is a object-oriented framework for\n" \
			@"creating advanced graphical, multi-platform\n" \
			@"applications. Additionally, a development and\n" \
			@"user desktop environment will be created on top\n" \
			@"of the framework. For more information about\n" \
			@"GNUstep, please visit: www.gnustep.org"
			];
    [[aboutGNUstepPanel contentView] addSubview: field];
    DESTROY(field);
  }
  [aboutGNUstepPanel makeKeyAndOrderFront: self];
}

- (id) init
{
  self = [super init];

  modal = NO;

  return self;
}

@end

