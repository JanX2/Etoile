/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "NSWorkspace+URLOpening.h"

#ifdef GNUSTEP

NSString *const RSSReaderWebBrowserDefaults = @"WebBrowser";

@implementation NSWorkspace (URLOpening)

-(BOOL) openURL: (NSURL*) URL
{
    BOOL result = YES;
    NSString* browserPath = nil;
    
    NS_DURING
    {
        if ([URL isFileURL]) {
            result = [self openFile: [URL path]];
        } else if ([[URL scheme] isEqualToString: @"http"] ||
                   [[URL scheme] isEqualToString: @"https"]) {
            browserPath = [[NSUserDefaults standardUserDefaults] stringForKey:
                RSSReaderWebBrowserDefaults
            ];
            
            NSAssert(browserPath != nil, @"Browser path");
            
            [NSTask launchedTaskWithLaunchPath: browserPath
                arguments: [NSArray arrayWithObject: [URL absoluteString]]];
        }
    }
    NS_HANDLER
    {
        NSRunAlertPanel(
            NSLocalizedString(@"Browsing failed", @"header of the failure alert message"),
            [NSString stringWithFormat:
                NSLocalizedString(
                    @"Unable to open this URL:\n%@\n\nPlease check your Grr web browser preferences.",
                    @"The failure alert message text when a URL can't be opened."
                ), URL],
            _(@"Ok"), nil, nil
        );
        result = NO;
    }
    NS_ENDHANDLER
    
    return result;
}

@end

#else // not on GNUSTEP
#warning NSWorkspace+URLOpening is not needed outside GNUstep, please remove it from your project.
#endif
