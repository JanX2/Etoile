/*
	EXGNUstepVFS.m

	Concrete class (partially a cluster) which relies on the GNUstep NSFileManager 
	class for the files interaction

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>

	Author:   Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2004

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
#import "EXGNUstepVFS.h"
#import "EXFileManager.h"

static EXFileManager *fileManager = nil;

@interface EXGNUstepVFS (Private)
- (void) _isNotFileURL: (NSURL *)url;
@end

@implementation EXGNUstepVFS

+ (void) initialize
{
    if (self == [EXGNUstepVFS class])
    {
        fileManager = [EXFileManager defaultManager];
    }
}

- (id) init
{
  // Nothing to initialize
}

/*
- (BOOL) createDirectoryAtURL: (NSURL *)url withPermissions: (unsigned int)perm
 */

/*
 * Protocols related methods
 */

- (NSArray *) supportedProtocols
{
    return [NSArray arrayWithObjects: @"file://", nil];
}

/*
 * Destroy and create contexts
 */

- (BOOL) createEntityContextWithURL: (NSURL *)url error: (NSError **)error 
{
    BOOL result;
  
    if ([url isFileURL])
    {
        result = [fileManager p_createDirectoryAtPath: [url path] attributes: nil];
    }
    else
    {
        [self _isNotFileURL: url];
    result = NO;
    }
    
    return result;
}

/*
- (BOOL) createEntityContextWithURL: (NSURL *)url 
                              error: (NSError **)error 
                      VFSAttributes: (NSDictionary *) attributes
{
    // TODO: convert EXVFS attributes to NSFileManager attributes
    
    return NO;
}
 */
 
- (BOOL) createElementContextWithURL: (NSURL *)url error: (NSError **)error
{
    BOOL result;
  
    if ([url isFileURL])
    {
        result = [fileManager p_createFileAtPath: [url path] contents: nil attributes: nil];
    }
    else
    {
        [self _isNotFileURL: url];
        result = NO;
    }
    
    return result;
}

/*
- (BOOL) createElementContextWithURL: (NSURL *)url 
                               error: (NSError **)error 
                       VFSAttributes: (NSDictionary *) attributes
{
    // TODO: convert EXVFS attributes to NSFileManager attributes
    
    return NO;
}
 */
 
- (BOOL) removeContextWithURL: (NSURL *)url handler: (id)handler
{
    BOOL result;
  
    if ([url isFileURL])
    {
        result = [fileManager p_removeFileAtPath: url handler: self];     
    }
    else
    {
      [self _isNotFileURL: url];
      result = NO;
    }
  
  return result;
}

- (BOOL) removeContextsWithURLs: (NSArray *)urls handler: (id)handler
{
    NSEnumerator *e = [urls objectEnumerator];
    NSURL *url;
    BOOL result;
  
    while ((url = [e nextObject]) != nil)
    {
        if ([url isFileURL])
        {
            result = [fileManager p_removeFileAtPath: url handler: self];
        }
        else
        {
            [self _isNotFileURL: url];
            result = NO;
        }
    }
  
    return result;
}

/*
 * Manipulate contexts
 */

- (BOOL) copyContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination
                    handler: (id)handler
{
    BOOL result = NO;
  
    if ([source isFileURL] && [destination isFileURL])
    {
        result = [fileManager p_copyPath: [source path] toPath: [destination path] handler: self];     
    }
    else
    {
        [self _isNotFileURL: url];
        result = NO;
    }
  
    return result;
}

- (BOOL) copyContextsWithURLs: (NSArray *)sources
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
    NSEnumerator *e = [source objectEnumerator];
    NSURL *url;
  
    if ([destination isFileURL] == NO)
    {
        [self _isNotFileURL: url];
        return NO;
        }
  
    while ((url = [e nextObject]) != nil)
    {
        if ([url isFileURL])
        {
            result = [fileManager p_copyPath: url toPath: destination handler: self];
        }
        else
        {
            [self _isNotFileURL: url];
            result = NO;
        }
    }
  
  return result;
}

- (BOOL) linkContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
                  linkStyle: (EXLinkStyle) style
{
    BOOL result = NO;
  
    if ([source isFileURL] && [destination isFileURL])
    {
        result = [fileManager p_linkPath: [source path] toPath: [destination path] handler: self];     
    }
    else
    {
        [self _isNotFileURL: url];
        result = NO;
    }
  
  return result;
}

