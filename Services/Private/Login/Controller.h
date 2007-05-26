/* All Rights reserved */

#include <AppKit/AppKit.h>
#import "GDMClient.h"

extern NSString *ETAllowUserToChooseEnvironment;

@interface Controller : NSObject
{
  id loginTextfield;
  id passwordTextfield;
  id window;
  id loginView;
  id busyView;
  id view;
  id imageView;
  id hostnameText;
  id sessionPopUpButton;
  id sessionText;

  int busyImageCounter;

  BOOL busy;

  int waggleCount;
  int add;
  NSRect originalPosition;
  GDMClient* gdm;
}
- (void) login: (id)sender;
- (void) shutdown: (id)sender;
- (void) reboot: (id)sender;
- (void) displayHostname;
- (void) setView: (NSView*) aView;
- (void) waggle: (NSTimer*) aTimer;
@end
