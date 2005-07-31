#ifndef __OgreKit_OGRegularExpressionFormatter__
#define __OgreKit_OGRegularExpressionFormatter__

/*
 * Name: OGRegularExpressionFormatter.h
 * Project: OgreKit
 *
 * Creation Date: Sep 05 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#include <Foundation/Foundation.h>
#include <OgreKit/OGRegularExpression.h>

// Exception name
extern NSString	* const OgreFormatterException;


@interface OGRegularExpressionFormatter : NSFormatter <NSCopying, NSCoding>
{
	NSString			*_escapeCharacter;		// escape character (\)
	unsigned			_options;				// options
	OgreSyntax			_syntax;				// synax
}

// essential methods
- (NSString*)stringForObjectValue:(id)anObject;
- (NSAttributedString*)attributedStringForObjectValue:(id)anObject 
	withDefaultAttributes:(NSDictionary*)attributes;
- (NSString*)editingStringForObjectValue:(id)anObject;

// error handle
- (BOOL)getObjectValue:(id*)obj forString:(NSString*)string 
	errorDescription:(NSString**)error;

- (id)init;
- (id)initWithOptions:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;

- (NSString*)escapeCharacter;
- (void)setEscapeCharacter:(NSString*)character;

- (unsigned)options;
- (void)setOptions:(unsigned)options;

- (OgreSyntax)syntax;
- (void)setSyntax:(OgreSyntax)syntax;

@end

#endif /* __OgreKit_OGRegularExpressionFormatter__ */
