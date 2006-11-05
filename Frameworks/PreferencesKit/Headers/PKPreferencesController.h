/*
	PKPreferencesController.h

	Preferences window controller class

	Copyright (C) 2004 Quentin Mathe
                       Uli Kusterer

	Author:  Quentin Mathe <qmathe@club-internet.fr>
             Uli Kusterer
    Date:  January 2005

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.
 
	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.
 
	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <Foundation/Foundation.h>

@protocol UKTest;

@protocol PKPreferencePaneOwner;
@class PKPreferencePane;
@class PKPresentationBuilder;

extern const NSString *PKNoPresentationMode;
extern const NSString *PKToolbarPresentationMode;
extern const NSString *PKTablePresentationMode;
extern const NSString *PKMatrixPresentationMode;
extern const NSString *PKOtherPresentationMode;


@interface PKPreferencesController: NSObject <PKPreferencePaneOwner, UKTest>
{
  IBOutlet id	owner; /* PKPreferencesView or NSWindow */
  IBOutlet NSView *preferencesView; /* Necessary only when owner is not PKPreferencesView */
  IBOutlet NSView *mainViewWaitSign;	/* View we show while next main view is being loaded. */
  PKPreferencePane *currentPane; /* Currently showing pane. */
  PKPreferencePane *nextPane; /* Pane to show in response to the next replyToShouldUnselect: YES. */
  PKPresentationBuilder *presentation;
}

+ (PKPreferencesController *) sharedPreferencesController;

- (id) initWithPresentationMode: (NSString *)presentationMode;

/* Preferences UI related stuff */
- (BOOL) updateUIForPreferencePane: (PKPreferencePane *)requestedPane;

- (void) selectPreferencePaneWithIdentifier: (NSString *)identifier;

/* Action methods */
- (IBAction) switchPreferencePaneView: (id)sender;

/* Accessors */
- (id) owner;
- (NSView *) preferencesView;

- (NSString *) selectedPreferencePaneIdentifier;
- (PKPreferencePane *) selectedPreferencePane;

- (NSString *) presentationMode;
- (void) setPresentationMode: (NSString *)presentationMode;

@end
