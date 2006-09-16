/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "Delegate.h"
#include <OgreKit/OgreTextFinder.h>

@implementation Delegate

- (void) awakeFromNib
{
  textView = [scrollView documentView];
  textFinder = [OgreTextFinder sharedTextFinder];
  [textView setRichText: NO]; /* Use Plain text adaptor */

  [textFinder setTargetToFindIn: textView];
}

- (void) findPanelAction: (id)sender
{
  [textFinder showFindPanel: sender]; 
}

@end
