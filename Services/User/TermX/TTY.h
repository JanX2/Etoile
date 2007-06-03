/*
   Copyright (c) 2007 <zetawoof gmail>
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or
   modify it under the terms of the MIT license. See COPYING.
*/

#define TTY_MAX_OUTPUT_CHUNK 1024

#import <Foundation/Foundation.h>

@interface TTY : NSObject 
{
	NSFileHandle *term;
	id delegate;
	BOOL alive;
}

- (id)initWithColumns: (int) cols rows: (int) rows;

- (id) delegate;
- (void) setDelegate:(id)del;

- (void) writeData: (NSData *) data;
- (void) writeString: (NSString *) text;

- (void) windowSizedWithRows: (int) rows cols: (int) cols;
@end
