// ADImageView.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address View Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.2 $
// $Date: 2004/06/14 05:48:08 $

#ifndef ADIMAGEVIEW_H
#define ADIMAGEVIEW_H

/* system includes */
#include <Addresses/Addresses.h>
#include <AppKit/AppKit.h>

/* my includes */
/* (none) */

@interface ADImageView: NSImageView
{
  id __target;
  SEL _selector;
  id _delegate;
  ADPerson *_person;
  BOOL _mouseDownOnSelf, _mouseDragged;
}
- initWithFrame: (NSRect) frame;
- (void) setTarget: (id) target;
- (void) setAction: (SEL) sel;
- (void) mouseDown: (NSEvent*) event;
- (void) mouseUp: (NSEvent*) event;
- (void) mouseDragged: (NSEvent*) event;
- (BOOL) hasEditableCells;
- (void) setDelegate: (id) delegate;
- (id) delegate;

- (void) setPerson: (ADPerson*) person;
- (ADPerson*) person;
@end

@interface NSObject (ADImageViewDelegate)
- (BOOL) imageView: (ADImageView*) view
     willDragImage: (NSImage*) image;
- (BOOL) imageView: (ADImageView*) view
    willDragPerson: (ADPerson*) aPerson;
- (NSImage*) draggingImage;
@end

#endif /* ADIMAGEVIEW_H */
