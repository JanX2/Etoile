/*
 * Name: OGRegularExpression.h
 * Project: OgreKit
 *
 * Creation Date: Aug 30 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>
#ifndef NOT_RUBY
#	define NOT_RUBY
#endif
#ifndef HAVE_CONFIG_H
#	define HAVE_CONFIG_H
#endif
#import <oniguruma.h>


/* constants */
// version
#define OgreVersionString	@"2.0.0"

// compile time options:
extern const unsigned	OgreNoneOption;
extern const unsigned	OgreSingleLineOption;
extern const unsigned	OgreMultilineOption;
extern const unsigned	OgreIgnoreCaseOption;
extern const unsigned	OgreExtendOption;
extern const unsigned	OgreFindLongestOption;
extern const unsigned	OgreFindNotEmptyOption;
extern const unsigned	OgreNegateSingleLineOption;
extern const unsigned	OgreDontCaptureGroupOption;
extern const unsigned	OgreCaptureGroupOption;

// (Doesn't work with REG_OPTION_POSIX_REGION)
// OgreDelimitByWhitespaceOptionはOgreSimpleMatchingSyntax: use space as seperator
// For example: @"AAA BBB CCC" -> @"(AAA)|(BBB)|(CCC)"
extern const unsigned	OgreDelimitByWhitespaceOption;

#define OgreCompileTimeOptionMask(x)	((x) & (OgreSingleLineOption | OgreMultilineOption | OgreIgnoreCaseOption | OgreExtendOption | OgreFindLongestOption | OgreFindNotEmptyOption | OgreNegateSingleLineOption | OgreDontCaptureGroupOption | OgreCaptureGroupOption | OgreDelimitByWhitespaceOption))

// search time options:
extern const unsigned	OgreNotBOLOption;
extern const unsigned	OgreNotEOLOption;
extern const unsigned	OgreFindEmptyOption;

#define OgreSearchTimeOptionMask(x)		((x) & (OgreNotBOLOption | OgreNotEOLOption | OgreFindEmptyOption))

// replace time options:
extern const unsigned	OgreReplaceWithAttributesOption;
extern const unsigned	OgreReplaceFontsOption;
extern const unsigned	OgreMergeAttributesOption;

#define OgreReplaceTimeOptionMask(x)		((x) & (OgreReplaceWithAttributesOption | OgreReplaceFontsOption | OgreMergeAttributesOption))

// compile time syntax
typedef enum {
	OgreSimpleMatchingSyntax = 0, 
	OgrePOSIXBasicSyntax, 
	OgrePOSIXExtendedSyntax, 
	OgreEmacsSyntax, 
	OgreGrepSyntax, 
	OgreGNURegexSyntax, 
	OgreJavaSyntax, 
	OgrePerlSyntax, 
	OgreRubySyntax
} OgreSyntax;

// @"\\"
#define	OgreBackslashCharacter			@"\\"
// "\\"
//#define	OgreCStringBackslashCharacter	[NSString stringWithCString:"\\"]
// Symbol of Yen (Japenese dollar) in GUI
#define	OgreGUIYenCharacter				[NSString stringWithUTF8String:"\xc2\xa5"]

// newline character
typedef enum {
	OgreNonbreakingNewlineCharacter = -1, 
	OgreUnixNewlineCharacter = 0,		OgreLfNewlineCharacter = 0, 
	OgreMacNewlineCharacter = 1,		OgreCrNewlineCharacter = 1, 
	OgreWindowsNewlineCharacter = 2,	OgreCrLfNewlineCharacter = 2, 
	OgreUnicodeLineSeparatorNewlineCharacter,
	OgreUnicodeParagraphSeparatorNewlineCharacter
} OgreNewlineCharacter;


// exception name
extern NSString	* const OgreException;

@class OGRegularExpressionMatch, OGRegularExpressionEnumerator;
@protocol OGStringProtocol;

@interface OGRegularExpression : NSObject <NSCopying, NSCoding>
{
	NSString			*_escapeCharacter;				// escape charactor (\_
	NSString			*_expressionString;				// string of regular expression
	unichar             *_UTF16ExpressionString;        // string of regular expression in UTF16
	unsigned			_options;						// options
	OgreSyntax			_syntax;						// syntax of regular expresion
	
