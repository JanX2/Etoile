// ADConverter.h (this is -*- ObjC -*-)
// 
// \author: Björn Giesler <giesler@ira.uka.de>
// 
// Address Book Framework for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:01 $

#ifndef ADCONVERTER_H
#define ADCONVERTER_H

/* system includes */
#include <Foundation/Foundation.h>
#include <Addresses/ADRecord.h>

/* my includes */
/* (none) */

@protocol ADInputConverting
- initForInput;
- (BOOL) useString: (NSString*) string;
- (ADRecord*) nextRecord;
@end

@protocol ADOutputConverting
- initForOutput;
- (BOOL) canStoreMultipleRecords;
- (void) storeRecord: (ADRecord*) record;
- (NSString*) string;
@end

@interface ADConverterManager: NSObject
{
  NSMutableDictionary *_icClasses, *_ocClasses;
}

+ (ADConverterManager*) sharedManager;
- (BOOL) registerInputConverterClass: (Class) c
			     forType: (NSString*) type;
- (BOOL) registerOutputConverterClass: (Class) c
			      forType: (NSString*) type;
- (id<ADInputConverting>) inputConverterForType: (NSString*) type;
- (id<ADOutputConverting>) outputConverterForType: (NSString*) type;

/*!
  \brief Return a pre-initialized input converter for the given file

  Find a fitting converter and pre-initialize it with the date for the
  given file.
*/
- (id<ADInputConverting>) inputConverterWithFile: (NSString*) filename;

- (NSArray*) inputConvertableFileTypes;
- (NSArray*) outputConvertableFileTypes;
@end

#endif /* ADCONVERTER_H */
