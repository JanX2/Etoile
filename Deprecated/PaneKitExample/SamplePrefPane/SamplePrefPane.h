//
//  SamplePrefPanePref.h
//  SamplePrefPane
//
//  Created by Uli Kusterer on 23.10.04.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

#import <PaneKit/PaneKit.h>


@interface SamplePrefPane : NSPreferencePane 
{

}

- (void) mainViewDidLoad;

- (IBAction) switchPresentation: (id)sender;

@end
