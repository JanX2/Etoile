/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <AppKit/AppKit.h>
#import <Foundation/NSObject.h>

@interface GNRatingCell : NSCell
{
    double rating;
    
    NSRect _currentTrackingRect;
    NSImage* star;
    NSButton* button;
}


@end
