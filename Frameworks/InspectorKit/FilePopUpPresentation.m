#import "FilePopUpPresentation.h"
#import <IconKit/IconKit.h>

const NSString *FilePopUpPresentationMode = @"FilePopUpPresentationMode";

#define BUTTON_HEIGHT 25 
#define PAD 5
/* Space to have file icon and name displayed */
#define FILE_SPACE 64 

@implementation FilePopUpButtonPresentation

+ (void) load
{
  [PKPresentationBuilder inject: self forKey: FilePopUpPresentationMode];
}

- (NSString *) presentationMode
{
  return (NSString *)FilePopUpPresentationMode;
}

- (id) init
{
  self = [super init];

  iconView = [[NSImageView alloc] initWithFrame: NSZeroRect];
  nameField = [[NSTextField alloc] initWithFrame: NSZeroRect];
  [nameField setEditable: NO];
  [nameField setSelectable: NO];
  [nameField setDrawsBackground: NO];
  [nameField setBordered: NO];
  [nameField setBezeled: NO];

  pathField = [[NSTextField alloc] initWithFrame: NSZeroRect];
  [pathField setEditable: NO];
  [pathField setSelectable: NO];
  [pathField setDrawsBackground: NO];
  [pathField setBordered: NO];
  [pathField setBezeled: NO];

  return self;
}

- (void) loadUI
{
  NSView *mainViewContainer = [controller view];

  [mainViewContainer addSubview: iconView];
  [mainViewContainer addSubview: nameField];
  [mainViewContainer addSubview: pathField];

  [super loadUI];
}

- (void) unloadUI
{
  [super unloadUI];
  [iconView removeFromSuperview];
  [nameField removeFromSuperview];
  [pathField removeFromSuperview];
}

/* It is too complicated to call super because each presentation has
   different architecture. So we need to add paneView ourselves.
   And over-use -setFrame causes view to flick. */
- (void) layoutPreferencesViewWithPaneView: (NSView *)paneView
{
  if (paneView == nil)
    return;

  NSView *mainView = [controller view];
  NSRect paneFrame = [paneView frame];
  NSRect popUpFrame = [popUpButton frame];
  NSRect windowFrame = [[mainView window] frame];
  NSRect contentFrame = NSZeroRect;
  int previousHeight = windowFrame.size.height;
  int heightDelta;

  /* Resize window so content area is large enough for prefs. */
    
  popUpFrame.size.width = paneFrame.size.width-2*PAD;
  paneFrame.origin.x = 0;
  paneFrame.origin.y = 0;
  
  contentFrame.size.width = windowFrame.size.width;
  contentFrame.size.height = 2*PAD+BUTTON_HEIGHT+FILE_SPACE+paneFrame.size.height;
   
  // FIXME: Implement -frameRectForContentRect: in GNUstep 
  windowFrame.size = [NSWindow frameRectForContentRect: contentFrame
      styleMask: [[mainView window] styleMask]].size;
    
  // NOTE: We have to check carefully the view is not undersized to avoid
  // limiting switch possibilities in listed panes.
  if (windowFrame.size.height < 100)
      windowFrame.size.height = 100;
  if (windowFrame.size.width < 100)
      windowFrame.size.width = 100;
    
  /* We take in account the fact the origin is located at bottom left corner. */
  heightDelta = previousHeight - windowFrame.size.height;
  windowFrame.origin.y += heightDelta;
    
  // FIXME: Animated resizing is buggy on GNUstep (exception thrown about
  // periodic events already generated for the current thread)
  #ifndef GNUSTEP
    [[mainView window] setFrame: windowFrame display: YES animate: YES];
  #else
    [[mainView window] setFrame: windowFrame display: YES animate: NO];
  #endif

  /* Do not resize table view because it is autoresizable.
   * Resize paneView before adding it into window to reduce flick.
   * It is also the reason that adding it after window is resized.
   */
  [paneView setFrame: paneFrame];
  if ([[paneView superview] isEqual: mainView] == NO)
    [mainView addSubview: paneView];
  NSRect rect = NSMakeRect(5, NSMaxY(paneFrame)+PAD, 48, 48);
  [iconView setFrame: rect];
  rect = NSMakeRect(NSMaxX(rect)+5, NSMaxY(paneFrame)+PAD+24, 
                    NSWidth(paneFrame)-2*PAD-NSMaxX(rect), 24);
  [nameField setFrame: rect];
  rect.origin.y -= 24;
  [pathField setFrame: rect];
}

- (void) setFilePath: (NSString *) p
{
  ASSIGN(path, p);

  if (path)
  {
    [iconView setImage: [[IKIcon iconForFile: path] image]];
    [nameField setStringValue: [path lastPathComponent]];
    [pathField setStringValue: path];
  }
}

- (NSString *) filePath
{
  return path;
}

- (void) dealloc
{
  DESTROY(path);
  DESTROY(iconView);
  DESTROY(nameField);
  DESTROY(pathField);
  [super dealloc];
}

@end
