/*
   ToolsPane.m
   The tools inspector.

   Copyright (C) 2005 Saso Kiselkov
                 2007 Yen-Ju Chen

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright notice, 
     this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright notice, 
     this list of conditions and the following disclaimer in the documentation 
     and/or other materials provided with the distribution.
   * Neither the name of the Etoile project nor the names of its contributors 
     may be used to endorse or promote products derived from this software 
     without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
   THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <AppKit/AppKit.h>
#include "ToolsPane.h"

static inline void AddAppToMatrix(NSString *appName, NSMatrix *matrix)
{
  NSButtonCell * cell;
  NSWorkspace * ws = [NSWorkspace sharedWorkspace];

  [matrix addColumn];
  cell = [matrix cellAtRow: 0 column: [matrix numberOfColumns] - 1];
  [cell setTitle: appName];
  [cell setImage: [ws iconForFile: [ws fullPathForApplication: appName]]];
}

@implementation ToolsPane
/* Private */
- (void) clearDisplay
{
  while ([matrix numberOfColumns])
    [matrix removeColumn: 0];

  [appPath setStringValue: nil];
  [defaultApp setStringValue: nil];

  [setDefaultButton setEnabled: NO];
  [revertButton setEnabled: NO];
}

- (void) buildUI: (NSView *) view 
{
  NSScrollView *scrollView = nil;
  NSTextField *textField = nil;
  NSRect frame = [view frame];
  NSRect rect = NSZeroRect, scrollFrame = NSZeroRect;
  int y = 0;

  /* Application list */
  rect.size = NSMakeSize(frame.size.width-5*2, 72);
  scrollFrame.size = [NSScrollView frameSizeForContentSize: rect.size
                                   hasHorizontalScroller: YES
                                   hasVerticalScroller: NO
                                   borderType: NSLineBorder];
  scrollFrame.origin.x = 5;
  scrollFrame.origin.y = frame.size.height-5-scrollFrame.size.height;

  matrix = [[NSMatrix alloc] initWithFrame: rect];
  NSButtonCell *cell = AUTORELEASE([[NSButtonCell alloc] init]);
  [cell setImagePosition: NSImageAbove];
  [cell setFont: [NSFont userFontOfSize: 10]];
  [cell setButtonType: NSPushOnPushOffButton];
  [matrix setPrototype: cell];
  [matrix setCellSize: NSMakeSize(72, 72)];
  [matrix setTarget: self];
  [matrix setDoubleAction: @selector(openWithApp:)];
  [matrix setAction: @selector(appSelected:)];
  [matrix setAutoscroll: YES];
  [matrix setIntercellSpacing: NSZeroSize];

  scrollView = [[NSScrollView alloc] initWithFrame: scrollFrame];
  [scrollView setHasVerticalScroller: NO];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setDocumentView: matrix];
  [view addSubview: scrollView];
  RELEASE(matrix);
  DESTROY(scrollView);
  
  /* Default */
  rect = NSMakeRect(5, NSMinY(scrollFrame)-5-30, 50, 30);
  textField = [[NSTextField alloc] initWithFrame: rect];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setStringValue: _(@"Default:")];
  [textField setDrawsBackground: NO];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [textField setAlignment: NSRightTextAlignment];
  [view addSubview: textField];
  DESTROY(textField);

  rect = NSMakeRect(NSMaxX(rect)+5, NSMinY(rect), 
                    frame.size.width-NSMaxX(rect)-5*2, 30);
  defaultApp = [[NSTextField alloc] initWithFrame: rect];
  [defaultApp setEditable: NO];
  [defaultApp setSelectable: NO];
  [defaultApp setDrawsBackground: NO];
  [defaultApp setBordered: NO];
  [defaultApp setBezeled: NO];
  [view addSubview: defaultApp];
  RELEASE(defaultApp);

  /* Path */
  rect = NSMakeRect(5, NSMinY(rect)-5-30, 50, 30);
  textField = [[NSTextField alloc] initWithFrame: rect];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setStringValue: _(@"Path:")];
  [textField setDrawsBackground: NO];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [textField setAlignment: NSRightTextAlignment];
  [view addSubview: textField];
  DESTROY(textField);

  rect = NSMakeRect(NSMaxX(rect)+5, NSMinY(rect), 
                    frame.size.width-NSMaxX(rect)-5*2, 30);
  appPath = [[NSTextField alloc] initWithFrame: rect];
  [appPath setEditable: NO];
  [appPath setSelectable: NO];
  [appPath setDrawsBackground: NO];
  [appPath setBordered: NO];
  [appPath setBezeled: NO];
  [view addSubview: appPath];
  RELEASE(appPath);

  /* text */
  rect = NSMakeRect(5, NSMinY(rect)-5-50, frame.size.width-2*5, 50);
  text = [[NSTextView alloc] initWithFrame: rect];
  [text setEditable: NO];
  [text setFont: [NSFont userFontOfSize: 11]];
  [text setString: _(@"Click `Set Default' to set default "
          @"application for all documents with this extension.")];
  [view addSubview: text];
  RELEASE(text);

  /* Revert & Set default*/
  rect = NSMakeRect(NSWidth(frame)-100-5, 5, 100, 30);
  setDefaultButton = [[NSButton alloc] initWithFrame: rect];
  [setDefaultButton setTitle: _(@"Set Default")];
  [setDefaultButton setTarget: self];
  [setDefaultButton setAction: @selector(setDefault:)];
  [view addSubview: setDefaultButton];
  RELEASE(setDefaultButton);

  rect = NSMakeRect(NSMinX(rect)-100-5, 5, 100, 30);
  revertButton = [[NSButton alloc] initWithFrame: rect];
  [revertButton setTitle: _(@"Revert")];
  [revertButton setTarget: self];
  [revertButton setAction: @selector(revert:)];
  [view addSubview: revertButton];
  RELEASE(revertButton);
}

