/*
	Copyright (C) 2009 Niels Grewe

	Author:  Niels Grewe <niels.grewe@halbordnung.de>
	Date:  July 2009
	License: Modified BSD (see COPYING)
 */

#include <stdlib.h>
#include <limits.h>
#import <Foundation/Foundation.h>

/**
 * Helper category for converting strings to integer values. Provides specific
 * conversions that the Foundation library (neither Apple's nor GNUstep's) does
 * not account for. Used by ETDeserializerBackendXML at the moment (read: can be
 * moved into EtoileFoundation if found useful).
 */
@interface NSString (ETNumericConversions)

-(char) charValue;

-(unsigned char) unsignedCharValue;

-(short) shortValue;

-(unsigned short) unsignedShortValue;

-(unsigned int) unsignedIntValue;

-(long) longValue;

-(unsigned long) unsignedLongValue;

//-longLongValue is defined by Foundation

-(unsigned long long) unsignedLongLongValue;

//-doubleValue and -floatValue are defined by Foundation
@end
