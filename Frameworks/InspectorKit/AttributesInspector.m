/*
   AttributesInspector.m
   The attributes inspector.

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
#import "AttributesInspector.h"

#import <OpenSpaceWidgets/OpenSpaceWidgets.h>

#import <sys/types.h>
#import <grp.h>
#import <pwd.h>
#import <unistd.h>

#import "PermissionsView.h"

//#ifdef Linux
//#import <sys/capability.h>
//#endif

@interface AttributesInspector (Private)

- (NSString *) stringFromSize: (unsigned long long) filesize;

 // find all user accounts on this machine
- (void) locateUsers;
 // find all groups on this machine + mark all that we're a member of
- (void) locateGroups;

- (void) updateOwner: (NSDictionary *) fileAttributes;
- (void) updateGroup: (NSDictionary *) fileAttributes;

@end

@implementation AttributesInspector (Private)

- (NSString *) stringFromSize: (unsigned long long) filesize
{
        if (filesize < 5 * 1024)
                return [NSString stringWithFormat: _(@"%u Bytes"),
                  (unsigned int) filesize];
        else if (filesize < 1024 * 1024)
                return [NSString stringWithFormat: _(@"%.2f KB"),
                  (float) filesize / 1024];
        else if (filesize < ((unsigned long long) 1024 * 1024 * 1024))
                return [NSString stringWithFormat: _(@"%.2f MB"),
                  (float) filesize / (1024 * 1024)];
        else
                return [NSString stringWithFormat: _(@"%.3f GB"),
                  (float) filesize / (1024 * 1024 * 1024)];
}

- (void) locateUsers
{
        struct passwd * pwd;
        NSMutableDictionary * usrs = [NSMutableDictionary dictionary];

        while ((pwd = getpwent()) != NULL)
                [usrs setObject: [NSNumber numberWithInt: pwd->pw_uid]
                         forKey: [NSString stringWithCString: pwd->pw_name]];

        users = [usrs copy];
}

- (void) locateGroups
{
        NSString * userName = NSUserName();
        struct group * groupEntry;
        NSMutableDictionary * allGrs = [NSMutableDictionary dictionary],
                            * myGrs = [NSMutableDictionary dictionary];

        while ((groupEntry = getgrent()) != NULL) {
                char * member;
                unsigned i;
                NSNumber * gid = [NSNumber numberWithInt: groupEntry->gr_gid];
                NSString * gname = [NSString stringWithCString:
                  groupEntry->gr_name];

                [allGrs setObject: gid forKey: gname];

                for (i=0; (member = groupEntry->gr_mem[i]) != NULL; i++) {
                        if ([userName isEqualToString: [NSString
                          stringWithCString: member]]) {
                                [myGrs setObject: gid forKey: gname];
                                break;
                        }
                }
        }

         // add our own group
        groupEntry = getgrgid(getegid());
        [myGrs setObject: [NSNumber numberWithInt: groupEntry->gr_gid]
                  forKey: [NSString stringWithCString: groupEntry->gr_name]];

        groups = [allGrs copy];
        myGroups = [myGrs copy];
}

- (void) updateOwner: (NSDictionary *) fileAttributes
{
        [fileOwner removeAllItems];

#ifdef Linux
         // TODO - under Linux determine this using Linux Capabilities
        if (geteuid() == 0)
#else
        if (geteuid() == 0)
#endif
        {
                if (users == nil)
                        [self locateUsers];

                [fileOwner addItemsWithTitles: [[users allKeys]
                  sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];
                [fileOwner setEnabled: YES];
        } else {
                [fileOwner addItemWithTitle: [fileAttributes
                  fileOwnerAccountName]];
                [fileOwner setEnabled: NO];
        }
        [fileOwner selectItemWithTitle: [fileAttributes fileOwnerAccountName]];
}

- (void) updateGroup: (NSDictionary *) fileAttributes
{
        [fileGroup removeAllItems];

#ifdef Linux
         // TODO - under Linux determine this using Linux Capabilities
        if (geteuid() == 0)
#else
        if (geteuid() == 0)
#endif
        {
                if (groups == nil)
                        [self locateGroups];

                [fileGroup addItemsWithTitles: [[groups allKeys]
                  sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];
                [fileGroup setEnabled: YES];
        } else if ([[fileAttributes fileOwnerAccountName] isEqual: NSUserName()]) {
                if (myGroups == nil)
                        [self locateGroups];

                [fileGroup addItemsWithTitles: [[myGroups allKeys]
                  sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];
                [fileGroup setEnabled: YES];
        } else {
                [fileGroup addItemWithTitle: [fileAttributes
                  fileGroupOwnerAccountName]];
                [fileGroup setEnabled: NO];
        }

        [fileGroup selectItemWithTitle: [fileAttributes
          fileGroupOwnerAccountName]];
}

@end

@implementation AttributesInspector

+ (NSArray *) extensions
{
        return nil;
}

- (void) dealloc
{
        NSDebugLLog(@"AttributesInspector", @"AttributesInspector: dealloc");

        TEST_RELEASE(path);

        TEST_RELEASE(users);
        TEST_RELEASE(groups);
        TEST_RELEASE(myGroups);

        TEST_RELEASE(user);
        TEST_RELEASE(group);

        TEST_RELEASE(box);

        [super dealloc];
}

- (void) changeOwner: sender
{
        ASSIGN(user, [sender titleOfSelectedItem]);

        [okButton setEnabled: YES];
        [revertButton setEnabled: YES];
}

- (void) changeGroup: (id)sender
{
        ASSIGN(group, [sender titleOfSelectedItem]);

        [okButton setEnabled: YES];
        [revertButton setEnabled: YES];
}


- (void) computeSize: (id)sender
{
        unsigned long long totalSize = 0;
        NSDirectoryEnumerator * de = [[NSFileManager defaultManager]
          enumeratorAtPath: path];
        NSDictionary * fattrs;

        while ([de nextObject] != nil && (fattrs = [de fileAttributes]) != nil)
                totalSize += [fattrs fileSize];

        [fileSize setStringValue: [self stringFromSize: totalSize]];
        [computeSizeBtn setImage: [NSImage imageNamed: @"ComputeSize_dimm"]];
        [computeSizeBtn setEnabled: NO];
}

- (void) awakeFromNib
{
        [box retain];
        [box removeFromSuperview];
        DESTROY(bogusWindow);

        [fileGroup removeAllItems];
        [perms setTarget: self];
        [perms setAction: @selector(changePerms:)];

        [date setShowsYear: YES];
}

- (NSString *) inspectorName
{
        return _(@"Attributes Inspector");
}

- (void) displayForPath: (NSString *) aPath
{
        NSCalendarDate * modDate;
        NSDictionary * fattrs;
        NSFileManager * fm = [NSFileManager defaultManager];
        NSString * fType;

        ASSIGN(path, aPath);

        DESTROY(user);
        DESTROY(group);
        modeChanged = NO;

        [okButton setEnabled: NO];
        [revertButton setEnabled: NO];

        fattrs = [fm fileAttributesAtPath: path traverseLink: YES];

        modDate = [[fattrs fileModificationDate]
          dateWithCalendarFormat: nil timeZone: [NSTimeZone localTimeZone]];

        [date setCalendarDate: modDate];

        [linkTo setStringValue: [fm pathContentOfSymbolicLinkAtPath: path]];
        [self updateOwner: fattrs];
        [self updateGroup: fattrs];

        [computeSizeBtn setImage: [NSImage imageNamed: @"ComputeSize_dimm"]];
        [computeSizeBtn setEnabled: NO];

        fType = [fattrs fileType];
        if ([fType isEqualToString: NSFileTypeDirectory]) {
                [computeSizeBtn setImage: [NSImage imageNamed: @"ComputeSize"]];
                [computeSizeBtn setEnabled: YES];
                [fileSize setStringValue: nil];
        } else {
                unsigned long long fSize = [fattrs fileSize];

                [fileSize setStringValue: [self stringFromSize: [fattrs fileSize]]];
        }

        oldMode = mode = [fattrs filePosixPermissions];
        [(PermissionsView *) perms setMode: mode];
        if (![[fattrs fileOwnerAccountName] isEqualToString: NSUserName()] &&
            geteuid() != 0)
                [perms setEditable: NO];
        else
                [perms setEditable: YES];
}

- (NSView *) view
{
        return box;
}

- (void) ok: sender
{
        NSFileManager * fm = [NSFileManager defaultManager];
        NSMutableDictionary * fattrs = [[[fm
          fileAttributesAtPath: path traverseLink: YES]
          mutableCopy]
          autorelease];
        int uid, gid;

        if (user)
                uid = [[users objectForKey: user] intValue];
        else
                uid = -1;
        if (group)
                gid = [[groups objectForKey: group] intValue];
        else
                gid = -1;

        if (mode != oldMode)
                [fattrs setObject: [NSNumber numberWithInt: mode]
                           forKey: NSFilePosixPermissions];

        if ([fm changeFileAttributes: fattrs atPath: path] == NO ||
            chown([path cString], uid, gid) != 0) {
                NSRunAlertPanel(_(@"Failed to change attributes"),
                  _(@"Couldn't change attributes of file %@: access denied"),
                  nil, nil, nil, [path lastPathComponent]);
                return;
        }

        DESTROY(user);
        DESTROY(group);
        oldMode = mode;

        [okButton setEnabled: NO];
        [revertButton setEnabled: NO];
}

- (void) revert: sender
{
        NSDictionary * fattrs = [[NSFileManager defaultManager]
          fileAttributesAtPath: path traverseLink: YES];

        [(PermissionsView *) perms setMode: oldMode];

        if (user != nil) {
                DESTROY(user);
                [fileOwner selectItemWithTitle: [fattrs fileOwnerAccountName]];
        }
        if (group != nil) {
                DESTROY(group);
                [fileGroup selectItemWithTitle: [fattrs fileGroupOwnerAccountName]];
        }

        [okButton setEnabled: NO];
        [revertButton setEnabled: NO];
}

- (void) changePerms: sender
{
        mode = [(PermissionsView *) perms mode];

        [okButton setEnabled: YES];
        [revertButton setEnabled: YES];
}

@end
