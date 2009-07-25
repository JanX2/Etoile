/*
	Mirror-based reflection API for Etoile.
 
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  June 2009
	License: Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import "ETReflection.h"
#import "ETInstanceVariableMirror.h"
#ifndef GNUSTEP
#import <objc/runtime.h>
#else
#import <ObjectiveC2/runtime.h>
#endif

@interface ETProtocolMirror : NSObject <ETProtocolMirror>
{
	Protocol *_protocol;
}
- (id) initWithProtocol: (Protocol *)protocol;
+ (id) mirrorWithProtocol: (Protocol *)protocol;
@end

