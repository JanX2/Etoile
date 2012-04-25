/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import "ABPerson.h"

@implementation ABPerson

- (id)initWithAddressBook: (ABAddressBook *)aBook
{
	return self;
}

- (id)initWithVCardRepresentation: (NSData *)vCardData
{
	return self;
}

- (id)init
{
	return self;
}

- (NSData *)vCardRepresentation
{
	return nil;
}

- (BOOL)setImageData: (NSData *)data
{
	return [self setValue: data forProperty: @"imageData"];
}

- (NSData *)imageData
{
	return [self valueForProperty: @"imageData"];
}

- (NSInteger)beginLoadingImageDataForClient: (id <ABImageClient>)aClient
{
	/* For now, we simulate asynchronous loading */
	[self performSelector: @selector(finishLoadingImageDataForClient:) 
                   withObject: aClient
	           afterDelay: 0];
	return ++loadRequestNumber;
}

- (void) finishLoadingImageDataForClient: (id <ABImageClient>)aClient
{
	[aClient consumeImageData: [self imageData] forTag: loadRequestNumber];
}

+ (void)cancelLoadingImageDataForTag: (NSInteger)aTag
{

}

@end

