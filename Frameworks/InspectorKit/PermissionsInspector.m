/*
   PermissionsInspector.m
   The permissions inspector.

   This file is part of OpenSpace.

   Copyright (C) 2005 Saso Kiselkov

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
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import <AppKit/AppKit.h>
#import "PermissionsInspector.h"
#import "PermissionsView.h"

#import <unistd.h>
#import <sys/types.h>
#import <sys/stat.h>


@interface PermissionsInspector (Private)

- (BOOL) changePermsTo: (unsigned) newPerms;

- (void) updateDisplayToMode: (unsigned) aMode;

 // update the warning about suid root executable binaries
- (void) updateWarnSuidRootExec: (unsigned) aMode;

@end

@implementation PermissionsInspector (Private)

- (BOOL) changePermsTo: (unsigned) newPerms
{
        NSMutableDictionary * fattrs;
        NSFileManager * fm = [NSFileManager defaultManager];

        fattrs = [[[fm fileAttributesAtPath: path traverseLink: YES]
          mutableCopy] autorelease];
        [fattrs setObject: [NSNumber numberWithUnsignedLong: newPerms]
                   forKey: NSFilePosixPermissions];
        if ([fm changeFileAttributes: fattrs atPath: path] == NO) {
                NSRunAlertPanel(_(@"Failed to change permissions"),
                  _(@"Couldn't change permissions for file %@: access denied."),
                  nil, nil, nil, [path lastPathComponent]);
                return NO;
        } else {
                [self updateWarnSuidRootExec: newPerms];

                return YES;
        }
}

- (void) updateDisplayToMode: (unsigned) aMode
{
        [(PermissionsView *) permsView setMode: aMode];
        [suid setState: (aMode & S_ISUID)];
        [guid setState: (aMode & S_ISGID)];
        [sticky setState: (aMode & S_ISVTX)];

        [self updateWarnSuidRootExec: aMode];
}

- (void) updateWarnSuidRootExec: (unsigned) aMode
{
        NSDictionary * fattrs = [[NSFileManager defaultManager]
          fileAttributesAtPath: path traverseLink: YES];

        if ((aMode & S_ISUID) &&
          ((aMode & S_IXOTH) || (aMode & S_IXGRP)) &&
          [[fattrs fileType] isEqualToString: NSFileTypeRegular]) {
                if ([fattrs fileOwnerAccountID] == 0)
                        [suidWarn setStringValue: _(@"Warning: SUID root executable!")];
                else
                        [suidWarn setStringValue: _(@"Warning: SUID executable!")];
        } else
                [suidWarn setStringValue: nil];
        
}

@end

@implementation PermissionsInspector

+ (NSArray *) extensions
{
        return nil;
}

- (void) dealloc
{
        NSDebugLLog(@"PermissionsInspector", @"PermissionsInspector: dealloc");

        TEST_RELEASE(view);
        TEST_RELEASE(advancedBox);
        TEST_RELEASE(path);

        [super dealloc];
}

- (void) awakeFromNib
{
        [view retain];
        [view removeFromSuperview];
        DESTROY(bogusWindow);

        [permsView setDisplaysExecute: YES];
        [permsView setTarget: self];
        [permsView setAction: @selector(permissionsChanged:)];

        [advancedBox retain];
        [advancedBox removeFromSuperview];

        [[ownerWarn enclosingScrollView] setHasVerticalScroller: NO];
        [[ownerWarn enclosingScrollView] setBorderType: NSNoBorder];
        [ownerWarn setAlignment: NSCenterTextAlignment];
        [ownerWarn setFont: [NSFont userFontOfSize: 11]];
}

- (void) revert: (id)sender
{
        [self updateDisplayToMode: oldMode];
        [revertButton setEnabled: NO];
        [okButton setEnabled: NO];
}


- (void) ok: (id)sender
{
        if ([self changePermsTo: mode]) {
                oldMode = mode;
                [okButton setEnabled: NO];
                [revertButton setEnabled: NO];
        }
}

- (NSView *) view
{
        return view;
}

- (NSString *) inspectorName
{
        return _(@"UNIX Permissions");
}

- (void) displayForPath: (NSString *) aPath
{
         // don't allow changes when we're not the owner
        if (![[[[NSFileManager defaultManager]
          fileAttributesAtPath: aPath traverseLink: YES]
          fileOwnerAccountName] isEqualToString: NSUserName()] &&
          geteuid() != 0) {
                [permsView setEditable: NO];
                [suid setEnabled: NO];
                [guid setEnabled: NO];
                [sticky setEnabled: NO];

                [ownerWarn setString:
                  _(@"Cannot change because you aren't the owner")];
                [ownerWarn setColor: [NSColor darkGrayColor]
                            ofRange: NSMakeRange(0, [[ownerWarn string] length])];
        } else {
                [permsView setEditable: YES];
                [suid setEnabled: YES];
                [guid setEnabled: YES];
                [sticky setEnabled: YES];

                [ownerWarn setString: @""];
        }

        ASSIGN(path, aPath);

        oldMode = [[[NSFileManager defaultManager]
          fileAttributesAtPath: aPath traverseLink: YES]
          filePosixPermissions];
        mode = oldMode;

        [self updateDisplayToMode: oldMode];
}

- (void) permissionsChanged: sender
{
        mode = (mode & (S_ISUID | S_ISGID | S_ISVTX)) |
          [(PermissionsView *) sender mode];

        [okButton setEnabled: YES];
        [revertButton setEnabled: YES];
}

- (void) changeSuid: sender
{
        if ([sender state] == YES) {
                mode |= S_ISUID;
        } else
                mode &= ~(S_ISUID);

        [okButton setEnabled: YES];
        [revertButton setEnabled: YES];
}

- (void) changeGuid: sender
{
        if ([sender state] == YES) {
                mode |= S_ISGID;
        } else
                mode &= ~(S_ISGID);

        [okButton setEnabled: YES];
        [revertButton setEnabled: YES];
}

- (void) changeSticky: sender
{
        if ([sender state] == YES) {
                mode |= S_ISVTX;
        } else
                mode &= ~(S_ISVTX);

        [okButton setEnabled: YES];
        [revertButton setEnabled: YES];
}

- (void) setShowAdvanced: sender
{
        if ([sender state])
                [view addSubview: advancedBox];
        else
                [advancedBox removeFromSuperview];
}

@end
