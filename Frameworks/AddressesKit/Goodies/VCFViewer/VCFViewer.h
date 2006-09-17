// VCFViewer.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// VCF Content Viewer for GWorkspace
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:03 $

#ifndef VCFVIEWER_H
#define VCFVIEWER_H

/* system includes */
#include <Foundation/Foundation.h>
#include <GWorkspace/ContentViewersProtocol.h>
#include <Addresses/Addresses.h>
#include <AddressView/ADPersonView.h>

/* my includes */
/* (none) */

@interface VCFViewer: NSView <ContentViewersProtocol>
{
  id panel;
  NSArray *people; int currentPerson;

  NSScrollView *sv; NSClipView *cv; ADPersonView *pv;
  NSButton *nb, *pb; NSTextField *lbl;
  NSButton *ifb, *dfb;

  NSString *bundlePath;

  int index;
}

- (void) nextPerson: (id) sender;
- (void) previousPerson: (id) sender;

- (void) increaseFontSize: (id) sender;
- (void) decreaseFontSize: (id) sender;
@end

#endif /* VCFVIEWER_H */
