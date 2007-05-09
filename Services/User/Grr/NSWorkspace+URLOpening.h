/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/


// NSWorkspace+URLOpening is only needed in GNUstep applications, OSX supports it anyway.
#ifdef GNUSTEP

#import <AppKit/AppKit.h>

extern NSString *const RSSReaderWebBrowserDefaults;

@interface NSWorkspace (URLOpening)

-(BOOL) openURL: (NSURL*) URL;

@end

#endif
