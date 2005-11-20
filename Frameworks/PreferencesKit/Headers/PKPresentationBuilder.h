/*
	PKPreferencesController.h
 
	Abstract Preferences window controller class
 
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


@interface PKPresentationBuilder : NSObject {

}

+ (id) builderForPresentationMode: (NSString *)presentationMode;

/* Preferences UI related stuff */
- (void) loadUI;
- (void) unloadUI;
- (void) resizePreferencesViewForView: (NSView *)view;

/* Method from PKPreferencesController which needs to be customized in subclass */
- (IBAction) switchPreferencePaneView: (id)sender;

/* Abstract accessors methods */
// NOTE: In subclass, should return a view where loaded preference panes 
// are listed and the related presentation name.
- (NSView *) presentationView;
- (NSString *) presentationMode;

@end
