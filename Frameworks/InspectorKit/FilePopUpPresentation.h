#import <PaneKit/PaneKit.h>

extern const NSString *FilePopUpPresentationMode;

@interface FilePopUpButtonPresentation : PKPopUpButtonPresentation
{
  NSImageView *iconView;
  NSTextField *nameField;
  NSTextField *pathField;

  NSString *path;
}

- (void) setFilePath: (NSString *) path;
- (NSString *) filePath;

@end

