#import <AppKit/AppKit.h>
#import "OSDistributedCell.h"

@interface OSDistributedView: NSControl
{
  NSMutableArray *cells; /* All cells to display */
  id delegate;
  id dataSource;

  NSMutableArray *selectedCells;

  /* Cache */
  OSDistributedCell *oldCellForDrop;
}

- (void) setDelegate: (id) delegate;
- (id) delegate;
- (void) setDataSource: (id) dataSource;
- (id) dataSource;

- (NSArray *) selectedCells;

/* The last selected cell. 
   If Shift is hold and a cell is deselected, 
   this will be any of the previously selected cell.
   The order of selection is not preserved. */
- (OSDistributedCell *) selectedCell;

@end

/* Data Source */
@interface NSObject (OSDistributedViewDataSource)
- (unsigned int) numberOfObjectsInDistributedView: (OSDistributedView *) view;
- (id) distributedView: (OSDistributedView *) view 
         objectAtIndex: (unsigned int) index;
/* Drag source */
- (BOOL) distributedView: (OSDistributedView *) view
         writeObjectsWithIndexes: (NSIndexSet *) indexes
         toPasteboard: (NSPasteboard *) pboard;
/* Drag destination */
/* validation will be called frequently in order to update the cursor icon
   in real time when moving on top of file or folder */
- (BOOL) distributedView: (OSDistributedView *) view
	 validateDrop: (id <NSDraggingInfo>) info
         onObject: (id) object; // object can be nil if on empty space
- (BOOL) distributedView: (OSDistributedView *) view
	 acceptDrop: (id <NSDraggingInfo>) info
         onObject: (id) object; // object can be nil if on empty space
@end

@interface NSObject (NSDistributedViewDelegate)
- (void) distributedView: (OSDistributedView *) view
              openObject: (id <OSObject>) object inNewWindow: (BOOL) flag;
- (void) distributedView: (OSDistributedView *) view
        didSelectObjects: (NSArray *) objects;
@end

