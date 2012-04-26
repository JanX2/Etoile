/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/COObject.h>
#import <AddressBook/ABRecord.h>

@class ABAddressBook;
/**
@abstract Image loading protocol

ABImageClient protocol allows ABPerson to return images asynchronously. 

Framework users can implement this protocol in their own classes, then invoke 
-beginLoadingImageDataForClient: to trigger the image loading, and AddressBook
will call back -consumeImageData:forTag: once the loading is finished.<br />
At any time, +[ABPerson cancelLoadingImageDataForTag:] can be used to cancel 
an ongoing image loading. */
@protocol ABImageClient
/** Will be called once the image loading triggered by 
-[ABPerson beginLoadingImageDataForClient:] is done.

The tag corresponds to the loading request identifier returned by 
-[ABPerson beginLoadingImageDataForClient:].  */
- (void)consumeImageData: (NSData *)data forTag: (NSInteger)aTag;
@end

/** 
@group Contacts
@abstract A contact in an address book. */
@interface ABPerson : COObject <ABRecord>
{
	@private
	NSInteger loadRequestNumber;
}

/** @taskunit Initialization */

- (id)initWithAddressBook: (ABAddressBook *)aBook;
- (id)initWithVCardRepresentation: (NSData *)vCardData;
- (id)init;

/** @taskunit Basic Properties */

/** Returns the vCard data. */
- (NSData *)vCardRepresentation;
/** Sets the person image representation. */
- (BOOL)setImageData: (NSData *)data;
/** Returns the person image representation. */
- (NSData *)imageData;

/** @taskunit Image Loading */

- (NSInteger)beginLoadingImageDataForClient: (id <ABImageClient>)aClient;
+ (void)cancelLoadingImageDataForTag: (NSInteger)aTag;

@end
