#import "StringMap.h"

unsigned simpleStringHash(NSMapTable *table, const void *anObject)
{
	if(strlen(anObject) > 3)
	{
		return *(unsigned *)anObject;
	}
	return 0;
}
BOOL isCStringEqual(NSMapTable *table, const void * str1, const void * str2)
{
	return strcmp(str1, str2) == 0;
}

