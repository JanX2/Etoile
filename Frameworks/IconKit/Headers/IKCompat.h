/*
 * IKCompat.h - IconKit
 *
 * Mac OS X compatibility.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 *
 * This application is free software; you can redistribute it and/or 
 * modify it under the terms of the 3-clause BSD license. See COPYING.
 */

#ifndef GNUSTEP

#define AUTORELEASE(object) [object autorelease]
#define RELEASE(object) [object release]
#define RETAIN(object) [object retain]
#define ASSIGN(object, value)	({\
id __value = (id)(value); \
id __object = (id)(object); \
if (__value != __object) { \
   if (__value != nil) \
      [__value retain]; \
   object = __value; \
   if (__object != nil) \
      [__object release]; \
}})
#define DESTROY(object) ({\
if (object) \
	{ \
		id __o = object; \
		object = nil; \
		[__o release]; \
	} \
})

#ifdef DEBUG
#define NSDebugLLog(level, format, args...) \
do { if (GSDebugSet(level) == YES) \
	NSLog(format , ## args); } while (0)
#else
#define NSDebugLLog(level, format, args...)
#endif

#endif
