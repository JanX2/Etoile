// ADVCFConverter.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:02 $

#ifndef ADVCFCONVERTER_H
#define ADVCFCONVERTER_H

/* system includes */
#include <Addresses/ADConverter.h>

/* my includes */
/* (none) */

@interface ADVCFConverter: NSObject<ADInputConverting,ADOutputConverting>
{
  NSString *_str;
  NSMutableString *_out;
  BOOL _input;
  int _idx;
}

/* ADInputConverting */
- initForInput;
- (BOOL) useString: (NSString*) str;
- (ADRecord*) nextRecord;

/* ADOutputConverting */
- initForOutput;
- (BOOL) canStoreMultipleRecords;
- (void) storeRecord: (ADRecord*) record;
- (NSString*) string;
@end

#endif /* ADVCFCONVERTER_H */
