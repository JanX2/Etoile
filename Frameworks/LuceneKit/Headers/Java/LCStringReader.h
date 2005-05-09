#ifndef __LUCENE_JAVA_STRING_READER__
#define __LUCENE_JAVA_STRING_READER__

#include "LCReader.h"

#ifdef HAVE_UKTEST
#include <UnitKit/UnitKit.h>
@interface LCStringReader: NSObject <LCReader, UKTest>
#else
@interface LCStringReader: NSObject <LCReader>
#endif
{
	unsigned int pos;
	NSString * source; 
}

- (id) initWithString: (NSString *) s;
@end

#endif /* __LUCENE_JAVA_STRING_READER__ */
