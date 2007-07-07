/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <Foundation/Foundation.h>

@interface NSScanner (Base64Encoding)

/**
 * Scans a Base64 encoded integer.
 * @param outputInteger the location to save the result
 * @return YES if and only if scanning succeeded.
 */
-(BOOL) scanBase64Int: (int*)outputInteger;

@end

