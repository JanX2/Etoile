/*
 *  DictionaryReader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


#ifdef ETOILE
#import <EtoileUI/UKNibOwner.h>
#else
#import "UKNibOwner.h"
#endif


/**
 * This notification is sent through the default notification center whenever the
 * selection of the active dictionaries changes. The notification object is an array
 * that contains the new active dictionaries.
 */
static NSString* DRActiveDictsChangedNotification = @"DRActiveDictsChangedNotification";



/**
 * This is the controller class for the preferences panel.
 */
@interface Preferences : UKNibOwner
{
    NSTableView* _tableView;
    NSPanel* _prefPanel;
    NSMutableArray* _dictionaries;
}

// Singleton
+(id)shared;

-(void)setDictionaries: (NSMutableArray*) dicts;
-(void)rescanDictionaries: (id)sender;

-(void)show;
-(void)hide;
@end


@interface Preferences (SearchForDictionaries)
// The file to store the dictionary list to
-(NSString*) dictionaryStoreFile;
-(void) foundDictionary: (id)aDictionary;
- (void) searchWithDictionaryStoreFile;
-(void) searchInUsualPlaces;
-(void) searchInDirectory: (NSString*) dirName;
@end


@interface Preferences (DictionarySelectionDataSource)
@end

