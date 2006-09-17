// ADImageLoading.h (this is -*- ObjC -*-)
// 
// \author: Bj�rn Giesler <giesler@ira.uka.de>
// 
// Address Book API for GNUstep
// 
// $Author: bjoern $
// $Locker:  $
// $Revision: 1.1.1.1 $
// $Date: 2004/02/14 18:00:02 $

#ifndef ADIMAGELOADING_H
#define ADIMAGELOADING_H

/* system includes */
#include <Addresses/Addresses.h>

/* my includes */
/* (none) */

@protocol CImageClient<NSObject>
- (void) consumeImageData: (NSData*) data
		   forTag: (ADImageTag) tag;
@end

@interface ADPerson (ImageAdditions)
- (BOOL) setImageData: (NSData*) data;
- (NSData*) imageData;

// Following two not implemented on GNUstep
- (ADImageTag) beginLoadingImageDataForClient: (id<CImageClient>) client;
+ (void) cancelLoadingImageDataForTag: (ADImageTag) tag;
@end

#define NSIMAGEREP_BROKEN
// NOTE: The following extension WILL DISAPPEAR as soon as GNUstep's
// NSImageRep can initWithData: for data formats other than
// tiff. Right now, it can only initWithContentsOfFile:, so we have to
// keep a file around.

#ifdef NSIMAGEREP_BROKEN
@interface ADPerson (ImageAdditionsForBrokenNSImageRep)
// these require the person to be owned by an address book.
- (BOOL) setImageDataWithFile: (NSString*) filename;
- (NSString*) imageDataFile;
- (BOOL) setImageDataType: (NSString*) type;
@end
#endif

#endif /* ADIMAGELOADING_H */
