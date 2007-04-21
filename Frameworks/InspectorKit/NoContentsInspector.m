/*
   NoContentsInspector.m
   A contents inspector displayed when no specific contents inspector
   is available.

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

#import "NoContentsInspector.h"

@implementation NoContentsInspector

+ (NSArray *) extensions
{
        return nil;
}

- (void) dealloc
{
        NSDebugLLog(@"NoContentsInspector", @"NoContentsInspector: dealloc");

        TEST_RELEASE(box);

        [super dealloc];
}

- (NSString *) inspectorName
{
        return _(@"No Contents Inspector");
}

- (void) displayForPath: (NSString *) aPath
{
}

- (void) awakeFromNib
{
        [box retain];
        [box removeFromSuperview];
        DESTROY(bogusWindow);
}

- (NSView *) view
{
        return box;
}

@end
