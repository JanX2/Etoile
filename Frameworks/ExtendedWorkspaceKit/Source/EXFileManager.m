/*
	EXFileManager.m

	NSFileManager subclass which implements support for an extended workspace

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>

	Author:   Quentin Mathe <qmathe@club-internet.fr>
	Created:  8 June 2004

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "EXFileManager.h"

@implementation EXFileManager


// Private methods that allows to call NSFileManager methods which EXFileManager methods
// hide when we call [NSFileManager poseAs: [EXFileManager class]] on the Foundation 
// framework load

- (BOOL) p_changeCurrentDirectoryPath: (NSString *)path
{
    	return [super changeCurrentDirectoryPath: path];
}

- (BOOL) p_changeFileAttributes: (NSDictionary *)attributes
		        atPath: (NSString *)path
{
    	return [super changeFileAttributes: attributes atPath: path];                                               
}

- (NSArray *) p_componentsToDisplayForPath: (NSString *)path
{
   	return [super componentsToDisplayForPath: path];
}

- (NSData *) p_contentsAtPath: (NSString *)path
{
    	return [super contentsAtPath: path];
}

- (BOOL) p_contentsEqualAtPath: (NSString *)path1
		      andPath: (NSString *)path2
{
    	return [super contentsEqualAtPath: path1 andPath: path2];
}
                      
- (BOOL) p_copyPath: (NSString *)source
	    toPath: (NSString *)destination
	   handler: (id)handler
{
    	return [super copyPath: source toPath: destination handler: handler];
}

- (BOOL) p_createDirectoryAtPath: (NSString *)path
		     attributes: (NSDictionary *)attributes
{
    	return [super createDirectoryAtPath: path attributes: attributes];
}
                     
- (BOOL) p_createFileAtPath: (NSString *)path
	 	 contents: (NSData *)contents
	        attributes: (NSDictionary *)attributes
{
    return [super createFileAtPath: path contents: contents attributes: attributes];
}

- (BOOL) p_createSymbolicLinkAtPath: (NSString *)path
		       pathContent: (NSString *)otherPath
{
    	return [super createSymbolicLinkAtPath: path pathContent: otherPath];
}

- (NSString *) p_currentDirectoryPath
{
    	return [super currentDirectoryPath];
}

- (NSArray *) p_directoryContentsAtPath: (NSString *)path
{
    	return [super directoryContentsAtPath: path];
}

- (NSString *) p_displayNameAtPath: (NSString *)path
{
    	return [super displayNameAtPath: path];
}

- (NSDirectoryEnumerator *) enumeratorAtPath: (NSString *)path
{
    	return [super enumeratorAtPath: path];
}

- (NSDictionary *) p_fileAttributesAtPath: (NSString *)path
			   traverseLink: (BOOL)flag
{
    	return [super fileAttributesAtPath: path traverseLink: flag];
}

- (BOOL) p_fileExistsAtPath: (NSString *)path
{
    	return [super fileExistsAtPath: path];
}

- (BOOL) p_fileExistsAtPath: (NSString *)path isDirectory: (BOOL *)isDirectory
{
    	return [super fileExistsAtPath: path isDirectory: isDirectory];
}

- (NSDictionary *) p_fileSystemAttributesAtPath: (NSString *)path
{
    	return [super fileSystemAttributesAtPath: path];
}

- (const char *) p_fileSystemRepresentationWithPath: (NSString *)path
{
    	return [super fileSystemRepresentationWithPath: path];
}

- (BOOL) p_isExecutableFileAtPath: (NSString *)path
{
    	return [super isExecutableFileAtPath: path];
}

- (BOOL) p_isDeletableFileAtPath: (NSString *)path
{
    	return [super isDeletableFileAtPath: path]; 
}

- (BOOL) p_isReadableFileAtPath: (NSString *)path
{
 	return [super isReadableFileAtPath: path];
}

- (BOOL) p_isWritableFileAtPath: (NSString *)path
{
   	return [super isWritableFileAtPath: path];
}

- (BOOL) p_linkPath: (NSString *)source
	    toPath: (NSString *)destination
	   handler: (id)handler
{
   	return [super linkPath: source toPath: destination handler: handler];
}

- (BOOL) p_movePath: (NSString *)source
	    toPath: (NSString *)destination 
	   handler: (id)handler
{
    	return [super movePath: source toPath: destination handler: handler];
}

- (NSString *) p_pathContentOfSymbolicLinkAtPath: (NSString *)path
{
    	return [super pathContentOfSymbolicLinkAtPath: path];
}

- (BOOL) p_removeFileAtPath: (NSString *)path
		   handler: (id)handler
{
    	return [super removeFileAtPath: path handler: handler];
}
                   
- (NSString *) p_stringWithFileSystemRepresentation: (const char *)string
					    length: (unsigned int)len
{
    	return [super stringWithFileSystemRepresentation: string length: len];
}

- (NSArray *) p_subpathsAtPath: (NSString *)path
{
    	return [super subpathsAtPath: path];
}

- (BOOL) p_fileManager: (NSFileManager *)fileManager
	shouldProceedAfterError: (NSDictionary *)errorDictionary
{
  	return [super fileManager: fileManager shouldProceedAfterError: errorDictionary];
}

- (void) p_fileManager: (NSFileManager *)fileManager
    	willProcessPath: (NSString *)path
{
   	[super fileManager: fileManager willProcessPath: path];
}

@end
