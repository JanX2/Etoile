/*
	EXTGNOMEVFS.h

	Concrete class (cluster) which relies on the gnome-vfs library for the files
	interaction

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
#import <glib.h>
#import <libgnomevfs/gnome-vfs.h>
#import "EXTContext.h"
#import "EXTWorkspace.h"
#import "EXTGNOMEVFS.h"

static EXTWorkspace *workspace = nil;

@interface EXTGNOMEVFS (Private)
- (EXTContext *) _contextByLoadingAttributesWithVFSFileInfo: 
  (GnomeVFSFileInfo *)info;
- (BOOL) _processVFSResult: (GnomeVFSResult)result;
@end

@implementation EXTGNOMEVFS

/* 
 * Functions
 */

(gint) gnome_vfs_callback(GnomeVFSXferProgressInfo *info, gpointer data)
{

}

+ (void) initialize
{
  if (self == [EXTGNOMEVFS class])
    {
      workspace = [EXTWorkspace sharedInstance];
    }
}

- (id) init
{
  if (gnome_vfs_initialized() == FALSE)
    gnome_vfs_init();
  
  if (gnome_vfs_initialized() == FALSE)
    NSLog(@"Impossible d'initialiser le backend gnome-vfs"); 
    // FIXME: raise exception
}

/*
- (BOOL) createDirectoryAtURL: (NSURL *)url withPermissions: (unsigned int)perm
*/

/*
 * Protocols related methods
 */

- (NSArray *) supportedProtocols
{
  return nil;
}

/*
 * Destroy and create contexts
 */

- (BOOL) createContextWithURL: (NSURL *)url error: (NSError **)error
{
  GnomeVFSResult result;
  GnomeVFSHandle *writeHandle;
  
  if ([[workspace contextForURL: url] isEntity])
    {
      result = 
        gnome_vfs_make_directory(
          (gchar *)[[url absoluteString] UTF8String], 733);
    }
  else
    {
      result = gnome_vfs_create(&writeHandle, 
                                (gchar *)[[url absoluteString] UTF8String], 
                                GNOME_VFS_OPEN_NONE, TRUE, 311); 
    }
  
  return _processVFSResult(result);
}

- (BOOL) removeContextWithURL: (NSURL *)url handler: (id)handler
{
  GnomeVFSResult result;

  if ([[workspace contextForURL: url] isEntity])
    {
      result = 
        gnome_vfs_remove_directory((gchar *)[[url absoluteString] UTF8String]);
      return _processVFSResult(result);
    }
  else
    {
      return [self removeContextsWithURLs: [NSArray arrayWithObject: url] 
                                  handler: handler];
    }   
}

- (BOOL) removeContextsWithURLs: (NSArray *)urls handler: (id)handler
{
  GnomeVFSResult result;
  GList *removeQueue = g_list_alloc();
  NSEnumerator *e = [urls objectEnumerator];
  NSURL *obj;
  
  while ((obj = [e nextObject]) != nil)
    g_list_append(removeQueue, (gchar *)[[obj absoluteString] UTF8String]);
    
  result = gnome_vfs_xfer_delete_list(removeQueue, 
        	          GNOME_VFS_XFER_ERROR_MODE_QUERY, 
	        	             GNOME_VFS_XFER_RECURSIVE | 
		              GNOME_VFS_XFER_DELETE_ITEMS |
	          GNOME_VFS_XFER_NEW_UNIQUE_DIRECTORY |
		          GNOME_VFS_XFER_USE_UNIQUE_NAMES,
			                  &gnome_vfs_callback,
		                	                    NULL);
    
  return _processVFSResult(result);
}

/*
 * Manipulate contexts
 */

- (BOOL) copyContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination
                    handler: (id)handler
{
  return [self copyContextsWithURLs: [NSArray arrayWithObject: source] 
                              toURL: destination 
			                handler: handler];
}

- (BOOL) copyContextsWithURLs: (NSArray *)sources
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
  GnomeVFSResult result;
  GList *sourceQueue = g_list_alloc(), *destinationQueue = g_list_alloc();
  NSEnumerator *e = [sources objectEnumerator];
  NSURL *obj;
  
  g_list_append(destinationQueue, 
    (gchar *)[[destination absoluteString] UTF8String]);
  
  while ((obj = [e nextObject]) != nil)
    g_list_append(sourceQueue, (gchar *)[[obj absoluteString] UTF8String]);
    
  result = gnome_vfs_xfer_url_list(sourceQueue,
                              destinationQueue, 
               GNOME_VFS_XFER_ERROR_MODE_QUERY, 
	                  GNOME_VFS_XFER_RECURSIVE | 
	       GNOME_VFS_XFER_NEW_UNIQUE_DIRECTORY |
	           GNOME_VFS_XFER_USE_UNIQUE_NAMES,
         GNOME_VFS_XFER_OVERWRITE_MODE_REPLACE, 
        // GNOME_VFS_XFER_OVERWRITE_MODE_ABORT
         // GNOME_VFS_XFER_OVERWRITE_MODE_SKIP
			               &gnome_vfs_callback,
		                	                 NULL);

  return _processVFSResult(result);
}

- (BOOL) linkContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
                  linkStyle: (EXTLinkStyle) style
{
  // Not implemented
  
  return NO;
}