- (BOOL) moveContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
{
    BOOL result = NO;
  
    if ([source isFileURL] && [destination isFileURL])
    {
        result = [fileManager p_movePath: [source path] toPath: [destination path] handler: self];     
    }
    else
    {
        [self _isNotFileURL: url];
        result = NO;
    }
  
    return result;
}

- (BOOL) moveContextsWithURLs: (NSArray *)sources
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
    NSEnumerator *e = [source objectEnumerator];
    NSURL *url;
  
    if ([destination isFileURL] == NO)
    {
        [self _isNotFileURL: url];
        return NO;
    }
  
    while ((url = [e nextObject]) != nil)
    {
        if ([url isFileURL])
        {
            result = [fileManager p_movePath: url toPath: destination handler: self];
        }
        else
        {
            [self _isNotFileURL: url];
            result = NO;
        }
    }
  
    return result;
}

/*
 * Visit contexts
 */
 
- (NSArray *) subcontextsURLsAtURL: (NSURL *)url deep: (BOOL)flag
{
    NSArray *paths;
  
    if ([url isFileURL] == NO)
    {
        [self _isNotFileURL: url];
        return nil;
    }
  
    if (deep)
    {
        paths = [fileManager p_subpathsAtPath: [url path]];
    }
    else
    {
        paths = [fileManager p_directoryContentsAtPath: [url path]];
    }
      
  return paths;
}

/*
 * Open, close contexts
 */
 
- (EXVFSHandle) openContextAtURL: (NSURL *)url mode: (EXVFSMode)mode
{
  EXVFSHandle *handle;
  NSFileHandle *fh;
    
  if ([url isFileURL] == NO)
    {
      [self _isNotFileURL: url];
      return nil;
    }
    
  switch (mode)
    {
      case EXVFSModeRead:
        fh = [NSFileHandle fileHandleForReadingAtPath: [url path]];
        break;
      case EXVFSModeWrite:
        fh = [NSFileHandle fileHandleForWritingAtPath: [url path]];
        break;
      case EXVFSModeReadWrite:
        fh = [NSFileHandle fileHandleForUpdatingAtPath: [url path]];
        break;
    }
    
  return [[EXVFSHandle alloc] initWithFileHandle: fh];
}

- (void) closeContextWithVFSHandle: (EXVFSHandle *)handle
{
  NSFileHandle *fh = [handle fileHandle];
  
  [fh closeFile];
}

/*
 * Read, write contexts
 */

// We need to pass a context and not an URL, because the context can maintain a handle for a file which is open
// with an URL, we would need to reopen the file each time we want the handle.
 
- (NSData *) readContextWithVFSHandle: (EXVFSHandle *)handle
                               length: (unsigned long long)length 
                                error: (NSError **)error
{
  NSFileHandle *fh;
  NSData *data;
  
  if ([handle hasFileHandle] == NO)
    {
      [self _isNotFileURL: url];
      return NO;
    }
  
  fd = [handle fileHandle];
  data = [fd readDataOfLength: length];
  
  return data; 
}

- (void) writeContextWithVFSHandle: (EXVFSHandle *)handle 
                              data: (NSData *)data 
                            length: (unsigned long long)length 
                             error: (NSError **)error
{
  NSFileHandle *fh;
  NSData *subdata;
  
  if ([handle hasFileHandle] == NO)
    {
      [self _isNotFileURL: url];
      return NO;
    }
  
  fd = [handle fileHandle];
  if ([data length] != length)
    {
      subdata = [NSData dataWithBytes: [data bytes] length: length];
    }
  else
    {
      subdata = data;
    }
    
  [fd writeData: subdata];
}

- (void) setPositionIntoContextWithVFSHandle: (EXVFSHandke *)handle
                                       start: (EXReadWritePosition)start 
                                      offset: (long long)offset 
                                       error: (NSError **)error
{
  NSFileHandle *fh;
  NSData *data;
  unsigned long long size;
  
  if ([handle hasFileHandle] == NO)
    {
      [self _isNotFileURL: url];
      return NO;
    }
  
  fd = [handle fileHandle];
  
  switch (start)
    {
      case EXReadWritePositionStart:
        [fd seekToFileOffset: offset];
        break;
      case EXReadWritePositionEnd:
        size = [fd seekToEndOfFile];
        [fd seekToFileOffset: size - offset];
        break;
    }    
}

