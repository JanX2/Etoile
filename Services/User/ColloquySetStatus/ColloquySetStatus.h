//
//  Test.h
//  distn
//
//  Created by David Chisnall on 20/05/2007.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ColloquySetStatus : NSObject {
	unsigned char lastShow;
	NSString * lastStatus;
}
- (void) run;
@end
