/*
 * Name: OGRegularExpressionMatch.h
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
//#include <OgreKit/oniguruma.h>


// constant
extern NSString	* const OgreMatchException;


@class OGRegularExpression, OGRegularExpressionEnumerator, OGRegularExpressionCapture;
@protocol OGStringProtocol;

/* A match for regular expression (\0), may contain many substrings (\1, \2...) */

@interface OGRegularExpressionMatch : NSObject <NSCopying, NSCoding>
{
	OnigRegion		*_region;						// match result region
	OGRegularExpressionEnumerator	*_enumerator;	// matcher
	unsigned		_terminalOfLastMatch;           // The terminal position of last match (_region->end[0] / sizeof(unichar))
	
	NSObject<OGStringProtocol>	*_targetString;		// target for regular expression search
	NSRange			_searchRange;					// search range
	unsigned		_index;							// index of match
}

/*********
 * Information *
 *********/
// index of this match in all matches (0,1,2,...)
- (unsigned)index;

// number of total substring, including \0
- (unsigned)count;

// description
- (NSString*)description;


/*********
 * String *
 *********/
// Target string
- (NSObject<OGStringProtocol>*)targetOGString;
- (NSString*)targetString;
- (NSAttributedString*)targetAttributedString;

// Matched string \&, \0
- (NSObject<OGStringProtocol>*)matchedOGString;
- (NSString*)matchedString;
- (NSAttributedString*)matchedAttributedString;

// substring at index \index
//  return nil if substring at index doesn't exist
- (NSObject<OGStringProtocol>*)ogSubstringAtIndex:(unsigned)index;
- (NSString*)substringAtIndex:(unsigned)index;
- (NSAttributedString*)attributedSubstringAtIndex:(unsigned)index;

// substring before match \`
- (NSObject<OGStringProtocol>*)prematchOGString;
- (NSString*)prematchString;
- (NSAttributedString*)prematchAttributedString;

// substring after match \'
- (NSObject<OGStringProtocol>*)postmatchOGString;
- (NSString*)postmatchString;
- (NSAttributedString*)postmatchAttributedString;

// the last substring \+
// return nil if not exist
- (NSObject<OGStringProtocol>*)lastMatchOGSubstring;
- (NSString*)lastMatchSubstring;
- (NSAttributedString*)lastMatchAttributedSubstring;

// string between this match and previous match \-
- (NSObject<OGStringProtocol>*)ogStringBetweenMatchAndLastMatch;
- (NSString*)stringBetweenMatchAndLastMatch;
- (NSAttributedString*)attributedStringBetweenMatchAndLastMatch;


/*******
 * range *
 *******/
// range of matched string
- (NSRange)rangeOfMatchedString;

// range of substring at index
//  return (-1, 0) if substring at index doesn't exist
- (NSRange)rangeOfSubstringAtIndex:(unsigned)index;

// range of string before match
- (NSRange)rangeOfPrematchString;

// range of string after match
- (NSRange)rangeOfPostmatchString;

// range of last substring
// return (-1, 0) is last match doesn't exist
- (NSRange)rangeOfLastMatchSubstring;

// range between this match and previous match
- (NSRange)rangeOfStringBetweenMatchAndLastMatch;


/***************************************************************
 * named group relationship (while OgreCaptureGroupOption is specified) *
 ***************************************************************/
// substring with name.
// return nil if name doesn't exist
// raise exception if there are more than one substring with the same name.
- (NSObject<OGStringProtocol>*)ogSubstringNamed:(NSString*)name;
- (NSString*)substringNamed:(NSString*)name;
- (NSAttributedString*)attributedSubstringNamed:(NSString*)name;

// range of substring with name
// return (-1, 0) if name doesn't exist
// raise exception if there are more than one substring with the same name.
- (NSRange)rangeOfSubstringNamed:(NSString*)name;

// index of substring with name
// return -1 if name doesn't exist
// raise exception if there are more than one substring with the same name.
- (unsigned)indexOfSubstringNamed:(NSString*)name;

// namd of substring at index
// return nil if substring at index doesn't exist
- (NSString*)nameOfSubstringAtIndex:(unsigned)index;

