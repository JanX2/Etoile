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

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSHost.h>

#import <AppKit/NSNibLoading.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSPanel.h>

#import "OSType.h"

static NSString * const EtoileVersion = @"0.1";

@interface AboutEtoileEntry (Private)

- (void) fillInfoPanelWithSystemInfo;
- (void) fillInfoPanelWithMachineInfo;

@end

@implementation AboutEtoileEntry (Private)

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
#endif // LINUX
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
  [self fillInfoPanelWithSystemInfo];
  [self fillInfoPanelWithMachineInfo];
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
