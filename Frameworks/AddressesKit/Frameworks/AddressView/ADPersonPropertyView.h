// ADPersonPropertyView.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Application for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:01 $

#ifndef ADPERSONPROPERTYVIEW_H
#define ADPERSONPROPERTYVIEW_H

/* system includes */
#include <AppKit/AppKit.h>
#include <Addresses/Addresses.h>

/* my includes */
/* (none) */

@interface NSString(ADPersonPropertySupport)
- (NSString*) stringByAbbreviatingToFitWidth: (int) width
				      inFont: (NSFont*) font;
- (NSString*) stringByTrimmingWhitespace;
- (BOOL) isEmptyString;
@end

@interface ADPersonPropertyCell: NSTextFieldCell
{
  NSRect _r;
  id _details;
}
- (void) setRect: (NSRect) r;
- (NSRect) rect;

- (void) setDetails: (id) details;
- (id) details;
@end

typedef enum {
  ADAddAction = 0,
  ADRemoveAction = 1,
  ADChangeAction = 2
} ADActionType;

@interface ADPersonActionCell: NSImageCell
{
  NSPoint _origin;
  id _details;
  ADActionType _type;
}
- (void) setActionType: (ADActionType) type;
- (ADActionType) actionType;

- (void) setOrigin: (NSPoint) origin;
- (NSRect) rect;

- (void) setDetails: (id) details;
- (id) details;
@end

@interface ADPersonPropertyView: NSView
{
  ADPerson *_person;
  NSString *_property;
  NSMutableArray *_cells; 
  BOOL _displaysLabel;
  int _maxLabelWidth, _neededLabelWidth;
  float _fontSize;
  NSFont *_font; BOOL _fontSetExternally;

  BOOL _editable;
  int _editingCellIndex; id _textObject;
  id _delegate;

  SEL _clickSel, _changeSel, _canPerformSel, _widthSel, _editInNextSel;

  NSSize _requiredSize;

  NSImage *_addImg, *_rmvImg, *_chgImg;

  NSDictionary *_labelDict;

  BOOL _mouseDownOnSelf;
  NSString *_propertyForDrag; id _mouseDownCell;
}

+ (NSFont*) font;
+ (NSFont*) boldFont;
+ (float) fontSize;
+ (void) setFontSize: (float) size;

- (void) setDelegate: (id) delegate;
- (id) delegate;

- (void) setPerson: (ADPerson*) person;
- (ADPerson*) person;

- (void) setProperty: (NSString*) property;
- (NSString*) property;

- (void) setDisplaysLabel: (BOOL) yesno;
- (BOOL) displaysLabel;

- (void) setMaxLabelWidth: (int) width;
- (int) maxLabelWidth;
- (int) neededLabelWidth;

- (NSFont*) font;
- (void) setFont: (NSFont*) font;
- (NSFont*) boldFont;
- (float) fontSize;
- (void) setFontSize: (float) size;

- (void) setEditable: (BOOL) editable;
- (BOOL) isEditable;

- (BOOL) hasEditableCells;
- (BOOL) hasCells;
- (void) beginEditingInFirstCell;
- (void) beginEditingInLastCell;
- (void) endEditing;

- (int) indexOfEditableCellWithDetails: (id) details;

- (NSString*) propertyForDragWithDetails: (id) details;
- (NSImage*) imageForDraggedProperty: (NSString*) prop;
@end

@interface ADPersonPropertyView (LabelMangling)
- (NSString*) nextLabelAfter: (NSString*) previous;
- (NSString*) defaultLabel;
- (id) emptyValue;
- (NSArray*) layoutRuleForValue: (NSDictionary*) dict;
@end

@protocol ADPersonPropertyViewDelegate
- (void) viewWillBeginEditing: (id) view; // must implement this
- (BOOL) canPerformClickForProperty: (id) property;
- (void) clickedOnProperty: (id) value
		 withValue: (id) property
		    inView: (id) sender;
- (void) valueForProperty: (id) property
	   changedToValue: (id) value
		   inView: (id) sender;
- (void) view: (id) view
changedWidthFrom: (float) oldW
	   to: (float) newW;
- (void) view: (id) view
changedHeightFrom: (float) oldH
	   to: (float) newH;
- (void) beginEditingInNextViewWithTextMovement: (int) textMovement;

- (BOOL) personPropertyView: (ADPersonPropertyView*) view
	      willDragValue: (NSString*) value
		forProperty: (NSString*) aProperty;
- (BOOL) personPropertyView: (ADPersonPropertyView*) view
	     willDragPerson: (ADPerson*) aPerson;

- (NSImage*) draggingImage;
@end

@interface ADPersonPropertyView (Private)
- (ADPersonPropertyCell*) addCellWithValue: (NSString*) val
				    inRect: (NSRect*) rect
				  editable: (BOOL) yesno
				      font: (NSFont*) font
				 alignment: (NSTextAlignment) alignment
				   details: (id) details;
- (ADPersonPropertyCell*) addValueCellForValue: (NSString*) val
					inRect: (NSRect*) rect
				       details: (id) details;
- (ADPersonPropertyCell*) addValueCellForValue: (NSString*) val
					inRect: (NSRect*) rect;
- (ADPersonPropertyCell*) addLabelCellForLabel: (NSString*) label
					inRect: (NSRect*) rect;
- (void) layout;
@end

@interface ADPersonPropertyView (Events)
- (void) beginEditingInCellAtIndex: (int) i
		    becauseOfEvent: (NSEvent*) e;
- (void) beginEditingInCellWithDetails: (id) details
			becauseOfEvent: (NSEvent*) e;
@end

#endif /* ADPERSONPROPERTYVIEW_H */
