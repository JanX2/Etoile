/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>
//TODO: Replace this with some conditional compilation for finding the correct
//DCE-compliant UUID header
#include <UUID/uuid_dce.h>

@interface COUUID : NSObject {
	uuid_t uuid;
}
- (uuid_t*) uuid;
@end

#define COUUIDSize (36 * sizeof(char))

@interface NSString (COUUID)

+ (NSString *) UUIDString;
@end
