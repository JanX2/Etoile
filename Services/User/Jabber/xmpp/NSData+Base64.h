//
//  NSString+Base64.h
//  Jabber
//
//  Created by David Chisnall on 10/11/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * The NSData (Base64) category provides methods for base 64 encoding and decoding
 * the value of an NSData object.  Uses the OpenSSL base 64 encoding and decoding
 * functionality.
 *
 * This might be useful elsewhere.  If it is, it could be moved into 
 * EtoileFoundation.
 */
@interface NSData (Base64) 
- (NSString*) base64String;
- (NSString*) base64DecodeString;
@end
