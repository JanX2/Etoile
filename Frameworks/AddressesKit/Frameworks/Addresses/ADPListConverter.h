// ADPListConverter.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:02 $

#ifndef ADPLISTCONVERTER_H
#define ADPLISTCONVERTER_H

/* system includes */
#include <Addresses/ADConverter.h>

/* my includes */
/* (none) */

@interface ADPListConverter: NSObject<ADInputConverting>
{
  BOOL _done;
  id _plist;
}
- initForInput;
- (BOOL) useString: (NSString*) str;
- (ADRecord*) nextRecord;
@end

#endif /* ADPLISTCONVERTER_H */
