/*
   AttributesPane.h
   The attributes pane.

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

#import "AttributesPane.h"
#import <sys/types.h>
#import <grp.h>
#import <pwd.h>
#import <unistd.h>

@implementation AttributesPane
/* Private */
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

// find all user accounts on this machine
- (void) locateUsers
{
  struct passwd *pwd = NULL;
  NSMutableDictionary * usrs = [NSMutableDictionary dictionary];

  while ((pwd = getpwent()) != NULL)
  {
    [usrs setObject: [NSNumber numberWithInt: pwd->pw_uid]
             forKey: [NSString stringWithCString: pwd->pw_name]];
  }

  ASSIGN(users, usrs);
}

// find all groups on this machine + mark all that we're a member of
- (void) locateGroups
{
  NSString * userName = NSUserName();
  struct group *groupEntry = NULL;
  NSMutableDictionary *allGrs = [NSMutableDictionary dictionary];
  NSMutableDictionary *myGrs = [NSMutableDictionary dictionary];

  while ((groupEntry = getgrent()) != NULL) 
  {
    char *member = NULL;
    unsigned i;
    NSNumber *gid = [NSNumber numberWithInt: groupEntry->gr_gid];
    NSString * gname = [NSString stringWithCString: groupEntry->gr_name];

    [allGrs setObject: gid forKey: gname];

    for (i=0; (member = groupEntry->gr_mem[i]) != NULL; i++) 
    {
      if ([userName isEqualToString: [NSString stringWithCString: member]]) 
      {
	[myGrs setObject: gid forKey: gname];
	break;
      }
    }
  }

  // add our own group
  groupEntry = getgrgid(getegid());
  [myGrs setObject: [NSNumber numberWithInt: groupEntry->gr_gid]
             forKey: [NSString stringWithCString: groupEntry->gr_name]];

  ASSIGN(groups, allGrs);
  ASSIGN(myGroups, myGrs);
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
  } 
  else 
  {
    [fileOwner addItemWithTitle: [fileAttributes fileOwnerAccountName]];
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
  } 
  else if ([[fileAttributes fileOwnerAccountName] isEqual: NSUserName()]) 
  {
    if (myGroups == nil)
      [self locateGroups];

    [fileGroup addItemsWithTitles: [[myGroups allKeys]
	sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];
    [fileGroup setEnabled: YES];
  } 
  else 
  {
    [fileGroup addItemWithTitle: [fileAttributes fileGroupOwnerAccountName]];
    [fileGroup setEnabled: NO];
  }

  [fileGroup selectItemWithTitle: [fileAttributes fileGroupOwnerAccountName]];
}

- (void) buildUI: (NSView *) view
{
  NSTextField *textField = nil;
  NSRect frame = [view frame];
  NSRect rect = NSZeroRect;

  /* Size */
  rect = NSMakeRect(5, frame.size.height-5-30, 50, 30);
  textField = [[NSTextField alloc] initWithFrame: rect];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setStringValue: _(@"Size:")];
  [textField setDrawsBackground: NO];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [view addSubview: textField];
  DESTROY(textField);

  rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, 
                    frame.size.width-NSMaxX(rect)-5*2-100, 30);
  fileSize = [[NSTextField alloc] initWithFrame: rect];
  [fileSize setEditable: NO];
  [fileSize setDrawsBackground: NO];
  [fileSize setBordered: NO];
  [fileSize setBezeled: NO];
  [view addSubview: fileSize];
  RELEASE(fileSize);

  rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, 
                    frame.size.width-NSMaxX(rect)-5*2, 30);
  computeSizeBtn = [[NSButton alloc] initWithFrame: rect];
  [computeSizeBtn setTitle: _(@"Compute Size")];
  [computeSizeBtn setTarget: self];
  [computeSizeBtn setAction: @selector(computeSize:)];
  [view addSubview: computeSizeBtn];
  RELEASE(computeSizeBtn);

  /* Owner */
  rect = NSMakeRect(5, NSMinY(rect)-5-30, 50, 30);
  textField = [[NSTextField alloc] initWithFrame: rect];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setStringValue: _(@"Owner:")];
  [textField setDrawsBackground: NO];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [view addSubview: textField];
  DESTROY(textField);

  rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, 
                    frame.size.width-NSMaxX(rect)-5*2-100, 30);
  fileOwner = [[NSPopUpButton alloc] initWithFrame: rect];
  [view addSubview: fileOwner];
  RELEASE(fileOwner);

  /* Group */
  rect = NSMakeRect(5, NSMinY(rect)-5-30, 50, 30);
  textField = [[NSTextField alloc] initWithFrame: rect];
  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setStringValue: _(@"Group:")];
  [textField setDrawsBackground: NO];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [view addSubview: textField];
  DESTROY(textField);

  rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, 
                    frame.size.width-NSMaxX(rect)-5*2-100, 30);
  fileGroup = [[NSPopUpButton alloc] initWithFrame: rect];
  [view addSubview: fileGroup];
  RELEASE(fileGroup);

  /* Permission */
  rect = NSMakeRect(5, NSMinY(rect)-5-80, 150, 80);
  /* Calendar */
  rect = NSMakeRect(NSMaxX(rect)+5, rect.origin.y, 
                    frame.size.width-NSMaxX(rect)-5*2, 80);
  dateView = [[OSDateView alloc] initWithFrame: rect];
  [dateView setShowsYear: YES];
  [view addSubview: dateView];
  RELEASE(dateView);
}

