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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

extern NSString* const FontBoxChangedNotification;

/**
 * This is a subclass of NSBox which is supposed to be connected with two NSPopUpButtons
 * in Gorm. It handles the selection of a font family and size and automatically connects
 * this selection with user defaults keys.
 */
@interface FontBox: NSBox
{
    IBOutlet NSPopUpButton* fontSelector;
    IBOutlet NSPopUpButton* sizeSelector;
    
    // The names of the defaults for font name and size.
    NSString* nameDefault;
    NSString* sizeDefault;
}

-(IBAction) fontSelectionChanged: (id)sender;
-(IBAction) sizeSelectionChanged: (id)sender;

-(void) setNameOptions: (NSArray*) nameOptions;
-(void) setSizeOptions: (NSArray*) sizeOptions;

-(void) attachToNameDefault: (NSString*) nameDefaultName;
-(void) attachToSizeDefault: (NSString*) sizeDefaultName;

-(void) notifyChange;
@end
