/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>

@interface NSBundle (GrrExtensions)

/**
 * Returns the principal classes instance of the bundle with the given name.
 * If there's no bundle with this name or an error occurs, nil is returned.
 */
+(id) instanceForBundleWithName: (NSString*) name;

/**
 * Returns the principal classes instance of the bundle with the given name
 * and type (path extension). If there's no bundle with this name or an error
 * occurs, nil is returned.
 */
+(id) instanceForBundleWithName: (NSString*) name
                           type: (NSString*) type;

@end


