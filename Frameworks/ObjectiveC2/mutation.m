#include "runtime.h"

extern __attribute__((weak)) id NSGenericException;

// Hack because GCC requires the constant string class to be defined.
@interface NXConstantString
{
	void *isa;
	char *data;
	int length;
}
@end
@interface NSConstantString : NXConstantString @end


@interface NSException
- (void)raise: (id)exception format: (id)fmt, ...;
@end

void __attribute__((weak)) objc_enumerationMutation(id obj)
{
	Class NSExceptionCls = objc_getClass("NSException");
	id exception;
	if (NULL == &NSGenericException) 
	{
		exception = @"NSGenericException";
	}
	else
	{
		exception = NSGenericException;
	}
	[NSExceptionCls raise: NSGenericException 
	               format: @"Collection %@ was mutated while being enumerated", 
	                       obj];
}

