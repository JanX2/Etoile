/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "PreferencesComponent.h"
#import "ToolbarDelegate.h"

@interface PreferencesPanel : UKNibOwner <ToolbarDelegate>
{
    IBOutlet NSPanel* window;
    IBOutlet NSView* replacableView;
    
    NSMutableArray* prefComponents;
    NSMutableArray* toolbarItemIdentifiers;
    NSMutableDictionary* toolbarItems; // key is item identifier
}


+(PreferencesPanel*) shared;

-(BOOL) addPreferencesComponent: (id<PreferencesComponent>) aPrefComponent;

-(void)open;
-(void)close;

@end