/* End of private */

+ (NSArray *) extensions
{
  return nil;
}

- (NSDictionary *) pluginInfo
{
  return info;
}

- (id) init
{
  self = [super init];

  _mainView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, INSPECTOR_WIDTH, 300)];
  [self buildUI: _mainView];

  info = [[NSDictionary alloc] initWithObjectsAndKeys:
        @"ToolsPane", @"identifier",
        @"Tools", @"name",
        @"ToolsPane", @"path",
        [NSValue valueWithPointer: [self class]], @"class",
        self, @"instance", nil];

  return self;
}

- (void) dealloc
{
  DESTROY(path);
  DESTROY(info);
  [super dealloc];
}

- (void) setPath: (NSString *) aPath
{
  NSString * defaultAppName;
  NSString * extension;
  NSWorkspace * ws = [NSWorkspace sharedWorkspace];
  NSString * defaultEditor = [[[NSUserDefaults standardUserDefaults]
          objectForKey: @"DefaultEditor"] stringByDeletingPathExtension];
  NSString * fileType;

  ASSIGN(path, aPath);
  extension = [path pathExtension];

  [self clearDisplay];

  if (![[NSFileManager defaultManager] fileExistsAtPath: path]) 
  {
    return;
  }


  [ws getInfoForFile: aPath application: &defaultAppName type: &fileType];


  if (defaultAppName != nil || (defaultEditor != nil &&
      ([fileType isEqualToString: NSPlainFileType] ||
      [fileType isEqualToString: NSShellCommandFileType]))) 
  {
    NSEnumerator * e;
    NSString * appName;
    NSButtonCell * cell;
    NSDictionary * extInfo;
    BOOL seenDefaultEditor = NO;

    if (defaultAppName == nil) 
    {
      defaultAppName = defaultEditor;
      seenDefaultEditor = YES;
    } 
    else 
    {
      defaultAppName = [defaultAppName stringByDeletingPathExtension];

      if ([defaultAppName isEqualToString: defaultEditor])
        seenDefaultEditor = YES;
    }

    AddAppToMatrix(defaultAppName, matrix);
    [defaultApp setStringValue: defaultAppName];

    extInfo = [ws infoForExtension: extension];
    e = [[[extInfo allKeys] sortedArrayUsingSelector:
                  @selector(caseInsensitiveCompare:)] objectEnumerator];
    while ((appName = [e nextObject]) != nil) 
    {
      appName = [appName stringByDeletingPathExtension];

      if ([appName isEqualToString: defaultAppName])
	continue;
      if ([appName isEqualToString: defaultEditor])
        seenDefaultEditor = YES;

      AddAppToMatrix(appName, matrix);
    }

    if (seenDefaultEditor == NO && defaultEditor != nil)
      AddAppToMatrix(defaultEditor, matrix);

    [self appSelected: matrix];
  } 
  else 
  {
    [defaultApp setStringValue: nil];
    [appPath setStringValue: nil];
  }

  [matrix sizeToCells];

  [setDefaultButton setEnabled: NO];
  [revertButton setEnabled: NO];
}

- (void) appSelected: (id) sender
{
  [appPath setStringValue: [[NSWorkspace sharedWorkspace]
          fullPathForApplication: [[sender selectedCell] title]]];
  [setDefaultButton setEnabled: YES];
  [revertButton setEnabled: YES];
}

- (void) openWithApp: (id) sender
{
  [[NSWorkspace sharedWorkspace]
          openFile: path withApplication: [[sender selectedCell] title]];
}

- (void) setDefault: (id) sender
{
  NSButtonCell *selected, *first;
  NSString * title = nil;
  NSWorkspace * ws;

  if ([matrix numberOfColumns] == 0)
    return;

  ws = [NSWorkspace sharedWorkspace];

  selected = [matrix selectedCell];
  first = [matrix cellAtRow: 0 column: 0];

  [ws setBestApp: [selected title] inRole: nil
                             forExtension: [path pathExtension]];

  // exchange the icons in the matrix
  ASSIGN(title, [selected title]);
  [selected setTitle: [first title]];
  [first setTitle: title];
  DESTROY(title);

  [first setImage: [ws iconForFile: [ws fullPathForApplication:
	[first title]]]];
  [selected setImage: [ws iconForFile: [ws fullPathForApplication:
	[selected title]]]];
  [matrix selectCellAtRow: 0 column: 0];
  [self appSelected: matrix];

  [setDefaultButton setEnabled: NO];
  [revertButton setEnabled: NO];
}

- (void) revert: (id) sender
{
  [matrix selectCellAtRow: 0 column: 0];
  [self appSelected: matrix];
  [setDefaultButton setEnabled: NO];
  [revertButton setEnabled: NO];
}

@end
