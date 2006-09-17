/* Yen-Ju Chen <yjchenx @ gmail com> 
 * BSD Licence ( or OgreKit License)
 */

#import <AppKit/AppKit.h>

@class OgreFindPanelController;

/* Standard find panel */
@interface OgreFindPanel: NSPanel
{
  NSTextField *findTextLabel;
  NSTextField *findTextField;
  NSTextField *replaceTextLabel;
  NSTextField *replaceTextField;

  NSButton *regexButton;
  NSButton *caseSensitiveButton;
  NSButton *findNextButton;
  NSButton *findPreviousButton;
  NSButton *replaceButton;
  
  OgreFindPanelController *findPanelController;
}

+ (OgreFindPanel *) sharedFindPanel;

- (NSTextField *) findTextField;
- (NSTextField *) replaceTextField;

- (void) setFindPanelController: (OgreFindPanelController *) controller;
- (OgreFindPanelController *) findPanelController;


@end
