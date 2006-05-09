/*
    AboutEtoileEntry.m

    Implementation of the AboutEtoileEntry class for the
    EtoileMenuServer application.

    Copyright (C) 2005, 2006  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "AboutEtoileEntry.h"

#import <sys/utsname.h>
#import <errno.h>
#import <string.h>

#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSHost.h>

#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSPanel.h>

#import "ScrollingImageView.h"

#import "OSType.h"

#if defined( FREEBSD )
#  include <sys/types.h>
#  include <sys/sysctl.h>	// sysctl(3)
#endif // FREEBSD

static NSString * const EtoileVersion = @"0.1";

#define ONE_KB	1024.
#define ONE_MB	(ONE_KB * ONE_KB)	//     1,048,576
#define ONE_GB	(ONE_KB * ONE_MB)	// 1,073,741,824

@interface AboutEtoileEntry (Private)

- (void) fillInfoPanelWithSystemInfo;
- (void) fillInfoPanelWithMachineInfo;

@end

@implementation AboutEtoileEntry (Private)

// Returns memory, file, or whatever _size_ in a more human readable form
NSString *sizeDescription(double aSize)
{
  double value = aSize;
  char sign = 0;
  
  if( 0. > value )
  {
    value *= -1;
  }
  
  if( (0. == value) || (1. == value) )
  {
    return [NSString stringWithFormat: @"%#3.2f byte", aSize];
  }
  else if( (10. * ONE_KB) > value )
  {
    return [NSString stringWithFormat:@"%#3.2f B", aSize];
  }
  else if( (100. * ONE_KB) > value )
  {
    sign = 'K';
    value = (aSize / ONE_KB);
  }
  else if( (1000. * ONE_MB) > value )
  {
    sign = 'M';
    value = (aSize / ONE_MB);
  }
  else
  {
    sign = 'G';
    value = (aSize / (ONE_GB));
  }
  
  return [NSString stringWithFormat: @"%#3.2f %cB", value, sign];
}

- (void) fillInfoPanelWithSystemInfo
{
  struct utsname systemInfo;

  [etoileVersion setStringValue: EtoileVersion];

  if (uname(&systemInfo) == -1)
    {
      NSRunAlertPanel(_(@"Error getting system info"),
        _(@"Error getting system info: %s"), nil, nil, nil, strerror(errno));

        return;
    }

  [hostName setStringValue: [[NSHost currentHost] name]];
  [operatingSystem setStringValue: [NSString stringWithCString:
    systemInfo.sysname]];
  [kernelVersion setStringValue: [NSString stringWithCString:
    systemInfo.release]];
  [machine setStringValue: [NSString stringWithCString: systemInfo.machine]];
}

- (void) fillInfoPanelWithMachineInfo
{
#ifdef LINUX
  // read /proc/cpuinfo for the processor type
  NSEnumerator * e = [[[NSString stringWithContentsOfFile:
    @"/proc/cpuinfo"] componentsSeparatedByString: @"\n"]
    objectEnumerator];
  NSString * line;

  while ((line = [e nextObject]) != nil)
    {
      if ([line rangeOfString: @"model name"].location != NSNotFound)
        {
          NSArray * comps = [line componentsSeparatedByString: @":"];

          if ([comps count] != 2)
            {
              continue;
            }

          [cpu setStringValue: [[comps objectAtIndex: 1]
            stringByTrimmingSpaces]];
        }
      else if ([line rangeOfString: @"cpu MHz"].location != NSNotFound)
        {
           NSArray * comps = [line componentsSeparatedByString: @":"];
           unsigned speed;

           if ([comps count] != 2)
             {
               continue;
             }

           speed = [[comps objectAtIndex: 1] intValue];
           if (speed > 1000)
             {
               [cpuFreq setStringValue: [NSString
                 stringWithFormat: @"%.2f GHz", (float) speed / 1000]];
             }
           else
             {
               [cpuFreq setStringValue: [NSString
                 stringWithFormat: @"%d MHz", speed]];
             }
        }
    }

  // and /proc/meminfo for memory info
  e = [[[NSString stringWithContentsOfFile:
    @"/proc/meminfo"] componentsSeparatedByString: @"\n"] objectEnumerator];
  while ((line = [e nextObject]) != nil)
    {
      if ([line rangeOfString: @"MemTotal"].location != NSNotFound)
        {
          NSArray * comps = [line componentsSeparatedByString: @":"];
          unsigned size;

          if ([comps count] != 2)
            {
              continue;
            }

          size = [[comps objectAtIndex: 1] intValue];
          if (size > 1024 * 1024)
            {
              // round this value
              [memory setStringValue: [NSString stringWithFormat: @"%.2f GB",
                (float) size / (1024 * 1024)]];
            }
          else
            {
              [memory setStringValue: [NSString stringWithFormat: @"%d MB",
                size / 1024]];
            }

          break;
        }
    }
#elif defined( FREEBSD )

  int mib[2];
  size_t len;
  char *p;
  
  // machine architecture, eg: i386
  {
    mib[0] = CTL_HW;
    mib[1] = HW_MODEL;
    
    if( sysctl(mib, 2, NULL, &len, NULL, 0) ) perror("sysctl");
    p = malloc(len);
    if( sysctl(mib, 2, p, &len, NULL, 0) ) perror("sysctl");
    
    [machine setStringValue: [NSString stringWithCString: p]];
  }
  free(p);
  
  // machine model, eg. "Intel(R) Celeron(R) CPU"
  {
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE_ARCH;
    
    if( sysctl(mib, 2, NULL, &len, NULL, 0) ) perror("sysctl");
    p = malloc(len);
    if( sysctl(mib, 2, p, &len, NULL, 0) ) perror("sysctl");
    
    [cpu setStringValue: [NSString stringWithCString: p]];
  }
  free(p);
  
  // cpu frequency
  {
    long mhz;
    
    len = sizeof(mhz);
    
    mhz = 1;
    if( sysctlbyname("hw.clockrate", NULL, &len, NULL, 0) ) perror("sysctl");
    if( sysctlbyname("hw.clockrate", &mhz, &len, NULL, 0) ) perror("sysctl");
    
    [cpuFreq setStringValue: [NSString stringWithFormat:	// I'm lazy...
      ( ( mhz > 1000 ) ? @"%.2f GHz" : @"%d MHz" ), 		//   format
      ( ( mhz > 1000 ) ? (float) mhz / 1000 : mhz )]];		//   value
  }
  
  // total memory
  {
    unsigned int mem = 0;
    
    len = sizeof mem;
    
    mib[0] = CTL_HW;
    mib[1] = HW_REALMEM;
    
    mem = 1;
    if( 0 != sysctl(mib, 2, NULL, &len, NULL, 0) ) perror("sysctl");
    if( 0 != sysctl(mib, 2, &mem, &len, NULL, 0) ) perror("sysctl");
    
    [memory setStringValue: sizeDescription((double)mem)];
  }
#else // ! Linux && ! FreeBSD
#  warning System not yet supported!
#endif

}

@end

@implementation AboutEtoileEntry

- (id <NSMenuItem>) menuItem
{
  NSMenuItem * menuItem;

  menuItem = [[[NSMenuItem alloc]
    initWithTitle: _(@"About Étoilé...")
           action: @selector(activate)
    keyEquivalent: nil]
    autorelease];

  [menuItem setTarget: self];

  return menuItem;
}

- (void) awakeFromNib
{
  NSBundle * bundle;
  NSData * rtfData;

  [self fillInfoPanelWithSystemInfo];
  [self fillInfoPanelWithMachineInfo];

  bundle = [NSBundle bundleForClass: [self class]];
  [image setScrolledImage: [[[NSImage alloc]
    initByReferencingFile: [bundle pathForResource: @"Credits" ofType: @"tiff"]]
    autorelease]];

  rtfData = [NSData dataWithContentsOfFile:
    [bundle pathForResource: @"Credits" ofType: @"rtf"]];
  [image setScrolledRTF: rtfData];
}

- (NSString *) menuGroup
{
  return @"Etoile";
}

- (void) activate
{
  if (window == nil)
    {
      [NSBundle loadNibNamed: @"AboutEtoileEntry" owner: self];

      [window center];
    }

  [window makeKeyAndOrderFront: nil];
}

@end
