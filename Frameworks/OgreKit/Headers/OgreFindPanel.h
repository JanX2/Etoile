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
  NSButton *findNextButton;
  NSButton *findPreviousButton;
  
  OgreFindPanelController *findPanelController;
}

+ (OgreFindPanel *) sharedFindPanel;

- (NSTextField *) findTextField;
- (void) setFindPanelController: (OgreFindPanelController *) controller;
- (OgreFindPanelController *) findPanelController;


@end
