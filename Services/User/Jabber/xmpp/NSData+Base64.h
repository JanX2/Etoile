//
//  NSString+Base64.h
//  Jabber
//
//  Created by David Chisnall on 10/11/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSData (Base64) 
- (NSString*) base64String;
- (NSString*) base64DecodeString;
@end
