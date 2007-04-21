/*
   The text/RTF inspector.

   Copyright (C) 2005 Saso Kiselkov

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
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