- (unsigned long long) positionIntoContextWithVFSHandle: (EXVFSHandle *)handle
                                                  error: (NSError **)error
{
    NSFileHandle *fh;
    unsigned long long offset;
  
    if ([handle hasFileHandle] == NO)
    {
        [self _isNotFileURL: url];
        return NO;
    }
  
    fd = [handle fileHandle];
    offset = [fd offsetInFile];
  
    return offset;
}

/*
 * Posix attributes related methods
 */
 
 - (NSDictionary *) posixAttributesAtURL: (NSURL *)url
 {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: 10];
    NSDictionary *fmDict;
    NSString *value;
    
    if ([url isFileURL] == NO)
    {
        [self _isNotFileURL: url];
        return nil;
    }
    
    fmDict = [fileManager p_fileAttributesAtPath: [url path] traverseLink: NO];
    
    [dict setObject: [fmDict objectForKey: NSFileCreationDate] forKey: EXAttributeCreationDate];
    [dict setObject: [fmDict objectForKey: NSFileSize] forKey: EXAttributeSize];
    [dict setObject: [fmDict objectForKey: NSFileModificationDate] forKey: EXAttributeModificationDate];
    [dict setObject: [fmDict objectForKey: NSFileType] forKey: EXAttributeFSType];
    [dict setObject: [fmDict objectForKey: NSFilePosixPermissions] forKey: EXAttributePosixPermissions];
    [dict setObject: [fmDict objectForKey: NSFileOwnerAccountID] forKey: EXAttributeOwnerNumber];
    [dict setObject: [fmDict objectForKey: NSFileOwnerAccountName] forKey: EXAttributeOwnerName];
    [dict setObject: [fmDict objectForKey: NSFileGroupOwnerAccountID] forKey: EXAttributeGroupOwnerNumber];
    [dict setObject: [fmDict objectForKey: NSFileGroupOwnerAccountName] forKey: EXAttributeGroupOwnerName];
    [dict setObject: [fmDict objectForKey: NSFileDeviceIdentifier] forKey: EXAttributeDeviceNumber];
    [dict setObject: [fmDict objectForKey: NSFileSystemFileNumber] forKey: EXAttributeFSNumber];

    value = [dict objectForKey: EXAttributeFSType];
    if ([value isEqualToString: NSFileTypeDirectory])
        [dict setObject: EXFSTypeDirectory forKey: EXAttributeFSType];
    else if ([value isEqualToString: NSFileTypeRegular])
        [dict setObject: EXFSTypeRegular forKey: EXAttributeFSType];
    else if ([value isEqualToString: NSFileTypeSymbolicLink])
        [dict setObject: EXFSTypeSymbolicLink forKey: EXAttributeFSType];
    else if ([value isEqualToString: NSFileTypeSocket])
        [dict setObject: EXFSTypeSocket forKey: EXAttributeFSType];
    else if ([value isEqualToString: NSFileTypeCharacterSpecial])
        [dict setObject: EXFSTypeCharacterSpecial forKey: EXAttributeFSType];
    else if ([value isEqualToString: NSFileTypeBlockSpecial])
        [dict setObject: EXFSTypeBlockSpecial forKey: EXAttributeFSType];
    else ([value isEqualToString: NSFileTypeUnknown)
        [dict setObject: EXFSTypeUnknown forKey: EXAttributeFSType];
        
    return dict;
 }
 
 - (id) posixAttributeWithName: (NSString *)name atURL: (NSURL *)url
 {
    return [[self posixAttributesAtURL: url] objectForKey: name];
 }

/*
 * Extra methods
 */
 
- (BOOL) isEntityContextAtURL: (NSURL *)url
{
    BOOL isDir;
  
    if ([url isFileURL] == NO)
    {
        [self _isNotFileURL: url];
        return NO;
    }

    result = [fileManager p_fileExistsAtPath: [url path] isDirectory: &isDir];
    if (result && isDir)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL) isElementContextAtURL: (NSURL *)url
{
    BOOL isDir;
    BOOL result;
  
    if ([url isFileURL] == NO)
    {
        [self _isNotFileURL: url];
        return NO;
    }
  
    result = [fileManager p_fileExistsAtPath: [url path] isDirectory: &isDir];
    if (result && !isDir)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void) _isNotFileURL: (NSURL *)url
{
  NSLog(@"GNUstep VFS backend doesn't support the URL %@ because it is not a local file.", url);
}

@end
