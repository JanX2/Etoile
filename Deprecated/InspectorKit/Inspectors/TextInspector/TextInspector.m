/*
   The text/RTF inspector.

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

#import <AppKit/AppKit.h>
#import "TextInspector.h"

@implementation TextInspector

static NSArray * exts = nil;

+ (NSArray *) extensions
{
        if (exts == nil)
                ASSIGN(exts, ([NSArray arrayWithObjects:
                  @"rtf", @"rtfd", @"txt", @"text", nil]));

        return exts;
}

- (NSString *) inspectorName
{
        return _(@"Text Inspector");
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

        [NSBundle loadNibNamed: @"TextInspector" owner: self];

        return self;
}

- (void) awakeFromNib
{
        [view retain];
        [view removeFromSuperview];
        DESTROY(bogusWindow);
}

- (void) displayForPath: (NSString *) aPath
{
        NSString * ext;

        ASSIGN(path, aPath);
        ext = [[path pathExtension] lowercaseString];

        [text setString: @""];

        if ([ext isEqualToString: @"rtf"])
                [text replaceCharactersInRange: NSMakeRange(0, 0)
                                     withRTF: [NSData dataWithContentsOfFile: path]];
        else if ([ext isEqualToString: @"rtfd"])
                [text readRTFDFromFile: path];
        else {
                [text setFont: [NSFont userFixedPitchFontOfSize: 0]];
                [text setString: [NSString stringWithContentsOfFile: path]];
        }

        [text scrollPoint: NSZeroPoint];
}

- (void) display: (id)sender
{
        [[NSWorkspace sharedWorkspace] openFile: path];
}

- (NSView *) view
{
        return view;
}

@end
