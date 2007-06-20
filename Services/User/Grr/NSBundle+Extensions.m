/*
 * A variation of GNUMail's NSBundle extension
 * Copyright (C) 2005 Ludovic Marcotte <ludovic@Sophos.ca>
 * Copyright (C) 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
 *
 *
 * This application is free software; you can redistribute it and/or 
 * modify it under the terms of the MIT license. See COPYING.
 */

#import "NSBundle+Extensions.h"

@implementation NSBundle (GrrExtensions)

/**
 * Returns the principal classes instance of the bundle with the given name
 * If there's no bundle with this name or an error occurs, nil is returned.
 */
+(id) instanceForBundleWithName: (NSString*) name
{
    return [self instanceForBundleWithName: name type: @"grrc"];
}

/**
 * Returns the principal classes instance of the bundle with the given name
 * and type (path extension). If there's no bundle with this name or an error
 * occurs, nil is returned.
 */
+(id) instanceForBundleWithName: (NSString*) name
                           type: (NSString*) type
{
    NSString* bundlePathName;
#ifdef MACOSX
    bundlePathName =
        [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:
            [name stringByAppendingPathExtension: type]];
#else
    bundlePathName =
        [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:
            [name stringByAppendingPathExtension: type]];
#if 0
    bundlePathName = [[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent];
    bundlePathName = [bundlePathName stringByDeletingPathExtension];
    
    // We verify if we must load the bundles in the GNUstep's Local, Network or System dir.
    // FIXME: We must also be careful in case poeple are using GNUstep with --enable-flattened
    if ([bundlePathName hasSuffix: @"/Applications/Grr"]) {
        bundlePathName = [NSString stringWithFormat: @"%@/Library/Grr/%@.%@",
                          [[bundlePathName stringByDeletingLastPathComponent]
                            stringByDeletingLastPathComponent],
                          name, type];
    } else {
        // This branch is taken when Grr is started from its source directory.
        bundlePathName = [NSString stringWithFormat: @"%@/Components/%@/%@.%@",
                          [bundlePathName stringByDeletingLastPathComponent],
                          name, name, type];
    }
#endif
#endif
    
    NSLog(@"Loading bundle at %@", bundlePathName);
    
    NSBundle* bundle = [NSBundle bundleWithPath: bundlePathName];
    id pClass = [bundle principalClass];
    
    if ([pClass respondsToSelector: @selector(shared)]) {
        return [pClass shared];
    } else {
        return [pClass new];
    }
}

@end
