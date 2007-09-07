/*
	IKWorkspaceAdditions.h

	IKWorkspaceAdditions is a category to add IconKit support to NSWorkspace.

	Copyright (C) 2005 Uli Kusterer <contact@zathras.de>
	                   Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:   Uli Kusterer <contact@zathras.de>
	          Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2005

    This application is free software; you can redistribute it and/or 
    modify it under the terms of the 3-clause BSD license. See COPYING.
*/

#import <AppKit/AppKit.h>


@interface NSWorkspace (IKIconAdditions)

- (NSImage *) iconForFile: (NSString *)fullPath;
- (NSImage *) iconForFiles: (NSArray *)fullPaths;
- (NSImage *) iconForFileType: (NSString *)fileType;

@end

