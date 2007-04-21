/*
   The image inspector.

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

#import "ImageInspector.h"

@implementation ImageInspector

static NSArray * exts = nil;

+ (NSArray *) extensions
{
        if (exts == nil)
                ASSIGN(exts, ([NSArray arrayWithObjects:
                  @"jpg", @"jpeg", @"png", @"tif", @"tiff",
                  @"gif", @"xpm", nil]));

        return exts;
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
        
        [NSBundle loadNibNamed: @"ImageInspector" owner: self];
        
        return self;
}

- (void) awakeFromNib
{
        [view retain];
        [view removeFromSuperview];
        DESTROY(bogusWindow);
}

- (NSString *) inspectorName
{
        return _(@"Image Inspector");
}

- (void) displayForPath: (NSString *) aPath
{
        NSImage * img;
        NSSize viewSize;
        NSSize imgSize;

        ASSIGN(path, aPath);

        img = [[[NSImage alloc]
          initByReferencingFile: path] autorelease];
        imgSize = [img size];
        viewSize = [image frame].size;

        [width setIntValue: imgSize.width];
        [height setIntValue: imgSize.height];

         // do we need to scale down?
        if (imgSize.width > viewSize.width ||
            imgSize.height > viewSize.height) {
                float xRatio, yRatio;

                xRatio = (viewSize.width / imgSize.width) * 100;
                yRatio = (viewSize.height / imgSize.height) * 100;

                [scale setStringValue: [NSString stringWithFormat:
                  _(@"%.0f%%"), xRatio < yRatio ? xRatio : yRatio]];
                [image setImageScaling: NSScaleProportionally];
        } else {
                [image setImageScaling: NSScaleNone];
                [scale setStringValue: _(@"100%")];
        }

        [image setImage: img];
}

- (NSView *) view
{
        return view;
}

- (void) display: sender
{
        [[NSWorkspace sharedWorkspace] openFile: path];
}

@end
