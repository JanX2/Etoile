/*
   PermissionsInspector.m
   The permissions inspector.

   Copyright (C) 2005 Saso Kiselkov
                 2007 Yen-Ju Chen

   Redistribution and use in source and binary forms, with or without 
   modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright notice, 
     this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright notice, 
     this list of conditions and the following disclaimer in the documentation 
     and/or other materials provided with the distribution.
   * Neither the name of the Etoile project nor the names of its contributors 
     may be used to endorse or promote products derived from this software 
     without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
   THE POSSIBILITY OF SUCH DAMAGE.
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
