//
//  SamplePrefPanePref.m
//  SamplePrefPane
//
//  Created by Uli Kusterer on 23.10.04.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

#import "SamplePrefPane.h"


@implementation SamplePrefPane

-(void) mainViewDidLoad
{

}

- (IBAction) switchPresentation: (id)sender
{
    PKPreferencesController *pc = [PKPreferencesController sharedPreferencesController];
    
    // TODO: We should be able to send -setPresentationMode message through 
    // responder chain without referencing explicitely our preferences 
    // controller.
    switch ([sender selectedRow])
    {
        case 0:
            [pc setPresentationMode: @"PKToolbarPresentationMode"];
            break;
        case 1:
            [pc setPresentationMode: @"PKTableViewPresentationMode"];
            break;
    }
}

/*
-(NSPreferencePaneUnselectReply) shouldUnselect
{
	// The following is simply for testing NSUnselectLater: We send a delayed replyToShouldUnselect: to ourselves:
	NSInvocation*	inv = [NSInvocation invocationWithMethodSignature: [self methodSignatureForSelector: @selector(replyToShouldUnselect:)]];
	BOOL			theBool = YES;
	
	[inv setTarget: self];
	[inv setSelector: @selector(replyToShouldUnselect:)];
	[inv setArgument: &theBool atIndex: 2];	// 0 and 1 are target and selector.
	
	[NSTimer scheduledTimerWithTimeInterval: 5 invocation: inv repeats: NO];

	// Now that that's set up, tell GSSystemPreferences about it:
	return NSUnselectLater;
}
*/
@end
