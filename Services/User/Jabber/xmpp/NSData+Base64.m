//
//  NSString+Base64.m
//  Jabber
//
//  Created by David Chisnall on 10/11/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSData+Base64.h"
#include <openssl/bio.h>
#include <openssl/evp.h>

@implementation NSData (Base64)
- (NSString*) base64String
{
	//TODO: Make this re-usable
	BIO * mem = BIO_new(BIO_s_mem());
	BIO * b64 = BIO_new(BIO_f_base64());
	BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    mem = BIO_push(b64, mem);
	BIO_write(mem, [self bytes], [self length]);
    BIO_flush(mem);
	char * base64CString;
    long base64Length = BIO_get_mem_data(mem, &base64CString);
    NSString * encodedString = [NSString stringWithCString:base64CString
                                                   length:base64Length];
    BIO_free_all(mem);
    return encodedString;
}
- (NSString*) base64DecodeString
{
	return nil;
}
@end
