/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "TWDocument.h"
#include "TWTextView.h"

@implementation TWDocument

- (void) awakeFromNib
{
  /* It is difficult to connect to textView in scroll view with Gorm */
  textView = [scrollView documentView];
}

- (void) windowControllerDidLoadNib: (NSWindowController *) windowController
{
  [[textView textStorage] setAttributedString: aString];
}

- (NSString *) windowNibName
{
  return @"Document.gorm";
}

- (BOOL) loadDataRepresentation: (NSData *) data ofType: (NSString *) type
{
  if ([type isEqualToString: @"TWRTFTextType"]) {
    ASSIGN(aString, AUTORELEASE([[NSAttributedString alloc] initWithRTF: data documentAttributes: NULL]));
  } else if ([type isEqualToString: @"TWPlainTextType"]) {
    NSString *s = [[NSString alloc] initWithData: data
	                          encoding: [NSString defaultCStringEncoding]];
    ASSIGN(aString, AUTORELEASE([[NSAttributedString alloc] initWithString: s]));
    DESTROY(s);
  }
  if (aString) {
    return YES;
  } else {
    return NO;
  }
}

- (NSData *) dataRepresentationOfType: (NSString *) type
{
}

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type
{
}

- (BOOL)loadFileWrapperRepresentation:(NSFileWrapper *)wrapper
                               ofType:(NSString *)type
{
  if ([type isEqualToString: @"TWRTFDTextType"]) {
    ASSIGN(aString, AUTORELEASE([[NSAttributedString alloc] initWithRTFDFileWrapper: wrapper documentAttributes: NULL]));
    if (aString) {
      return YES;
    }
  } else {
    return [super loadFileWrapperRepresentation: wrapper ofType: type];
  }
  return NO;
}

@end
