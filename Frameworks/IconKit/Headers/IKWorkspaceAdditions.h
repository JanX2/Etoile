/*
 *  IKWorkspaceAdditions.h
 *  
 *
 *  Created by Uli Kusterer on 04.01.05.
 *  Copyright 2005 M. Uli Kusterer. All rights reserved.
 *
 */

#ifndef ICONKIT_IKWORKSPACEADDITIONS_H
#define ICONKIT_IKWORKSPACEADDITIONS_H 1

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#include <AppKit/AppKit.h>


// -----------------------------------------------------------------------------
//  Categories:
// -----------------------------------------------------------------------------

@interface NSWorkspace (IKIconAdditions)

-(NSImage*) iconForFile: (NSString*)fullPath;
-(NSImage*) iconForFiles: (NSArray*)fullPaths;
-(NSImage*) iconForFileType: (NSString*)fileType;

@end


#endif /*ICONKIT_IKWORKSPACEADDITIONS_H*/