	NSMutableDictionary	*_groupIndexForNameDictionary;	// dictionary of index for name
														// Usage: /(?<a>a+)(?<b>b+)(?<a>c+)/ => {"a" = (1,3), "b" = (2)}
	NSMutableArray		*_nameForGroupIndexArray;		// array of name for index
														// Usage: /(?<a>a+)(?<b>b+)(?<a>c+)/ => ("a", "b", "a")
	regex_t				*_regexBuffer;					// regular expression in OniGuruma
}

/****************************
 * creation, initialization *
 ****************************/
//  Arguments:
//   expressionString: regular expression
//   options: options (see below)
//   syntax: syntax (see below)
//   escapeCharacter: escape character (\)
//  Return value:
//   success: a pointer to OGRegularExpression instance
//   error:  exception raised
/*
 options:
  OgreNoneOption				no option
  OgreSingleLineOption			'^' -> '\A', '$' -> '\z', '\Z' -> '\z'
  OgreMultilineOption			'.' match with newline
  OgreIgnoreCaseOption			ignore case (case-insensitive)
  OgreExtendOption				extended pattern form
  OgreFindLongestOption			find longest match
  OgreFindNotEmptyOption		ignore empty match
  OgreNegateSingleLineOption	clear OgreSINGLELINEOption which is default on
								in OgrePOSIXxxxxSyntax, OgrePerlSyntax and OgreJavaSyntax.
  OgreDontCaptureGroupOption	named group only captured.  (/.../g)
  OgreCaptureGroupOption		named and no-named group captured. (/.../G)
  OgreDelimitByWhitespaceOption	delimit words by whitespace in OgreSimpleMatchingSyntax
  								@"AAA BBB CCC" <=> @"(AAA)|(BBB)|(CCC)"
  
 syntax:
  OgrePOSIXBasicSyntax		POSIX Basic RE 
  OgrePOSIXExtendedSyntax	POSIX Extended RE
  OgreEmacsSyntax			Emacs
  OgreGrepSyntax			grep
  OgreGNURegexSyntax		GNU regex
  OgreJavaSyntax			Java (Sun java.util.regex)
  OgrePerlSyntax			Perl
  OgreRubySyntax			Ruby (default)
  OgreSimpleMatchingSyntax	Simple Matching
  
 escapeCharacter:
  OgreBackslashCharacter		@"\\" Backslash (default)
  OgreGUIYenCharacter			[NSString stringWithUTF8String:"\xc2\xa5"] Yen Mark
 */

+ (id)regularExpressionWithString:(NSString*)expressionString;
+ (id)regularExpressionWithString:(NSString*)expressionString 
	options:(unsigned)options;
+ (id)regularExpressionWithString:(NSString*)expressionString 
	options:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;
	
- (id)initWithString:(NSString*)expressionString;
- (id)initWithString:(NSString*)expressionString 
	options:(unsigned)options;
- (id)initWithString:(NSString*)expressionString 
	options:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;


/*************
 * accessors *
 *************/
// regular expression string, recompile if change
- (NSString*)expressionString;
// current option, recompile if change
- (unsigned)options;
// current syntax, recompile if change
- (OgreSyntax)syntax;
// escape character, recompile if change
- (NSString*)escapeCharacter;

// number of capture group
- (unsigned)numberOfGroups;
// number of named group
- (unsigned)numberOfNames;
// array of names
// return nil if named group is not used
- (NSArray*)names;

// default escape character (\)
+ (NSString*)defaultEscapeCharacter;
// change escape character.
// Won't affect instance generated before change
// raise while character cannot be used.
+ (void)setDefaultEscapeCharacter:(NSString*)character;

// default syntax (OgreRubySyntax)
+ (OgreSyntax)defaultSyntax;
// change default syntax
// Won't affect instance generated before change
+ (void)setDefaultSyntax:(OgreSyntax)syntax;

// OgreKit version
+ (NSString*)version;
// oniguruma version
+ (NSString*)onigurumaVersion;

// description
- (NSString*)description;


/*******************
 * Validation test *
 *******************/
// return YES if valid, NO if invalid
/* Usage to know the reason of invalidation.
	NS_DURING
		OGRegularExpression	*rx = [OGRegularExpression regularExpressionWithString:expressionString];
	NS_HANDLER
		// exceptioni handle
		NSLog(@"%@ caught\n", [localException name]);
		NSLog(@"reason = \"%@\"\n", [localException reason]);
	NS_ENDHANDLER
 */
