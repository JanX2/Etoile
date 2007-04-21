/*
   ToolsInspector.m
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
#include "ToolsInspector.h"

static inline void AddAppToMatrix(NSString * appName, NSMatrix * matrix)
{
        NSButtonCell * cell;
        NSWorkspace * ws = [NSWorkspace sharedWorkspace];

        [matrix addColumn];
        cell = [matrix cellAtRow: 0 column: [matrix numberOfColumns] - 1];
        [cell setTitle: appName];
        [cell setImage: [ws iconForFile: [ws fullPathForApplication: appName]]];
}

@interface ToolsInspector (Private)

- (void) clearDisplay;

@end

@implementation ToolsInspector (Private)

- (void) clearDisplay
{
        [appList setDocumentView: nil];
        [appPath setStringValue: nil];
        [defaultApp setStringValue: nil];

        [setDefaultButton setEnabled: NO];
        [revertButton setEnabled: NO];
}

@end

@implementation ToolsInspector

+ (NSArray *) extensions
{
        return nil;
}

- (void) dealloc
{
        NSDebugLLog(@"ToolsInspector", @"ToolsInspector: dealloc");

        TEST_RELEASE(view);
        TEST_RELEASE(path);

        [super dealloc];
}

- (void) awakeFromNib
{
        NSRange r;

        [[appList horizontalScroller]
          setArrowsPosition: NSScrollerArrowsNone];

        [view retain];
        [view removeFromSuperview];
        DESTROY(bogusWindow);

        [textSv setHasVerticalScroller: NO];
        [text setFont: [NSFont userFontOfSize: 11]];
        [text setString: _(@"Click `Set Default' to set default "
          @"application for all documents with this extension.")];
        r = NSMakeRange(0, [[text string] length]);
        [text setAlignment: NSCenterTextAlignment range: r];
        [text setColor: [NSColor darkGrayColor] ofRange: r];
}

- (NSString *) inspectorName
{
        return _(@"Tools Inspector");
}

- (void) displayForPath: (NSString *) aPath
{
        NSMatrix * matrix;
        NSButtonCell * cell = [[NSButtonCell new] autorelease];
        NSString * defaultAppName;
        NSString * extension;
        NSWorkspace * ws = [NSWorkspace sharedWorkspace];
        NSString * defaultEditor = [[[NSUserDefaults standardUserDefaults]
          objectForKey: @"DefaultEditor"] stringByDeletingPathExtension];
        NSString * fileType;

        ASSIGN(path, aPath);
        extension = [path pathExtension];

        if (![[NSFileManager defaultManager]
          fileExistsAtPath: path]) {
                [self clearDisplay];
                return;
        }

        matrix = [[[NSMatrix alloc]
          initWithFrame: NSMakeRect(0, 0, 72, 72)]
          autorelease];

        [ws getInfoForFile: aPath
               application: &defaultAppName
                      type: &fileType];

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

        if (defaultAppName != nil || (defaultEditor != nil &&
          ([fileType isEqualToString: NSPlainFileType] ||
           [fileType isEqualToString: NSShellCommandFileType]))) {
                NSEnumerator * e;
                NSString * appName;
                NSButtonCell * cell;
                NSDictionary * extInfo;
                BOOL seenDefaultEditor = NO;

                if (defaultAppName == nil) {
                        defaultAppName = defaultEditor;
                        seenDefaultEditor = YES;
                } else {
                        defaultAppName = [defaultAppName
                          stringByDeletingPathExtension];

                        if ([defaultAppName isEqualToString: defaultEditor])
                                seenDefaultEditor = YES;
                }

                AddAppToMatrix(defaultAppName, matrix);
                [defaultApp setStringValue: defaultAppName];

                extInfo = [ws infoForExtension: extension];
                e = [[[extInfo allKeys] sortedArrayUsingSelector:
                  @selector(caseInsensitiveCompare:)] objectEnumerator];
                while ((appName = [e nextObject]) != nil) {
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
        } else {
                [defaultApp setStringValue: nil];
                [appPath setStringValue: nil];
        }

        [matrix sizeToCells];
        [appList setDocumentView: matrix];

        [setDefaultButton setEnabled: NO];
        [revertButton setEnabled: NO];
}

- (NSView *) view
{
        return view;
}

- (void) appSelected: sender
{
        [appPath setStringValue: [[NSWorkspace sharedWorkspace]
          fullPathForApplication: [[sender selectedCell] title]]];
        [setDefaultButton setEnabled: YES];
        [revertButton setEnabled: YES];
}

- (void) openWithApp: sender
{
        [[NSWorkspace sharedWorkspace]
          openFile: path withApplication: [[sender selectedCell] title]];
}

- (void) setDefault: sender
{
        NSMatrix * matrix = [appList documentView];
        NSButtonCell * selected, * first;
        NSString * title = nil;
        NSWorkspace * ws;

        if ([matrix numberOfColumns] == 0)
                return;

        ws = [NSWorkspace sharedWorkspace];

        selected = [matrix selectedCell];
        first = [matrix cellAtRow: 0 column: 0];

        [ws setBestApp: [selected title]
                inRole: nil
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

- (void) revert: sender
{
        [[appList documentView] selectCellAtRow: 0 column: 0];
        [self appSelected: [appList documentView]];
        [setDefaultButton setEnabled: NO];
        [revertButton setEnabled: NO];
}

@end
