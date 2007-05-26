//
//  Microblogger.h
//  A microblogging tool that reads the presence from StepChat
//  and pushes it out to microblogging sites, like Jaiku.
//
//  Created by Jesse Ross on 20/05/2007.
//  Copyright 2007 Jesse Ross. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Microblogger : NSObject {
	NSString * lastStatus;
	NSString * username;
	NSString * password;
	NSMutableURLRequest * jaikuCall;
}
- (void) runWithUsername:(NSString*)aUsername password:(NSString*)aPassword;
@end
