#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

extern NSImage  *unknownApplication = nil;

@implementation NSWorkspace (theme)

- (NSImage*) _iconForExtension: (NSString*)ext
{
  NSImage	*icon = nil;
  NSBundle* bundle = [NSBundle bundleForClass: NSClassFromString(@"Theme")];

  if (ext == nil || [ext isEqualToString: @""])
    {
      return nil;
    }
  /*
   * extensions are case-insensitive - convert to lowercase.
   */
  ext = [ext lowercaseString];
  if ((icon = [_iconMap objectForKey: ext]) == nil)
    {
      NSDictionary	*prefs;
      NSDictionary	*extInfo;
      NSString		*iconPath;

      if (icon == nil && (extInfo = [self infoForExtension: ext]) != nil)
	{
	  NSString	*appName;

	 NSImage* background = [[NSImage alloc] initWithContentsOfFile: [bundle pathForImageResource: @"file_background.tiff"]];
	 NSImage* rtf = [[NSImage alloc] initWithContentsOfFile: [bundle pathForImageResource: @"ext_rtf.tiff"]];

	 [background lockFocus];
		[rtf compositeToPoint: NSMakePoint (0,0) operation: NSCompositeCopy];
		NSBitmapImageRep* resB = [[NSBitmapImageRep alloc] initWithFocusedViewRect: NSMakeRect (0,0, 48, 48)];
	 [background unlockFocus];
	 icon = [[NSImage alloc] initWithData: [resB TIFFRepresentation]];
	

	  /*
	   * If there are any application preferences given, try to use the
	   * icon for this file that is used by the preferred app.
	   */
	  /*
	  if (prefs)
	    {
	      if ((appName = [extInfo objectForKey: @"Editor"]) != nil)
		{
		  icon = [self _extIconForApp: appName info: extInfo];
		}
	      if (icon == nil
		&& (appName = [extInfo objectForKey: @"Viewer"]) != nil)
		{
		  icon = [self _extIconForApp: appName info: extInfo];
		}
	    }
	  */
	
	/*
	  if (icon == nil)
	    {
	      NSEnumerator	*enumerator;

	      //
	      // Still no icon - try all the apps that handle this file
	      // extension.
	      
	      enumerator = [extInfo keyEnumerator];
	      while (icon == nil && (appName = [enumerator nextObject]) != nil)
		{
		  icon = [self _extIconForApp: appName info: extInfo];
		}
	    } 
	*/
	}

      /*
       * Nothing found at all - use the unknowntype icon.
       */
      if (icon == nil)
	{
	  if ([ext isEqualToString: @"app"] == YES
	    || [ext isEqualToString: @"debug"] == YES
	    || [ext isEqualToString: @"profile"] == YES)
	    {
	      if (unknownApplication == nil)
		{
		  unknownApplication = RETAIN([self _getImageWithName:
		    @"UnknownApplication.tiff" alternate:
		    @"common_UnknownApplication.tiff"]);
		}
	      icon = unknownApplication;
	    }
	  else
	    {
	      icon = [self unknownFiletypeImage];
	    }
	}

      /*
       * Set the icon in the cache for next time.
       */
      if (icon != nil)
	{
	  [_iconMap setObject: icon forKey: ext];
	}
    }
  return icon;
}

@end
