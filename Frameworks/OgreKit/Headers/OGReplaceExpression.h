/*
 * Name: OGReplaceExpression.h
 * Project: OgreKit
 *
 * Creation Date: Sep 22 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#import <OgreKit/OGRegularExpression.h>

@class OGRegularExpressionMatch;

extern NSString	* const OgreReplaceException;

@interface OGReplaceExpression : NSObject <NSCopying, NSCoding>
{
	NSMutableArray	*_compiledReplaceString;
	NSMutableArray	*_compiledReplaceStringType;
	NSMutableArray	*_nameArray;
	unsigned		_options;
}

/*********
 * Initiation *
 *********/
/*
 special characters used in expressionString (replaceString ?)
  \&, \0		string of match
  \1 ... \9		substrings of match
  \+			last substring of match
  \`			string before match (prematchString)
  \'			string after match (postmatchString)
  \-			string between this match and previous match (stringBetweenLastMatchAndLastButOneMatch)
  \g<name>  	(?<name>...) substring of match (usable while OgreCaptureGroupOption is specified)
  \g<index> 	index of substring of match (?<name>...) (usable while OgreCaptureGroupOption is specified)
  \\			backslash "\"
  \t			tab (0x09)
  \n			newline (0x0A)
  \r			return (0x0D)
  \x{HHHH}		16-bit Unicode character U+HHHH
  \OtherCharacter	\Other character
 */
- (id)initWithString:(NSString*)replaceString 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
- (id)initWithString:(NSString*)replaceString 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
- (id)initWithString:(NSString*)replaceString 
	escapeCharacter:(NSString*)character;
- (id)initWithString:(NSString*)replaceString;

- (id)initWithAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)options
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
- (id)initWithAttributedString:(NSAttributedString*)replaceString
	options:(unsigned)replaceOptions;
- (id)initWithAttributedString:(NSAttributedString*)replaceString;

- (id)initWithOGString:(NSObject<OGStringProtocol>*)replaceString 
	options:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;

+ (id)replaceExpressionWithString:(NSString*)replaceString 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
+ (id)replaceExpressionWithString:(NSString*)replaceString 
	escapeCharacter:(NSString*)character;
+ (id)replaceExpressionWithString:(NSString*)replaceString;

+ (id)replaceExpressionWithAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
+ (id)replaceExpressionWithAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)options;
+ (id)replaceExpressionWithAttributedString:(NSAttributedString*)replaceString;

+ (id)replaceExpressionWithOGString:(NSObject<OGStringProtocol>*)replaceString 
	options:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;

/*******
 * replace *
 *******/
- (NSObject<OGStringProtocol>*)replaceMatchedOGStringOf:(OGRegularExpressionMatch*)match;
- (NSString*)replaceMatchedStringOf:(OGRegularExpressionMatch*)match;
- (NSAttributedString*)replaceMatchedAttributedStringOf:(OGRegularExpressionMatch*)match;

@end

