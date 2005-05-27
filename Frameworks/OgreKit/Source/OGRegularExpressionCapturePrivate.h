#ifndef __OgreKit_OGRegularExpressionCapturePrivate__
#define __OgreKit_OGRegularExpressionCapturePrivate__

/*
 * Name: OGRegularExpressionCapturePrivate.h
 * Project: OgreKit
 *
 * Creation Date: Jun 24 2004
 * Author: Isao Sonobe <sonoisa (AT) muse (DOT) ocn (DOT) ne (DOT) jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */


#include <OgreKit/OGRegularExpressionCapture.h>
#include <OgreKit/OGRegularExpressionMatch.h>
#include "OGRegularExpressionMatchPrivate.h"


@interface OGRegularExpressionCapture (Private)

- (id)initWithTreeNode:(OnigCaptureTreeNode*)captureNode 
    index:(unsigned)index 
    level:(unsigned)level 
    parentNode:(OGRegularExpressionCapture*)parentNode 
    match:(OGRegularExpressionMatch*)match;

- (OnigCaptureTreeNode*)_captureNode;

@end

#endif /* __OgreKit_OGRegularExpressionCapturePrivate__ */
