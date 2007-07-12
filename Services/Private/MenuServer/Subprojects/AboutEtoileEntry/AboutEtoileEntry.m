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
#import "ETMachineInfo.h"

static NSString * const EtoileVersion = @"0.2";

@interface AboutEtoileEntry (Private)

- (void) fillInfoPanelWithSystemInfo;
- (void) fillInfoPanelWithMachineInfo;

@end

@implementation AboutEtoileEntry (Private)

- (void) fillInfoPanelWithSystemInfo
{
  [etoileVersion setStringValue: EtoileVersion];

  [hostName setStringValue: [ETMachineInfo hostName]];
  [operatingSystem setStringValue: [ETMachineInfo operatingSystem]];
  [kernelVersion setStringValue: [ETMachineInfo operatingSystemVersion]];
}

- (void) fillInfoPanelWithMachineInfo
{
  [cpu setStringValue: [ETMachineInfo tidyCPUName]];
  [cpuFreq setStringValue: [ETMachineInfo humanReadableCPUSpeed]];
  [memory setStringValue: [ETMachineInfo humanReadableRealMemory]];
  [machine setStringValue: [ETMachineInfo machineType]];
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