- (BOOL) moveContextWithURL: (NSURL *)source 
                      toURL: (NSURL *)destination 
                    handler: (id)handler
{
  GnomeVFSResult result;
  gboolean identicalFS;
  
  gnome_vfs_check_same_fs((gchar *)[[source absoluteString] UTF8String], 
    (gchar *)[[destination absoluteString] UTF8String], &identicalFS);
  if (identicalFS)
    {
      result = gnome_vfs_move([[source absoluteString] UTF8String], 
        (gchar *)[[destination absoluteString] UTF8String], FALSE);
      return _processVFSResult(result);
    }
  else
    {
      return [self moveContextsWithURLs: [NSArray arrayWithObject: source] 
                                  toURL: destination 
			                    handler: handler];
    }
}

- (BOOL) moveContextsWithURLs: (NSArray *)sources
                        toURL: (NSURL *)destination 
                      handler: (id)handler
{
  GnomeVFSResult result;
  GList *sourceQueue = g_list_alloc(), *destinationQueue = g_list_alloc();
  NSEnumerator *e = [sources objectEnumerator];
  NSURL *obj;
  
  g_list_append(destinationQueue, 
    (gchar *)[[destination absoluteString] UTF8String]);
  
  while ((obj = [e nextObject]) != nil)
    g_list_append(sourceQueue, (gchar *)[[obj absoluteString] UTF8String]);
    
  result = gnome_vfs_xfer_url_list(sourceQueue,
                              destinationQueue, 
               GNOME_VFS_XFER_ERROR_MODE_QUERY, 
	                  GNOME_VFS_XFER_RECURSIVE |
	               GNOME_VFS_XFER_DELETE_ITEMS | 
	       GNOME_VFS_XFER_NEW_UNIQUE_DIRECTORY |
	          GNOME_VFS_XFER_USE_UNIQUE_NAMES,
        GNOME_VFS_XFER_OVERWRITE_MODE_REPLACE, 
       // GNOME_VFS_XFER_OVERWRITE_MODE_ABORT
        // GNOME_VFS_XFER_OVERWRITE_MODE_SKIP
			              &gnome_vfs_callback,
		                             	NULL);

  return _processVFSResult(result);
}

/*
 * Visit contexts
 */
 
- (NSArray *) subcontextsAtURL: (NSURL *)url deep: (BOOL)flag
{
  GnomeVFSDirectoryHandle *handle; 
  GnomeVFSFileInfo *file;
  BOOL more = YES;
  NSMutableArray *subcontexts = [NSMutableArray array];
  
  gnome_vfs_directory_open(&handle, (gchar *)[[url absoluteString] UTF8String], 
    GNOME_VFS_FILE_INFO_FORCE_FAST_MIME_TYPE);
  
  while (more)
    {
      more = _processVFSResult(gnome_vfs_directory_read_next(handle, file));
      [subcontexts addObject: 
        [self _contextByLoadingAttributesWithVFSFileInfo: file]];
    }
    
  gnome_vfs_directory_close(handle);
  
  return subcontexts;
}

/*
 * Read, write contexts
 */
  
- (NSData *) readContext: (EXTContext *)context 
                  length: (unsigned long long)length 
                error: (NSError **)error
{
  GnomeVFSHandle *handle = [context handleForContent];
  GnomeVFSFileSize readLength;
  gpointer buffer;
  
  if (handle == NULL) // Variable context has no content
    {
      // Adjust error
      return nil;
    }
    
  gnome_vfs_read(handle, buffer, (GnomeVFSFileSize)length, &readLength);
  
  if (length != readLength)
    {
      // Adjust error
    }
  
  return [NSData dataWithBytesNoCopy: (void *)buffer length: readLength]; 
}

- (void) writeContext: (EXTContext *)context 
                 data: (NSData *)data 
               length: (unsigned long long)length 
                error: (NSError **)error
{
  GnomeVFSHandle *handle = [context handleForContent];
  GnomeVFSFileSize writeLength;
  gpointer buffer = (gpointer)[data bytes];
  
  if (handle == NULL) // Variable context has no content
    {
      // Adjust error
      return;
    }
    
  gnome_vfs_write(handle, buffer, length, &writeLength);
  
  if (length != writeLength)
    {
      // Adjust error
    }
}

- (void) setPositionIntoContext: (EXTContext *)context 
                          start: (EXTReadWritePosition)start 
                         offset: (long long)offset 
                          error: (NSError **)error
{
  GnomeVFSSeekPosition seekPosition;
  GnomeVFSHandle *handle = [context handleForContent];
  
  if (handle == NULL) // Variable context has no content
    {
      // Adjust error
      return;
    }
  
  switch (start)
    {
      case EXTReadWritePositionStart:
        seekPosition = GNOME_VFS_SEEK_START;
	break;
      case EXTReadWritePositionCurrent:
        seekPosition = GNOME_VFS_SEEK_CURRENT;
	break;
      case EXTReadWritePositionEnd:
        seekPosition = GNOME_VFS_SEEK_END;
	break;
    }
  
  gnome_vfs_seek(handle, seekPosition, (GnomeVFSFileOffset)offset);
}

- (long long) positionIntoContext: (EXTContext *)context 
                            error: (NSError **)error
{
  GnomeVFSHandle *handle = [context handleForContent];
  GnomeVFSFileSize position;
  
  if (handle == NULL) // Variable context has no content
    {
      // Adjust error
      return 0;
    }
  
  gnome_vfs_tell(handle, &position);
  
  return position;
}
 
/*
 * Private methods
 */
  
- (EXTContext *) _contextByLoadingAttributesWithVFSFileInfo: 
  (GnomeVFSFileInfo *)info
{
  return nil;
}

- (BOOL) _processVFSResult: (GnomeVFSResult)VFSResult
{
  switch(VFSResult)
    {
      case GNOME_VFS_OK:
        return YES;
        //break;
    }
    
}

@end
