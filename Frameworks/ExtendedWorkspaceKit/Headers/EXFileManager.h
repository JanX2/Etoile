/*
	EXFileManager.h

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

#import <Foundation/NSFileManager.h>

@interface EXFileManager : NSFileManager
{

}

@end

@interface NSFileManager (EXPrivate)

// Private methods that allows to call NSFileManager methods which EXFileManager methods
// hide when we call [NSFileManager poseAs: [EXFileManager class]] on the Foundation 
// framework load

- (BOOL) p_changeCurrentDirectoryPath: (NSString *)path;
- (BOOL) p_changeFileAttributes: (NSDictionary *)attributes
		        atPath: (NSString *)path;
- (NSArray *) p_componentsToDisplayForPath: (NSString*)path;
- (NSData *) p_contentsAtPath: (NSString *)path;
- (BOOL) p_contentsEqualAtPath: (NSString *)path1
		      andPath: (NSString *)path2;
- (BOOL) p_copyPath: (NSString *)source
	    toPath: (NSString *)destination
	   handler: (id)handler;
- (BOOL) p_createDirectoryAtPath: (NSString *)path
		     attributes: (NSDictionary *)attributes;
- (BOOL) p_createFileAtPath: (NSString *)path
	 	 contents: (NSData *)contents
	        attributes: (NSDictionary *)attributes;
- (BOOL) p_createSymbolicLinkAtPath: (NSString *)path
		       pathContent: (NSString *)otherPath;
- (NSString *) p_currentDirectoryPath;
- (NSArray *) p_directoryContentsAtPath: (NSString *)path;
- (NSString *) p_displayNameAtPath: (NSString *)path;
- (NSDirectoryEnumerator *) p_enumeratorAtPath: (NSString *)path;
- (NSDictionary *) p_fileAttributesAtPath: (NSString *)path
			   traverseLink: (BOOL)flag;
- (BOOL) p_fileExistsAtPath: (NSString *)path;
- (BOOL) p_fileExistsAtPath: (NSString *)path isDirectory: (BOOL *)isDirectory;
- (NSDictionary *) p_fileSystemAttributesAtPath: (NSString *)path;
- (const char *) p_fileSystemRepresentationWithPath: (NSString *)path;
- (BOOL) p_isExecutableFileAtPath: (NSString *)path;
- (BOOL) p_isDeletableFileAtPath: (NSString *)path;
- (BOOL) p_isReadableFileAtPath: (NSString *)path;
- (BOOL) p_isWritableFileAtPath: (NSString *)path;
- (BOOL) p_linkPath: (NSString *)source
	    toPath: (NSString *)destination
	   handler: (id)handler;
- (BOOL) p_movePath: (NSString *)source
	    toPath: (NSString *)destination 
	   handler: (id)handler;
- (NSString *) p_pathContentOfSymbolicLinkAtPath: (NSString *)path;
- (BOOL) p_removeFileAtPath: (NSString *)path
		   handler: (id)handler;
- (NSString *) p_stringWithFileSystemRepresentation: (const char *)string
					    length: (unsigned int)len;
- (NSArray *) p_subpathsAtPath: (NSString*)path;

- (BOOL) p_fileManager: (NSFileManager *)fileManager
    shouldProceedAfterError: (NSDictionary *)errorDictionary;
- (void) p_fileManager: (NSFileManager *)fileManager
    willProcessPath: (NSString *)path;

@end