/***********************
* information of substring *
************************/
// (regex1)|(regex2)|... An easier way to divide a string into different substrings based on regular expression.
/* For example: 
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"([0-9]+)|([a-zA-Z]+)"];
	NSEnumerator	*matchEnum = [regex matchEnumeratorInString:@"123abc"];
	OGRegularExpressionMatch	*match;
	while ((match = [matchEnum nextObject]) != nil) {
		switch ([match indexOfFirstMatchedSubstring]) {
			case 1:
				NSLog(@"numbers");
				break;
			case 2:
				NSLog(@"alphabets");
				break;
		}
	}
*/
// The first matched substring, return 0 if none.
- (unsigned)indexOfFirstMatchedSubstring;
- (unsigned)indexOfFirstMatchedSubstringBeforeIndex:(unsigned)anIndex;
- (unsigned)indexOfFirstMatchedSubstringAfterIndex:(unsigned)anIndex;
- (unsigned)indexOfFirstMatchedSubstringInRange:(NSRange)aRange;
// name of substring
- (NSString*)nameOfFirstMatchedSubstring;
- (NSString*)nameOfFirstMatchedSubstringBeforeIndex:(unsigned)anIndex;
- (NSString*)nameOfFirstMatchedSubstringAfterIndex:(unsigned)anIndex;
- (NSString*)nameOfFirstMatchedSubstringInRange:(NSRange)aRange;

// The last matched substring, return 0 if none.
- (unsigned)indexOfLastMatchedSubstring;
- (unsigned)indexOfLastMatchedSubstringBeforeIndex:(unsigned)anIndex;
- (unsigned)indexOfLastMatchedSubstringAfterIndex:(unsigned)anIndex;
- (unsigned)indexOfLastMatchedSubstringInRange:(NSRange)aRange;
// name of substring
- (NSString*)nameOfLastMatchedSubstring;
- (NSString*)nameOfLastMatchedSubstringBeforeIndex:(unsigned)anIndex;
- (NSString*)nameOfLastMatchedSubstringAfterIndex:(unsigned)anIndex;
- (NSString*)nameOfLastMatchedSubstringInRange:(NSRange)aRange;

// The longest substring, return 0 if none.
// If there are more than one substring with the same length,
// return the one with smaller index.
- (unsigned)indexOfLongestSubstring;
- (unsigned)indexOfLongestSubstringBeforeIndex:(unsigned)anIndex;
- (unsigned)indexOfLongestSubstringAfterIndex:(unsigned)anIndex;
- (unsigned)indexOfLongestSubstringInRange:(NSRange)aRange;
// name of longest substring
- (NSString*)nameOfLongestSubstring;
- (NSString*)nameOfLongestSubstringBeforeIndex:(unsigned)anIndex;
- (NSString*)nameOfLongestSubstringAfterIndex:(unsigned)anIndex;
- (NSString*)nameOfLongestSubstringInRange:(NSRange)aRange;

// The shortest substring, return 0 if none.
// If there are more than one substring with the same length,
// return the one with smaller index.
- (unsigned)indexOfShortestSubstring;
- (unsigned)indexOfShortestSubstringBeforeIndex:(unsigned)anIndex;
- (unsigned)indexOfShortestSubstringAfterIndex:(unsigned)anIndex;
- (unsigned)indexOfShortestSubstringInRange:(NSRange)aRange;
// name of shortest substring
- (NSString*)nameOfShortestSubstring;
- (NSString*)nameOfShortestSubstringBeforeIndex:(unsigned)anIndex;
- (NSString*)nameOfShortestSubstringAfterIndex:(unsigned)anIndex;
- (NSString*)nameOfShortestSubstringInRange:(NSRange)aRange;

/******************
* Capture History *
*******************/
/*Example:
	NSString					*target = @"abc de";
	OGRegularExpression			*regex = [OGRegularExpression regularExpressionWithString:@"(?@[a-z])+"];
	OGRegularExpressionMatch	*match;
    OGRegularExpressionCapture  *capture;
	NSEnumerator				*matchEnumerator = [regex matchEnumeratorInString:target];
	unsigned					i;
	
	while ((match = [matchEnumerator nextObject]) != nil) {
		capture = [match captureHistory];
		NSLog(@"number of capture history: %d", [capture numberOfChildren]);
		for (i = 0; i < [capture numberOfChildren]; i++) 
            NSLog(@" %@", [[capture childAtIndex:i] string]);
	}
	
Record:
number of capture history: 3
 a
 b
 c
number of capture history: 2
 d
 e
 */

// capture history
// return nil if there is no history
- (OGRegularExpressionCapture*)captureHistory;

@end

// Length of UTF16 string
unsigned Ogre_UTF16strlen(unichar *const aUTF16string, unichar *const end);