+ (BOOL)isValidExpressionString:(NSString*)expressionString;
+ (BOOL)isValidExpressionString:(NSString*)expressionString
	options:(unsigned)options;
+ (BOOL)isValidExpressionString:(NSString*)expressionString 
	options:(unsigned)options 
	syntax:(OgreSyntax)syntax 
	escapeCharacter:(NSString*)character;


/**********
 * Search *
 **********/
/*
 options:
  OgreNotBOLOption			string head(str) isn't considered as begin of line
  OgreNotEOLOption			string end (end) isn't considered as end of line
  OgreFindEmptyOption		allow empty match being next to not empty matchs
	e.g. 
	regex = [OGRegularExpression regularExpressionWithString:@"[a-z]*" options:compileOptions];
	NSLog(@"%@", [regex replaceAllMatchesInString:@"abc123def" withString:@"(\\0)" options:searchOptions]);
	
	compileOptions			searchOptions				replaced string
 1. OgreFindNotEmptyOption  OgreNoneOption				(abc)123(def)
							(or OgreFindEmptyOption)		
 2. OgreNoneOption			OgreNoneOption				(abc)1()2()3(def)
 3. OgreNoneOption			OgreFindEmptyOption			(abc)()1()2()3(def)()
 
	(comment: OgreFindEmptyOption is useful in the case of a matching like [a-z]+|\z.)
 */
// The first match
// return nil if no match
- (OGRegularExpressionMatch*)matchInString:(NSString*)string;
- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	range:(NSRange)range;
- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	options:(unsigned)options;
- (OGRegularExpressionMatch*)matchInString:(NSString*)string 
	options:(unsigned)options 
	range:(NSRange)searchRange;

- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString;
- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString 
	range:(NSRange)range;
- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString 
	options:(unsigned)options;
- (OGRegularExpressionMatch*)matchInAttributedString:(NSAttributedString*)attributedString 
	options:(unsigned)options 
	range:(NSRange)searchRange;

- (OGRegularExpressionMatch*)matchInOGString:(NSObject<OGStringProtocol>*)string 
	options:(unsigned)options 
	range:(NSRange)searchRange;

// All matches in enumerator of OGRegularExpressionMatch
// return OGRegularExpressionEnumerator
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string;
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string 
	options:(unsigned)options;
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string 
	range:(NSRange)searchRange;
- (NSEnumerator*)matchEnumeratorInString:(NSString*)string 
	options:(unsigned)options 
	range:(NSRange)searchRange;
	
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString;
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString 
	options:(unsigned)options;
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString 
	range:(NSRange)searchRange;
- (NSEnumerator*)matchEnumeratorInAttributedString:(NSAttributedString*)attributedString 
	options:(unsigned)options 
	range:(NSRange)searchRange;

- (NSEnumerator*)matchEnumeratorInOGString:(NSObject<OGStringProtocol>*)string 
	options:(unsigned)options 
	range:(NSRange)searchRange;
	
// All matches in array of OGRegularExpressionMatch
// The order is the matched order
// The same  as ([[self matchEnumeratorInString:string] allObject])
// return nil if there is no match
- (NSArray*)allMatchesInString:(NSString*)string;
- (NSArray*)allMatchesInString:(NSString*)string
	options:(unsigned)options;
- (NSArray*)allMatchesInString:(NSString*)string
	range:(NSRange)searchRange;
- (NSArray*)allMatchesInString:(NSString*)string
	options:(unsigned)options 
	range:(NSRange)searchRange;

- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString;
- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString
	options:(unsigned)options;
- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString
	range:(NSRange)searchRange;
- (NSArray*)allMatchesInAttributedString:(NSAttributedString*)attributedString
	options:(unsigned)options 
	range:(NSRange)searchRange;

- (NSArray*)allMatchesInOGString:(NSObject<OGStringProtocol>*)string
	options:(unsigned)options 
	range:(NSRange)searchRange;


/***********
 * Replace *
 ***********/
// return matched regular expression in targetString with replaceString
// replaceString can use escape, see OGReplaceExpression.h
// Only replace the first match
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)searchOptions;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)searchOptions;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

// replace all matches
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)searchOptions;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)searchOptions;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

// replace matches
/*
 isReplaceAll == YES replace all matches
				 NO  replace first match
 count: number of replace
 */
- (NSString*)replaceString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;

