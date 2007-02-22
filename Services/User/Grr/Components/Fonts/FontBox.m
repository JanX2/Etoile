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

#import "FontBox.h"

NSString* const FontBoxChangedNotification = @"FontBoxChangedNotification";

static NSMutableDictionary* titleToFontSizeDict = nil;


@implementation FontBox

// ----------------------------------------------------
//    Responding to actions from the GUI
// ----------------------------------------------------

-(IBAction) fontSelectionChanged: (id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject: [sender titleOfSelectedItem]
                                              forKey: nameDefault];
    [self notifyChange];
}

-(IBAction) sizeSelectionChanged: (id)sender
{
    [[NSUserDefaults standardUserDefaults]
        setObject: [titleToFontSizeDict objectForKey: [sender titleOfSelectedItem]]
           forKey: sizeDefault];
    
    [self notifyChange];
}


// ----------------------------------------------------
//    Setting the options
// ----------------------------------------------------

-(void) setNameOptions: (NSArray*) nameOptions
{
    NSAssert(fontSelector != nil, @"Where is my font selector?");
    
    [fontSelector removeAllItems];
    [fontSelector addItemsWithTitles: nameOptions];
}



-(void) setSizeOptions: (NSArray*) sizeOptions
{
    NSMutableArray* sizeOptionsTitles = [NSMutableArray new];
    NSAssert(sizeSelector != nil, @"Where is my size selector?");
    
    if (titleToFontSizeDict == nil) {
        ASSIGN(titleToFontSizeDict, [NSMutableDictionary new]);
    }
    
    int i;
    for (i=0; i<[sizeOptions count]; i++) {
        NSString* floatObj = [sizeOptions objectAtIndex: i];
        NSString* title = [floatObj description];
        
        [titleToFontSizeDict setObject: floatObj forKey: title];
        [sizeOptionsTitles addObject: title];
    }

    [sizeSelector removeAllItems];
    [sizeSelector addItemsWithTitles: sizeOptionsTitles];
}



// ----------------------------------------------------
//    Attach font box to user defaults
// ----------------------------------------------------

-(void) attachToNameDefault: (NSString*) nameDefaultName;
{
    ASSIGN(nameDefault, nameDefaultName);
    NSString* selName = [[NSUserDefaults standardUserDefaults] objectForKey: nameDefault];
    
    [fontSelector selectItemWithTitle: selName];
    
    NSLog(@"tried to select item with title %@", selName);
}

-(void) attachToSizeDefault: (NSString*) sizeDefaultName
{
    ASSIGN(sizeDefault, sizeDefaultName);
    NSNumber* size = [[NSUserDefaults standardUserDefaults] objectForKey: sizeDefault];
    
    [sizeSelector selectItemWithTitle: [size description]];
}



// ----------------------------------------------------
//    Notifies on changes
// ----------------------------------------------------

-(void) notifyChange
{
    [[NSNotificationCenter defaultCenter] postNotificationName: FontBoxChangedNotification
                                                        object: self
                                                      userInfo: nil];
}
@end

