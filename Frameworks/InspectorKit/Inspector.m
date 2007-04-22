/*
   Inspector.m
   The workspace manager's inspector.

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

#import "Inspector.h"
#import "InspectorModule.h"
#import <EtoileFoundation/OSBundleExtensionLoader.h>
#import <IconKit/IconKit.h>
#import "AttributesPane.h"
#import "FilePopUpPresentation.h"

@interface Inspector (Private)

- (void) updateDisplay;
#if 0
- (void) setInspector: inspector;
- (id <InspectorModule>) contentsInspectorForFile: (NSString *) filename;
#endif

@end

@implementation Inspector (Private)
- (void) updateDisplay
{
  if (filePath != nil) 
  {
    NSArray *array = [[self registry] loadedPlugins];
    int i = 0; 
    for (i = 0; i < [array count]; i++)
    {
      id <InspectorModule> module = [[array objectAtIndex: i] objectForKey: @"instance"];
      [module setPath: filePath];
    }
    if ([presentation isKindOfClass: [FilePopUpButtonPresentation class]])
    {
      [(FilePopUpButtonPresentation *)presentation setFilePath: filePath];
    }
     
#if 0
     id <InspectorModule> mod;

     [icon setImage: [[IKIcon iconForFile: filePath] image]];
     [filename setStringValue: [filePath lastPathComponent]];
     [path setStringValue: filePath];

     if ([popUpButton indexOfSelectedItem] != 1) 
     {
       [self setInspector: currentInspector];
     } 
     else 
     {
       [self setInspector: [self contentsInspectorForFile: filePath]];
     }
#endif
  } 
  else 
  {
#if 0
     [icon setImage: nil];
     [filename setStringValue: nil];
     [path setStringValue: nil];
     if (multipleSelectionView == nil) 
     {
       [NSBundle loadNibNamed: @"MultipleSelectionInspectorView" owner: self];
       [multipleSelectionView retain];
       [multipleSelectionView removeFromSuperview];
       DESTROY(multipleSelectionViewBogusWindow);
     }
     [box setContentView: multipleSelectionView];
     [panel setTitle: _(@"Inspector")];
#endif
  }
}

#if 0
- (void) setInspector: inspector
{
        if (filePath != nil) {
                [box setContentView: [inspector view]];
                [panel setTitle: [inspector inspectorName]];
                [inspector displayForPath: filePath];
        }


        ASSIGN(currentInspector, inspector);
}
#endif

#if 0
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
                contentsInspectors = [[[OSBundleExtensionLoader sharedLoader]
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
#endif

@end

@implementation Inspector

static Inspector * shared = nil;

+ (Inspector *) sharedInspector
{
  if (shared == nil)
  {
    PKPaneRegistry *registry = [[PKPaneRegistry alloc] init];
    [registry addPlugin: AUTORELEASE([[[AttributesPane alloc] init] pluginInfo])];
    
    shared = [[Inspector alloc] 
                initWithRegistry: AUTORELEASE(registry)
                presentationMode: FilePopUpPresentationMode
                           owner: nil];
  }
  return shared;
}

- (void) dealloc
{
  DESTROY(filePath);
  [super dealloc];
}

- (id) init
{
  self = [super init];

  return self;
}

- (void) activate
{
  [self updateDisplay];

  /* don't make our panel the key window - we want to allow
     the user to open the inspector a continue on browsing the file system.
   */
  [[self owner] orderFront: nil]; 
}

#if 0
- (void) awakeFromNib
{
  [panel setFrameAutosaveName: @"Inspector"];
}
#endif

- (void) displayPath: (NSString *) aPath
{
  if ([filePath isEqualToString: aPath])
    return;

  ASSIGN(filePath, aPath);

  if ([self owner] && [[self owner] isKindOfClass: [NSWindow class]] && 
      [[self owner] isVisible])
    [self updateDisplay];
}

- (void) showAttributesInspector: (id) sender
{
  [self activate];
}

- (void) showContentsInspector: (id) sender
{
  [self activate];
}

- (void) showToolsInspector: (id) sender
{
  [self activate];
}

- (void) showPermissionsInspector: (id) sender
{
  [self activate];
}

@end
