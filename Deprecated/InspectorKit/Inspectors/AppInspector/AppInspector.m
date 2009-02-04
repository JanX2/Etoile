/*
   The app inspector.

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

#import "AppInspector.h"

@interface AppInspector (Private)

- (void) parseTypeEntry: (NSDictionary *) entry
               inBundle: (NSBundle *) bundle
          fillingMatrix: (NSMatrix *) matrix;

@end

@implementation AppInspector (Private)

- (void) parseTypeEntry: (NSDictionary *) entry
               inBundle: (NSBundle *) bundle
          fillingMatrix: (NSMatrix *) matrix
{
        NSArray * extensions;
        NSString * nsIcon;
        NSString * iconPath;
        NSImage * icon;
        NSString * ext;
        NSCell * cell;

        if ((nsIcon = [entry objectForKey: @"NSIcon"]) != nil &&
            [nsIcon isKindOfClass: [NSString class]] &&
            (iconPath = [bundle pathForResource: [nsIcon
          stringByDeletingPathExtension] ofType: [nsIcon pathExtension]])
          != nil) {
                icon = [[[NSImage alloc]
                  initByReferencingFile: iconPath]
                  autorelease];
        } else
                icon = nil;

        if ((extensions = [entry objectForKey: @"NSUnixExtensions"]) != nil &&
            [extensions isKindOfClass: [NSArray class]] &&
            [extensions count] > 0) {
                if (![(ext = [extensions objectAtIndex: 0]) isKindOfClass:
                  [NSString class]])
                        ext = nil;
        } else
                ext = nil;

        [matrix addColumn];
        cell = [matrix cellAtRow: 0 column: [matrix numberOfColumns] - 1];
        [cell setTitle: ext];
        [cell setImage: icon];
}

@end

@implementation AppInspector

static NSArray * exts = nil;

+ (NSArray *) extensions
{
        if (exts == nil)
                ASSIGN(exts, [NSArray arrayWithObject: NSApplicationFileType]);

        return exts;
}

- (NSString *) inspectorName
{
        return _(@"App Inspector");
}



- (void) dealloc
{
        TEST_RELEASE(view);
        TEST_RELEASE(path);

        [super dealloc];
}

- init
{
        [super init];

        [NSBundle loadNibNamed: @"AppInspector" owner: self];

        return self;
}

- (void) awakeFromNib
{
        [view retain];
        [view removeFromSuperview];
        [normalBox retain];
        [invalidBox retain];
        [invalidBox removeFromSuperview];

        [[sv horizontalScroller] setArrowsPosition: NSScrollerArrowsNone];

        DESTROY(bogusWindow);
}

- (void) displayForPath: (NSString *) aPath
{
        NSBundle * bundle;
        NSArray * types;
        NSDictionary * infoPlist;
        NSString * infoPlistPath;
        NSArray * nsTypes;
        NSMatrix * matrix;
        NSButtonCell * proto;
        NSDictionary * nsExtensions;

	ASSIGN(path, aPath);

        bundle = [NSBundle bundleWithPath: path];
        if (bundle == nil) {
                [view setContentView: invalidBox];
                return;
        }
        if ((infoPlistPath = [bundle pathForResource: @"Info-gnustep"
                                              ofType: @"plist"]) == nil &&
            (infoPlistPath = [bundle pathForResource: @"Info"
                                              ofType: @"plist"]) == nil) {
                [view setContentView: invalidBox];
                return;
        }
        if ((infoPlist = [NSDictionary dictionaryWithContentsOfFile:
          infoPlistPath]) == nil) {
                [view setContentView: invalidBox];
                return;
        }

        matrix = [[[NSMatrix alloc]
          initWithFrame: NSMakeRect(0, 0, 0, 72)]
          autorelease];
        proto = [[NSButtonCell new] autorelease];
        [proto setImagePosition: NSImageAbove];
        [proto setFont: [NSFont systemFontOfSize: 11]];

        [matrix setAutoscroll: YES];
        [matrix setCellSize: NSMakeSize(72, 72)];
        [matrix setIntercellSpacing: NSZeroSize];
        [matrix setPrototype: proto];

        if ((nsTypes = [infoPlist objectForKey: @"NSTypes"]) != nil &&
            [nsTypes isKindOfClass: [NSArray class]]) {
                NSEnumerator * e = [nsTypes objectEnumerator];
                NSDictionary * typeEntry;

                while ((typeEntry = [e nextObject]) != nil) {
                        if (![typeEntry isKindOfClass: [NSDictionary class]])
                                continue;

                        [self parseTypeEntry: typeEntry
                                    inBundle: bundle
                               fillingMatrix: matrix];
                }

                [matrix sizeToCells];
        }
        if ((nsExtensions = [infoPlist objectForKey: @"NSExtensions"]) != nil &&
            [nsExtensions isKindOfClass: [NSDictionary class]]) {
                NSEnumerator * e;
                NSString * ext;

                e = [[nsExtensions allKeys] objectEnumerator];
                while ((ext = [e nextObject]) != nil) {
                        NSDictionary * entry;
                        NSCell * cell;
                        NSImage * icon;
                        NSString * iconPath;

                        entry = [nsExtensions objectForKey: ext];
                        if (![ext isKindOfClass: [NSString class]] ||
                            ![entry isKindOfClass: [NSDictionary class]])
                                continue;

                        if ((iconPath = [entry objectForKey: @"NSIcon"]) != nil &&
                            [iconPath isKindOfClass: [NSString class]] &&
                            (iconPath = [bundle pathForResource: [iconPath
                            stringByDeletingPathExtension] ofType:
                            [iconPath pathExtension]]) != nil)
                                icon = [[[NSImage alloc]
                                  initByReferencingFile: iconPath]
                                  autorelease];
                        else
                                icon = nil;

                        [matrix addColumn];
                        cell = [matrix cellAtRow: 0 column: [matrix
                          numberOfColumns] - 1];
                        [cell setTitle: ext];
                        [cell setImage: icon];
                }

                [matrix sizeToCells];
        }

        [sv setDocumentView: matrix];
        [view setContentView: normalBox];
}

- (void) launch: (id)sender
{
        [[NSWorkspace sharedWorkspace] launchApplication: path];
}

- (NSView *) view
{
        return view;
}

@end
