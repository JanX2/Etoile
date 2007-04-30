#import <AppKit/AppKit.h>

typedef enum _OSObjectError {
  OSObjectNotExistingOnFileSystemError, 
  OSObjectFileSystemOperationFailedError,
  OSObjectNotAllowedActionError, 
  OSObjectIdenticalObjectError, /* when an identical object already exist */
  OSObjectUnknownError /* Error for no reason. Need debug */
} OSObjectError;

/* OSObject implement necessary methods for file manager */
@protocol OSObject <NSObject>

/* Allow to match either prefix or path Extension 
   to decide which object to use. Return nil if not used.
   return [@"tif", @"tiff"] in pathExtensions to match TIFF files. */
+ (NSArray *) prefix;
+ (NSArray *) pathExtension;

- (NSString *) name; /* Full name, usually lastPathComponent. */
- (NSImage *) icon; 
- (NSImage *) preview; 

/* Refresh internal cache. Its behavior depends on implementation */
- (void) refresh;

/* If it is not a directory, return nil.
   If it is an empty directory, return an empty array.
   Object may have 0 child and return YES for -hasChildren. */
- (BOOL) hasChildren;
- (NSArray *) children;

- (NSComparisonResult) caseInsensitiveCompare: (id <OSObject>) object;

/* These methods will be called when children are drag-and-drop or 
   copying/moving. Each child will also be asked with 
   protocol OSNodeOperation when real copying/moving happens 
   (See OSNodeOperation below). 
   These are mainly controlling the behaviors of drag-and-drop. */
/* For drag */
/* Return children which is allowed to be dragged. Return nil if none. */
- (BOOL) willTakeAwayChild: (id <OSObject>) child;
/* object will be notified when children are really take away.
   It is a copy by default, unless move: flag is YES.
   - refresh will be called after a mass file operation.
   Therefore, there is no need to refresh children here. */
- (void) doTakeAwayChild: (id <OSObject>) child move: (BOOL) flag;
/* For drop */
/* Return YES if it can take this child */
- (BOOL) willAcceptChild: (id <OSObject>) child error: (unsigned int *) error;
/* Return YES if it successfully took this child.
   It is a copy by default, unless move: flag is YES.
   Object should implement file operation here. */
- (BOOL) doAcceptChild: (id <OSObject>) child move: (BOOL) flag
                 error: (unsigned int *) error;

@end

@class OSNode;

/* This is informal protocol. There is no need to implement it
   if it is not necessary */
@interface NSObject (OSNodeOperation)
/* The object been copied or moved will receive these calls.
 * If object does not implement any of them, itself will be used.
 * It is usually used by special object, such as OSVirtualNode.
 * Returning nil will stop copying or moving.
 * For OSVirtualNode, it may need to write into /tmp first,
 * then return that /tmp file as OSNode.
 * The bottom line is that the returned OSNode will be used with NSFileManager.
 * If the returned OSNode is not ready, 
 * the file operation will not proceed or even fails.
 */
- (OSNode *) willStartCopying;
- (void) didFinishCopying;
- (OSNode *) willStartMoving;
- (void) didFinishMoving;

/* It is usually called when object is double-clicked.
   When it fails to launch, return NO and an alert will shows.
   If object do not want to be launched, it can either not implement this
   or return YES so that no warning will raise.  */
- (BOOL) doLaunching;

@end

