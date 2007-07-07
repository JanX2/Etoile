/*  -*-objc-*-
 *
 *  Dictionary Reader - A Dict client for GNUstep
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#ifndef _STREAMLINEWRITER_H_
#define _STREAMLINEWRITER_H_

#import <Foundation/Foundation.h>

@interface StreamLineWriter : NSObject
{
	NSOutputStream* outputStream;
}

- (id) initWithOutputStream: (NSOutputStream *) anOutputStream;
- (BOOL) writeLine: (NSString *) aString;

@end

#endif // _STREAMLINEWRITER_H_
