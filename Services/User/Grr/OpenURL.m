/*
   Project: RSSReader

   Copyright (C) 2006 Yen-Ju Chen 
   Copyright (C) 2005 Guenther Noack 

   Author: Yen-Ju Chen
   Author: Guenther Noack,,,

   Created: 2005-03-26 08:52:28 +0100 by guenther

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "OpenURL.h"
#import "Global.h"

/* Cache browser */
static NSString *backupBrowserPath;

@implementation NSWorkspace (OpenURL)

/*
 * GNUstep currently doesn't support http URL opening.
 */
-(BOOL) openURL: (NSURL*) url
{
  BOOL result;
  NSString *browserPath = nil;
  
  NS_DURING
  {
    if ([url isFileURL])
    {
      result = [self openFile: [url path]];
    }
    else if ([[url scheme] isEqualToString: @"http"] ||
             [[url scheme] isEqualToString: @"https"])
    {
      ASSIGN(browserPath,
          [[NSUserDefaults standardUserDefaults] stringForKey: RSSReaderWebBrowserDefaults]);

      if (browserPath == nil) {
        if (backupBrowserPath == nil) {
          /* Try firefox */
          NSFileManager *fm = [NSFileManager defaultManager];
          NSProcessInfo *pi = [NSProcessInfo processInfo];
          NSEnumerator *e = [[[[pi environment] objectForKey: @"PATH"] 
                     componentsSeparatedByString: @":"] objectEnumerator];
          NSString *p;
          while ((p = [e nextObject])) {
            p = [p stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            p = [p stringByAppendingPathComponent: @"firefox"];
            if ([fm fileExistsAtPath: p]) {
              ASSIGN(backupBrowserPath, p);
              NSLog(@"Found browser %@", backupBrowserPath);
              break;
            }
          }
        }
        ASSIGN(browserPath, backupBrowserPath);
      }
	  
      if (browserPath != nil) {
        [NSTask launchedTaskWithLaunchPath: browserPath
		arguments: [NSArray arrayWithObject: [url absoluteString]]];
        result = YES;
      } else {
	result = NO;
      }
    }
    else
    {
      result = NO;
    }
  }
  NS_HANDLER
  {
     NSString *s =  [NSString stringWithFormat: @"Cannot execute browser %@, "
			     @"please check the preferences!\n", url];
      
    [[NSNotificationCenter defaultCenter]
               postNotificationName: RSSReaderLogNotification
               object: s]; 

    result = NO;
  }
  NS_ENDHANDLER;
  
  return result;
}

@end

