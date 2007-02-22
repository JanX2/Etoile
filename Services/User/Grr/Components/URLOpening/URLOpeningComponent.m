/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "URLOpeningComponent.h"
#import "NSWorkspace+URLOpening.h"

@implementation URLOpeningComponent

// ---------------------------------------
//    initialisation
// ---------------------------------------

-(id) init
{
    if ((self = [super init]) != nil) {
        ASSIGN(
            browserPath,
            [[NSUserDefaults standardUserDefaults] objectForKey: RSSReaderWebBrowserDefaults]
        );
        [self updateGUI];
    }
    
    return self;
}

-(void) awakeFromNib
{
    // Load browser image and give name
    NSString* imgPath = [[NSBundle bundleForClass: [self class]]
        pathForResource: @"WebBrowser" ofType: @"tiff" ];
    NSAssert1([imgPath length] > 0, @"Bad image path %@", imgPath);
    NSImage* browserImage = [[NSImage alloc] initWithContentsOfFile: imgPath];
    NSAssert(browserImage != nil, @"\"Browser\" image couldn't be loaded from the resources.");
    [browserImage setName: @"WebBrowser"];
}


// ---------------------------------------
//    Overriding stuff from the superclass
// ---------------------------------------

-(NSString*) prefPaneName
{
    return @"Web Browser";
}

-(NSImage*) prefPaneIcon
{
    return [NSImage imageNamed: @"WebBrowser"];
}

// ---------------------------------------
//    actions from the GUI
// ---------------------------------------

-(IBAction) openBrowserSelectionDialog: (id)sender
{
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES) lastObject];
    
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setTitle: NSLocalizedString(@"Choose Web Browser application", @"title of the open dialog")];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setCanChooseFiles: YES];
    [openPanel setCanChooseDirectories: NO];
    
    int result = [openPanel runModalForDirectory: path file: browserPath types: nil];
    
    if (result == NSOKButton) {
        NSLog(@"Panel selected: %@", [openPanel filename]);
        NSString* filename = [openPanel filename];
        if ([self isBrowserAllowed: filename]) {
            [self setBrowser: filename];
        }
    }
}


// ---------------------------------------
//    verifying and setting the browser
// ---------------------------------------

-(BOOL) isBrowserAllowed: (NSString*) path
{
    return YES;
}

-(void) setBrowser: (NSString*) path
{
    NSParameterAssert([self isBrowserAllowed: path]);
    
    ASSIGN(browserPath, path);
    [[NSUserDefaults standardUserDefaults] setObject: path
        forKey: RSSReaderWebBrowserDefaults];
    
    [self updateGUI];
}


// ---------------------------------------
//    updating the GUI
// ---------------------------------------

-(void) updateGUI
{
    if (browserPath == nil) {
        [browserIconView setImage: [NSImage imageNamed: @"WebBrowser"]];
        [browserNameView setStringValue: @"Nothing chosen."];
    } else {
        [browserIconView setImage: [[NSWorkspace sharedWorkspace] iconForFile: browserPath]];
        [browserNameView setStringValue: [browserPath lastPathComponent]];
    }
}

@end

