#import "StringMap.h"
#include <stdint.h>
/**
 * A trivial hash from a string, made by casting the first few characters of a
 * string to an integer.
 */
NSUInteger simpleStringHash(NSMapTable *table, const void *anObject)
{
	int len = strlen(anObject) + 1;
	// NOTE: NSUInteger is unsigned long on 64bit and unsigned int on 32bit
	// platforms.
	if(len >= sizeof(NSUInteger))
	{
		return *(NSUInteger *)anObject;
	}
	if(len >= sizeof(uint32_t))
	{
		return (NSUInteger)*(uint32_t*)anObject;
	}
	if(len >= sizeof(uint16_t))
	{
		return (NSUInteger)*(uint16_t*)anObject;
	}
	if (len >= sizeof(uint8_t))
	{
		return (NSUInteger)*(uint8_t*)anObject;
	}
	//Should never be reached
	return 0;
}
/**
 * String comparison function.  Simple wrapper around strcmp.
 */
BOOL isCStringEqual(NSMapTable *table, const void * str1, const void * str2)
{
	return strcmp(str1, str2) == 0;
}

