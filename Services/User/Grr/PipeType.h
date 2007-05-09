/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/NSObject.h>

@protocol PipeType <NSObject>
@end

@interface PipeType : NSObject <PipeType>
{
    NSString* description;
}

+ (id) pipeTypeWithDescription: (NSString*) aDescription;
- (id) initWithDescription: (NSString*) aDescription;

+ (id<PipeType>) articleType;
+ (id<PipeType>) feedType;
+ (id<PipeType>) databaseElementType;
@end
