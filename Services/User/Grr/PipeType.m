/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "PipeType.h"
#import <Foundation/NSString.h>

@implementation PipeType

+ (id) pipeTypeWithDescription: (NSString*) aDescription
{
    return [[[self alloc] initWithDescription: aDescription] autorelease];
}

- (id) initWithDescription: (NSString*) aDescription
{
    if ((self = [super init]) != nil) {
        ASSIGN(description, aDescription);
    }
    
    return self;
}

+ (id<PipeType>) articleType
{
    static id<PipeType> articleType = nil;
    
    if (articleType == nil) {
        ASSIGN(articleType, [self pipeTypeWithDescription: @"article pipe type"]);
    }
    
    return articleType;
}

+ (id<PipeType>) feedType
{
    static id<PipeType> articleType = nil;
    
    if (articleType == nil) {
        ASSIGN(articleType, [self pipeTypeWithDescription: @"feed pipe type"]);
    }
    
    return articleType;
}

+ (id<PipeType>) databaseElementType
{
    static id<PipeType> databaseElementType = nil;
    
    if (databaseElementType == nil) {
        ASSIGN(databaseElementType, [self pipeTypeWithDescription: @"database element pipe type"]);
    }
    
    return databaseElementType;
}

- (NSString*) description
{
    return description;
}
@end

