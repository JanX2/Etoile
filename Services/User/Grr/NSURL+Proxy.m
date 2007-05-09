/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "NSURL+Proxy.h"
#import <Foundation/NSUserDefaults.h>

@implementation NSURL (Proxy)
-(void) applyProxySettings
{
#ifdef GNUSTEP
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL proxyEnabled = [defaults boolForKey: @"ProxyEnabled"];
    NSString* proxyPort = [defaults stringForKey: @"ProxyPort"];
    NSString* proxyHostname = [defaults stringForKey: @"ProxyHostname"];
    
    if (proxyEnabled == YES) {
        [self setProperty: proxyHostname forKey: GSHTTPPropertyProxyHostKey];
        [self setProperty: proxyPort forKey: GSHTTPPropertyProxyPortKey];
    }
#endif //GNUSTEP
    // FIXME: Find out how proxies on MacOSX work!
}
@end
