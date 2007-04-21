/*
   Inspector.m
   The workspace manager's inspector.

   This file is part of OpenSpace.

   Copyright (C) 2005 Saso Kiselkov

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import "Inspector.h"

#import "InspectorModule.h"

#import <OpenSpace/OpenSpace.h>
#import <IconKit/IconKit.h>

@interface Inspector (Private)

- (void) updateDisplay;

- (void) setInspector: inspector;

- (id <InspectorModule>) contentsInspectorForFile: (NSString *) filename;

@end

@implementation Inspector (Private)

- (void) updateDisplay
{
        if (filePath != nil) {
                id <InspectorModule> mod;

                [icon setImage: [[IKIcon iconForFile: filePath] image]];
                [filename setStringValue: [filePath lastPathComponent]];
                [path setStringValue: filePath];

                if ([popUpButton indexOfSelectedItem] != 1) {
                        [self setInspector: currentInspector];
/*                        [box setContentView: [currentInspector view]];
                        [currentInspector displayForPath: filePath];*/
                } else {
                        [self setInspector: [self
                          contentsInspectorForFile: filePath]];
                }
        } else {
                [icon setImage: nil];
                [filename setStringValue: nil];
                [path setStringValue: nil];
                if (multipleSelectionView == nil) {
                        [NSBundle loadNibNamed: @"MultipleSelectionInspectorView"
                                         owner: self];

                        [multipleSelectionView retain];
                        [multipleSelectionView removeFromSuperview];
                        DESTROY(multipleSelectionViewBogusWindow);
                }
                [box setContentView: multipleSelectionView];
                [panel setTitle: _(@"Inspector")];
        }
}

- (void) setInspector: inspector
{
        if (filePath != nil) {
                [box setContentView: [inspector view]];
                [panel setTitle: [inspector inspectorName]];
                [inspector displayForPath: filePath];
        }


        ASSIGN(currentInspector, inspector);
}

- (id <InspectorModule>) contentsInspectorForFile: (NSString *) file
{
        NSEnumerator * e;
        id object;
        NSString * ext;
        NSString * app;
        NSString * fileType;

        if (noContents == nil)
                [NSBundle loadNibNamed: @"NoContentsInspector" owner: self];

        if ([[NSWorkspace sharedWorkspace]
          getInfoForFile: file
             application: &app
                    type: &fileType] == NO)
                return noContents;

        ext = [[file pathExtension] lowercaseString];

        if (contentsInspectors == nil)
                contentsInspectors = [[[OSBundleExtensionLoader shared]
                  extensionsForBundleType: @"inspector"
                   principalClassProtocol: @protocol(InspectorModule)
                       bundleSubdirectory: @"Workspace"
                                inDomains: 0
                     domainDetectionByKey: @"Inspectors"]
                  mutableCopy];

        e = [contentsInspectors objectEnumerator];
        while ((object = [e nextObject]) != nil) {
                Class cls;

                if ([object isKindOfClass: [NSBundle class]])
                        cls = [object principalClass];
                else
                        cls = [object class];

                if ([[cls extensions] containsObject: ext] ||
                    [[cls extensions] containsObject: fileType]) {
                        if ([object isKindOfClass: [NSBundle class]]) {
                                unsigned i = [contentsInspectors
                                  indexOfObject: object];

                                [contentsInspectors
                                  replaceObjectAtIndex: i
                                        withObject: [[cls new] autorelease]];
                                object = [contentsInspectors objectAtIndex: i];
                        }

                        return object;
                }
        }

        return noContents;
}

@end

@implementation Inspector

static Inspector * shared = nil;

+ shared
{
        if (shared == nil)
                shared = [self new];
        return shared;
}

- (void) dealloc
{
        NSDebugLLog(@"Inspector", @"Inspector: dealloc");

        TEST_RELEASE(filePath);

        TEST_RELEASE(attrs);
        TEST_RELEASE(tools);
        TEST_RELEASE(perms);

        TEST_RELEASE(contentsInspectors);
        TEST_RELEASE(multipleSelectionView);

        [super dealloc];
}

- init
{
        [super init];

        [[NSNotificationCenter defaultCenter]
          addObserver: self
             selector: @selector(release)
                 name: NSApplicationWillTerminateNotification
               object: NSApp];

        return self;
}

- (void) activate
{
        if (panel == nil)
                [NSBundle loadNibNamed: @"Inspector" owner: self];

        [self updateDisplay];
         // don't make our panel the key window - we want to allow
         // the user to open the inspector a continue on browsing
         // the file system.
        [panel orderFront: nil];
}

- (void) awakeFromNib
{
        [panel setFrameAutosaveName: @"Inspector"];
}

- (void) displayPath: (NSString *) aPath
{
        if ([filePath isEqualToString: aPath])
                return;

        ASSIGN(filePath, aPath);

        if (panel && [panel isVisible])
                [self updateDisplay];
}


- (void) selectView: (id)sender
{
        switch ([popUpButton indexOfSelectedItem]) {
             // attributes
            case 0:
                if (attrs == nil)
                        [NSBundle loadNibNamed: @"AttributesInspector"
                                         owner: self];
                [self setInspector: attrs];
            break;
             // contents
            case 1:
                [self setInspector: [self contentsInspectorForFile: filePath]];
            break;
             // tools
            case 2:
                if (tools == nil)
                        [NSBundle loadNibNamed: @"ToolsInspector"
                                         owner: self];
                [self setInspector: tools];
            break;
             // permissions
            case 3:
                if (perms == nil)
                        [NSBundle loadNibNamed: @"PermissionsInspector"
                                         owner: self];
                [self setInspector: perms];
            break;
        }
}

- (void) showAttributesInspector: sender
{
        [self activate];
        [popUpButton selectItemAtIndex: 0];
        [self selectView: popUpButton];
}

- (void) showContentsInspector: sender
{
        [self activate];
        [popUpButton selectItemAtIndex: 1];
        [self selectView: popUpButton];
}

- (void) showToolsInspector: sender
{
        [self activate];
        [popUpButton selectItemAtIndex: 2];
        [self selectView: popUpButton];
}

- (void) showPermissionsInspector: sender
{
        [self activate];
        [popUpButton selectItemAtIndex: 3];
        [self selectView: popUpButton];
}

@end
