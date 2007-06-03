/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <AppKit/AppKit.h>

@interface TXCursor: NSTextFieldCell
{
@public
	unsigned int row, column;
	uint32_t attribute;
	uint32_t fg, bg;
	char charset;
}

- (void) setRow: (unsigned int) row;
- (void) setColumn: (unsigned int) column;
- (unsigned int) row;
- (unsigned int) column;

- (void) setCharset: (char) charset;
- (char) charset;
@end