- (NSString*)replaceString:(NSString*)targetString 
	withString:(NSString*)replaceString 
	options:(unsigned)searchOptions 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	withAttributedString:(NSAttributedString*)replaceString 
	options:(unsigned)searchOptions 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

- (NSObject<OGStringProtocol>*)replaceOGString:(NSObject<OGStringProtocol>*)targetString 
	withOGString:(NSObject<OGStringProtocol>*)replaceString 
	options:(unsigned)searchOptions 
	range:(NSRange)replaceRange 
	replaceAll:(BOOL)replaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

// delegate for replacement
/*
 aSelector must be this format:
 messages:
	1st: insatnce of OGRegularExpressionMatch
	2nd: contextInfo
 return:
	string for replacement
	(but return nil if replacement is stop)
	
 For example: conversion of temperature (celcius to fahrenheit).
	- (NSString*)fahrenheitForCelsius:(OGRegularExpressionMatch*)aMatch contextInfo:(id)contextInfo
	{
		double	celcius = [[aMatch substringAtIndex:1] doubleValue];
		double	fahrenheit = celcius * 9.0 / 5.0 + 32.0;
		return [NSString stringWithFormat:@"%.1fF", fahrenheit];
	}
 */
// replace first match
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions;
- (NSString*)replaceFirstMatchInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions;
- (NSAttributedString*)replaceFirstMatchInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

- (NSObject<OGStringProtocol>*)replaceFirstMatchInOGString:(NSObject<OGStringProtocol>*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

// replace all matches
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions;
- (NSString*)replaceAllMatchesInString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions;
- (NSAttributedString*)replaceAllMatchesInAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

- (NSObject<OGStringProtocol>*)replaceAllMatchesInOGString:(NSObject<OGStringProtocol>*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange;

// replace matches
/*
 isReplaceAll == YES replace all matches
				 NO  replace first match
 count: number of replace
 */
- (NSString*)replaceString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;
- (NSString*)replaceString:(NSString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll;	
- (NSAttributedString*)replaceAttributedString:(NSAttributedString*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;

- (NSObject<OGStringProtocol>*)replaceOGString:(NSObject<OGStringProtocol>*)targetString 
	delegate:(id)aDelegate 
	replaceSelector:(SEL)aSelector 
	contextInfo:(id)contextInfo 
	options:(unsigned)searchOptions
	range:(NSRange)replaceRange
	replaceAll:(BOOL)isReplaceAll
	numberOfReplacement:(unsigned*)numberOfReplacement;


/*********
 * Split *
 *********/
// split string with regular expression
- (NSArray*)splitString:(NSString*)aString;

- (NSArray*)splitString:(NSString*)aString 
	options:(unsigned)searchOptions;
	
- (NSArray*)splitString:(NSString*)aString 
	options:(unsigned)searchOptions 
	range:(NSRange)searchRange;
	
/*
 Usage of limit (use @"," as example)
	limit >  0:				the max number of split. limit==3 means @"a,b,c,d,e" -> (@"a", @"b", @"c")
	limit == 0(silent):	ignore the last aString @"a,b,c," -> (@"a", @"b", @"c")
	limit <  0:				include the last aString @"a,b,c," -> (@"a", @"b", @"c", @"")
 */
- (NSArray*)splitString:(NSString*)aString 
	options:(unsigned)searchOptions 
	range:(NSRange)searchRange
	limit:(int)limit;


/*************
 * Utilities *
 *************/
// conversion between OgreSyntax and int
+ (int)intValueForSyntax:(OgreSyntax)syntax;
+ (OgreSyntax)syntaxForIntValue:(int)intValue;
// string of OgreSyntax
+ (NSString*)stringForSyntax:(OgreSyntax)syntax;
// strings of Options
+ (NSArray*)stringsForOptions:(unsigned)options;

// convert string into regex-safe string (@"|().?*+{}^$[]-&#:=!<>@\\" are avoided)
+ (NSString*)regularizeString:(NSString*)string;

// newline character in string
+ (OgreNewlineCharacter)newlineCharacterInString:(NSString*)aString;
// replace newline character
+ (NSString*)replaceNewlineCharactersInString:(NSString*)aString withCharacter:(OgreNewlineCharacter)newlineCharacter;
// remove newline character
+ (NSString*)chomp:(NSString*)aString;

@end

