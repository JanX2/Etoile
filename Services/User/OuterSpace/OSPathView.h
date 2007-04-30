#import <AppKit/AppKit.h>

@interface OSPathView : NSControl
{
  NSString *path;
  NSString *prefix;
  id delegate;
	
  NSMutableArray *cells;
  NSButtonCell *left;
  NSButtonCell *right;
  NSImageCell *separator;
  int startIndex; /* the first cell to display, set by left and right arrow */
}

/* prefix + path will be the absolute path.
 * It will display path only. */
- (NSString *) prefix;
- (void) setPrefix: (NSString *) prefix;

- (NSString *) path;
- (void) setPath: (NSString *) path;

- (NSString *) absolutePath;

- (void) setDelegate: (id) delegate;
- (id) delegate;

@end

@interface NSObject (OSPathViewDelegate)
/* Notify the selected path */
- (void) pathView: (OSPathView *) view selectedPath: (NSString *) path;
@end
