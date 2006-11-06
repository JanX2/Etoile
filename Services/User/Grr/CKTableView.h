#import <CollectionKit/CollectionKit.h>

/* Use category to override some default behavior */
@interface CKTableView (RSSReader)

@end

@interface NSObject (RSSReader)
- (void) enterKeyDownInTableView: (NSTableView *) tableView;
@end

