/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "TWDocument.h"
#include "TWTextView.h"
#include "TWCharacterPanel.h"
#include <OgreKit/OgreTextFinder.h>

@implementation TWDocument

- (void) characterSelectedInPanel: (id) sender
{
  NSString *character = [[[(TWCharacterPanel *)sender matrix] selectedCell] stringValue];
  [textView insertText: character];
}

- (void) awakeFromNib
{
  /* It is difficult to connect to textView in scroll view with Gorm */
  textView = [scrollView documentView];
  textFinder = [OgreTextFinder sharedTextFinder];
  [textFinder setTargetToFindIn: textView];
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
  NSTextStorage *ts = [textView textStorage];
  if ([type isEqualToString: @"TWRTFTextType"]) {
    return [ts RTFFromRange: NSMakeRange(0, [ts length]) documentAttributes: nil];
  } else if ([type isEqualToString: @"TWPlainTextType"]) {
    return [[ts string] dataUsingEncoding: [NSString defaultCStringEncoding]];
  } else {
    return nil;
  }
}

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)type
{
  if ([type isEqualToString: @"TWRTFDTextType"]) {
    NSTextStorage *ts = [textView textStorage];
    return [ts RTFDFileWrapperFromRange: NSMakeRange(0, [ts length])
	       documentAttributes: nil];
  } else {
    return [super fileWrapperRepresentationOfType: type];
  }
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

/* Find panel */
- (void) showFindPanel: (id) sender
{
  [textFinder showFindPanel: sender]; 
}

- (void) showCharacterPanel: (id) sender
{
  [[TWCharacterPanel sharedCharacterPanel] orderFront: self];
}

@end
