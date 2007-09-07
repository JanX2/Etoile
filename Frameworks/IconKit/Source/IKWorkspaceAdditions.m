/*
 *  IKWorkspaceAdditions.m
 *  
 *
 *  Created by Uli Kusterer on 31.12.04.
 *  Copyright 2004 M. Uli Kusterer. All rights reserved.
 *
 *  This application is free software; you can redistribute it and/or 
 *  modify it under the terms of the 3-clause BSD license. See COPYING.
 */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "IKCompat.h"
#import <IconKit/IKIcon.h>


// -----------------------------------------------------------------------------
//  Make NSWorkspace use our IconKit instead of its own, slow code:
// -----------------------------------------------------------------------------

// FIX ME! Right now, IKIcon calls these to get the icons, so we can't override
//         these to call IKIcon or we'd recurse endlessly. Uncomment these once
//         we've changed IKIcon to use Quentin's code.

/*@implementation NSWorkspace (IKIconAdditions)

-(NSImage*) iconForFile: (NSString*)fullPath
{
    return [[[[IKIcon alloc] initForFile: fullPath] autorelease] image];
}


-(NSImage*) iconForFiles: (NSArray*)fullPaths
{
    return [self iconForFile: [fullPaths objectAtIndex: 0]];  // FIX ME! Needs to look at all icons and find a best guess, I suppose?
}


-(NSImage*) iconForFileType: (NSString*)fileType
{
    IKIcon* icon = [IKIcon iconWithExtension: fileType mimeType: nil attributes: nil];
    
    return [icon image];
}

@end*/
