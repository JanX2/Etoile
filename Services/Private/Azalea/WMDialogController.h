#ifndef __WM_DIALOG_CONTROLLER__
#define __WM_DIALOG_CONTROLLER__

#include <AppKit/AppKit.h>
#include "WindowMaker.h"

extern int wScreenCount;
extern WPreferences wPreferences;

@interface WMDialogController: NSObject
{
  /* info panel */
  NSPanel *aboutGNUstepPanel;
  NSPanel *legalPanel;
  NSPanel *infoPanel;

  /* icon chooser panel */
  NSPanel *chooserPanel;
  NSTextField *iconField;
  NSButton *chooserOKButton;
  NSBrowser *browser;
  NSImageView *iconView;
  NSString *iconPath;
  int chooserResponse;
  NSArray *directories;
  NSArray *icons;

  /* exit panel */
  NSPanel *exitPanel;
  NSButton *saveStateButton;
  NSTextField *exitTitle;
  NSTextField *exitMessage;
  NSButton *exitDefaultButton;
  NSButton *exitAlternateButton;
  NSButton *exitOtherButton;
  int exitResponse;

  /* input panel */
  NSPanel *inputPanel;
  NSTextField *inputTitle;
  NSTextField *inputMessage;
  NSTextField *inputField;
  int inputResponse;

  BOOL modal;

}

+ (WMDialogController *) sharedController;

/* return nil if cancelled */
- (NSString *) iconChooserDialogWithInstance: (NSString *) instance
		           class: (NSString *) class;

/* FIXME: cannot use this first */
- (int) messageDialogWithTitle: (NSString *) title
                       message: (NSString *) message
	         defaultButton: (NSString *) defaultButton
	       alternateButton: (NSString *) alternateButton
		   otherButton: (NSString *) otherButton;
		   
- (int) exitDialogWithTitle: (NSString *) title
                       message: (NSString *) message
	         defaultButton: (NSString *) defaultButton
	       alternateButton: (NSString *) alternateButton
		   otherButton: (NSString *) otherButton;
		   
- (NSString *) inputDialogWithTitle: (NSString *) title
                            message: (NSString *) message
	 		       text: (NSString *) text;

- (void) showInfoPanel: (id) sender;
- (void) showGNUstepPanel: (id) sender;
- (void) showLegalPanel: (id) sender;

@end

#endif /* __WM_DIALOG_CONTROLLER__ */
