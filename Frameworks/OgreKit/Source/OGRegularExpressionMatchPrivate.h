#ifndef __OgreKit_OGRegularExpressionMatchPrivate__
#define __OgreKit_OGRegularExpressionMatchPrivate__

/*
 * Name: OGRegularExpressionMatchPrivate.h
 * Project: OgreKit
 *
 * Creation Date: Sep 01 2003
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#include <Foundation/Foundation.h>
#include <OgreKit/OGRegularExpressionMatch.h>
#include <OgreKit/OGString.h>

@interface OGRegularExpressionMatch (Private)

/*********
 * 初期化 *
 *********/
- (id)initWithRegion:(OnigRegion*)region 
	index:(unsigned)anIndex
	enumerator:(OGRegularExpressionEnumerator*)enumerator
	terminalOfLastMatch:(unsigned)terminalOfLastMatch;

- (NSObject<OGStringProtocol>*)_targetString;
- (NSRange)_searchRange;
- (OnigRegion*)_region;

@end

#endif /* __OgreKit_OGRegularExpressionMatchPrivate__ */
