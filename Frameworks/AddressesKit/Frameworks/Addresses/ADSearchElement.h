// ADSearchElement.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:02 $

#ifndef ADSEARCHELEMENT_H
#define ADSEARCHELEMENT_H

/* system includes */
#include <Foundation/Foundation.h>
#include <Addresses/ADRecord.h>
#include <Addresses/ADTypedefs.h>
#include <Addresses/ADGlobals.h>

/* my includes */
/* (none) */

@interface ADSearchElement: NSObject
+ (ADSearchElement*) searchElementForConjunction: (ADSearchConjunction) conj
					children: (NSArray*) children;
- (BOOL) matchesRecord: (ADRecord*) record;
@end

@interface ADRecordSearchElement: ADSearchElement // EXTENSION
{
  NSString *_property, *_label, *_key;
  id _val;
  ADSearchComparison _comp;
}

- initWithProperty: (NSString*) property
	     label: (NSString*) label
	       key: (NSString*) key
	     value: (id) value
	comparison: (ADSearchComparison) comparison;
- (void) dealloc;
- (BOOL) matchesValue: (id) value;
- (BOOL) matchesRecord: (ADRecord*) record;
@end

#endif /* ADSEARCHELEMENT_H */
