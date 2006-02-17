/*
 * Name: OGRegularExpressionEnumerator.h
 * Project: OgreKit
 *
 * Creation Date: Sep 03 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <Foundation/Foundation.h>

@class OGRegularExpression;

// Exception
extern NSString	* const OgreEnumeratorException;

@interface OGRegularExpressionEnumerator : NSEnumerator <NSCopying, NSCoding>
{
	OGRegularExpression	*_regex;				// Regular expression
	NSObject<OGStringProtocol>			*_targetString;			// target string
	unichar             *_UTF16TargetString;	// target string in UTF16
	unsigned			_lengthOfTargetString;	// [_targetString length]
	NSRange				_searchRange;			// search range
	unsigned			_searchOptions;			// search options
	int					_terminalOfLastMatch;	// position of previous match  (_region->end[0] / sizeof(unichar))
	unsigned			_startLocation;			// start location to search
	BOOL				_isLastMatchEmpty;		// whether previous match is empty (not exist ?)
	
	unsigned			_numberOfMatches;		// number of matches
}

// All matches in order
- (NSArray*)allObjects;
// next match
- (id)nextObject;

// description
- (NSString*)description;

@end

