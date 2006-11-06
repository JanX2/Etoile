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
//#import "ErrorLogController.h"

@implementation NSWorkspace (OpenURL)

/*
 * GNUstep currently doesn't support http URL opening.
 */
-(BOOL) openURL: (NSURL*) url
{
  BOOL result;
  
  NS_DURING
    {
      if ([url isFileURL])
	{
	  result = [self openFile: [url path]];
	}
      else if ([[url description] hasPrefix: @"http://"] ||
	       [[url description] hasPrefix: @"https://"])
	{
	  NSTask* browser;
	  NSString* browserPath;
	  
	  browserPath =
	    [[NSUserDefaults standardUserDefaults] stringForKey: @"WebBrowser"];
	  
	  if (browserPath != nil)
	    {
	      browser =
		[NSTask launchedTaskWithLaunchPath: browserPath
			arguments: [NSArray arrayWithObject: [url description] ] ];
	      result = YES;
	    }
	  else
	    {
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
#if 0
      [[ErrorLogController instance]
	logString: [NSString stringWithFormat: @"Cannot execute browser %@, "
			     @"please check the preferences!\n", url]];
      
#endif
      result = NO;
    }
  NS_ENDHANDLER;
  
  return result;
}

@end

