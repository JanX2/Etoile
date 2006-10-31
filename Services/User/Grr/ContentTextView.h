#import <AppKit/AppKit.h>
#import <CollectionKit/CollectionKit.h>

@interface ContentTextView: NSTextView
{
  CKItem *item;
}

- (void) setItem: (CKItem *) item;
- (CKItem *) item;
@end
