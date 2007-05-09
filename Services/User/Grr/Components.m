/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "Components.h"

NSString* ComponentDidUpdateNotification = @"ComponentDidUpdateNotification";

@implementation ViewProvidingComponent

-(id) init
{
    if ((self = [super init]) != nil) {
        [_view retain]; // make sure _view is ours!
    }
    
    return self;
}

-(void)dealloc
{
    [_view release];
    [super dealloc];
}

-(NSView*) view
{
    return [[_view retain] autorelease];
}

-(void) notifyChanges
{
    [[NSNotificationCenter defaultCenter] postNotificationName: ComponentDidUpdateNotification
                                                        object: self];
}

@end