- (void) changeOwner: (id) sender
{
  ASSIGN(user, [sender titleOfSelectedItem]);
#if 0
  [okButton setEnabled: YES];
  [revertButton setEnabled: YES];
#endif
}

- (void) changeGroup: (id) sender
{
  ASSIGN(group, [sender titleOfSelectedItem]);
#if 0
  [okButton setEnabled: YES];
  [revertButton setEnabled: YES];
#endif
}

- (void) computeSize: (id) sender
{
  unsigned long long totalSize = 0;
  NSDirectoryEnumerator *de = [[NSFileManager defaultManager] enumeratorAtPath: path];
  NSDictionary *fattrs;

  while ([de nextObject] != nil && 
         (fattrs = [de fileAttributes]) != nil)
  {
    totalSize += [fattrs fileSize];
  }

  [fileSize setStringValue: [self stringFromSize: totalSize]];
  [computeSizeBtn setEnabled: NO];
}

- (id) init
{
  self = [super init];
 
  _mainView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, INSPECTOR_WIDTH, 300)];
  [self buildUI: _mainView];

  info = [[NSDictionary alloc] initWithObjectsAndKeys:
        @"AttributesPane", @"identifier",
	@"Attributes", @"name",
	@"AttributesPane", @"path",
	[NSValue valueWithPointer: [self class]], @"class",
	self, @"instance", nil];

  return self;
}

- (void) dealloc
{
  DESTROY(_mainView);
  DESTROY(info);
  DESTROY(group);
  DESTROY(user);
  DESTROY(users);
  DESTROY(groups);
  DESTROY(myGroups);
  [super dealloc];
}

- (NSDictionary *) pluginInfo
{
  return info;
}

+ (NSArray *) extensions
{
  return nil;
}

- (void) setPath: (NSString *) aPath
{
  NSCalendarDate * modDate = nil;
  NSDictionary * fattrs = nil;
  NSFileManager * fm = [NSFileManager defaultManager];
  NSString * fType = nil;

  ASSIGN(path, aPath);

  DESTROY(user);
  DESTROY(group);
#if 0
  modeChanged = NO;

  [okButton setEnabled: NO];
  [revertButton setEnabled: NO];
#endif

  fattrs = [fm fileAttributesAtPath: path traverseLink: YES];

  modDate = [[fattrs fileModificationDate]
          dateWithCalendarFormat: nil timeZone: [NSTimeZone localTimeZone]];
  [dateView setCalendarDate: modDate];

#if 0
  [linkTo setStringValue: [fm pathContentOfSymbolicLinkAtPath: path]];
#endif
  [self updateOwner: fattrs];
  [self updateGroup: fattrs];

  [computeSizeBtn setEnabled: NO];

  fType = [fattrs fileType];
  if ([fType isEqualToString: NSFileTypeDirectory]) 
  {
    [computeSizeBtn setEnabled: YES];
    [fileSize setStringValue: nil];
  } 
  else 
  {
    unsigned long long fSize = [fattrs fileSize];
    [fileSize setStringValue: [self stringFromSize: [fattrs fileSize]]];
  }

#if 0
  oldMode = mode = [fattrs filePosixPermissions];
  [(PermissionsView *) perms setMode: mode];
  if (![[fattrs fileOwnerAccountName] isEqualToString: NSUserName()] &&
      geteuid() != 0)
    [perms setEditable: NO];
  else
    [perms setEditable: YES];
#endif
}

@end
