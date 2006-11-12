#import <AppKit/AppKit.h>
#import <CollectionKit/CollectionKit.h>

@interface ContentTextView: NSTextView
{
  CKItem *item;
  NSFont *font;
}

- (void) setItem: (CKItem *) item;
- (CKItem *) item;

- (void) setBaseFont: (NSFont *) font;
@end
