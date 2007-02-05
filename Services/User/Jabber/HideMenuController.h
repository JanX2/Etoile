//
//  HideMenuController.h
//  Jabber
//
//  Created by David Chisnall on 09/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface HideMenuController : NSObject {
	id current;
}
- (IBAction) away:(id) sender;
- (IBAction) xa:(id) sender;
- (IBAction) dnd:(id) sender;
- (IBAction) offline:(id) sender;
- (IBAction) none:(id) sender;
@end
