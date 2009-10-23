#import "LanguageKit.h"
#import "Runtime/BigInt.h"
#import "Runtime/Symbol.h"
#import "LKInterpreterRuntime.h"
#import "LKInterpreter.h"
#import "LKTypeHelpers.h"
#import <EtoileFoundation/runtime.h>
#include <ffi.h>

static id BoxValue(void *value, const char *typestr);
static void UnboxValue(id value, void *dest, const char *objctype);

static NSMutableDictionary *_InterpreterIMPs;

ffi_type *_ffi_type_nspoint_elements[] = {
	&ffi_type_float, &ffi_type_float, NULL
};
ffi_type ffi_type_nspoint = {
	0, 0, FFI_TYPE_STRUCT, _ffi_type_nspoint_elements
};
ffi_type *_ffi_type_nsrect_elements[] = {
	&ffi_type_nspoint, &ffi_type_nspoint, NULL
};
ffi_type ffi_type_nsrect = {
	0, 0, FFI_TYPE_STRUCT, _ffi_type_nsrect_elements
};
#if NSUIntegerMax == ULONG_MAX
ffi_type *_ffi_type_nsrange_elements[] = {
	&ffi_type_ulong, &ffi_type_ulong, NULL
};
#else
ffi_type *_ffi_type_nsrange_elements[] = {
	&ffi_type_uint, &ffi_type_uint, NULL
};
#endif
ffi_type ffi_type_nsrange = {
	0, 0, FFI_TYPE_STRUCT, _ffi_type_nsrange_elements
};

static ffi_type *FFITypeForObjCType(const char *typestr)
{
	LKSkipQualifiers(&typestr);

	switch(*typestr)
	{
		case 'B':
		case 'c':
			return &ffi_type_schar;
		case 'C':
			return &ffi_type_uchar;
		case 's':
			return &ffi_type_sshort;
		case 'S':
			return &ffi_type_ushort;
		case 'i':
			return &ffi_type_sint;
		case 'I':
			return &ffi_type_uint;
		case 'l':
			return &ffi_type_slong;
		case 'L':
			return &ffi_type_ulong;
		case 'q':
			return &ffi_type_sint64;
		case 'Q':
			return &ffi_type_uint64;
		case 'f': 
			return &ffi_type_float;
		case 'd':
			return &ffi_type_double;
		case ':': 
			return &ffi_type_pointer;
		case '{':
		{
			if (0 == strncmp(typestr, "{_NSRect", 8))
			{
				return &ffi_type_nsrect;
			} 
			else if (0 == strncmp(typestr, "{_NSRange", 9))
			{
				return &ffi_type_nsrange;
			}
			else if (0 == strncmp(typestr, "{_NSPoint", 9))
			{
				return &ffi_type_nspoint;
			}
			else if (0 == strncmp(typestr, "{_NSSize", 8))
			{
				return &ffi_type_nspoint;
			}
			[NSException raise: LKInterpreterException  
			            format: @"ObjC to FFI type conversion not supported for"
			                    "arbitrary structs"];
		}
		case 'v':
			return &ffi_type_void;
		case '@':
		case '#':
			return &ffi_type_pointer;
	}
	[NSException raise: LKInterpreterException  
	            format: @"ObjC to FFI type conversion not supported for '%c'",
	                    *typestr];
	return NULL;
}

static id BoxValue(void *value, const char *typestr)
{
	LKSkipQualifiers(&typestr);
	
	switch(*typestr)
	{
		case 'B':
			return [BigInt bigIntWithLong: *(BOOL*)value];
		case 'c':
			return [BigInt bigIntWithLong: *(char*)value];
		case 'C':
			return [BigInt bigIntWithUnsignedLong: *(unsigned char*)value];
		case 's':
			return [BigInt bigIntWithLong: *(short*)value];
		case 'S':
			return [BigInt bigIntWithUnsignedLong: *(unsigned short*)value];
		case 'i':
			return [BigInt bigIntWithLong: *(int*)value];
		case 'I':
			return [BigInt bigIntWithUnsignedLong: *(unsigned int*)value];
		case 'l':
			return [BigInt bigIntWithLongLong: *(long*)value];
		case 'L':
			return [BigInt bigIntWithUnsignedLong: *(unsigned long*)value];
		case 'q': case 'Q': // FIXME: Incorrect for unsiged long long
			return [BigInt bigIntWithLongLong: *(long long*)value];
		case 'f': 
			return [NSNumber numberWithFloat: *(float*)value];
		case 'd':
			return [NSNumber numberWithDouble: *(double*)value];
		case ':': 
			return [Symbol SymbolForSelector: *(SEL*)value];
		case '{':
		{
			if (0 == strncmp(typestr, "{_NSRect", 8))
			{
				return [NSValue valueWithRect: *(NSRect*)value];
			} 
			else if (0 == strncmp(typestr, "{_NSRange", 9))
			{
				return [NSValue valueWithRange: *(NSRange*)value];
			}
			else if (0 == strncmp(typestr, "{_NSPoint", 9))
			{
				return [NSValue valueWithPoint: *(NSPoint*)value];
			}
			else if (0 == strncmp(typestr, "{_NSSize", 8))
			{
				return [NSValue valueWithSize: *(NSSize*)value];
			}
			[NSException raise: LKInterpreterException  
			            format: @"Boxing arbitrary structures doesn't work yet."];
		}
			// Map void returns to nil
		case 'v':
			return nil;
			// If it's already an object, we don't need to do anything
		case '@':
		case '#':
			return *(id*)value;
			// Other types, just wrap them up in an NSValue
		default:
			NSLog(@"Warning: using +[NSValue valueWithBytes:objCType:]");
			return [NSValue valueWithBytes: value objCType: typestr];
	}
}

static void UnboxValue(id value, void *dest, const char *objctype)
{
	LKSkipQualifiers(&objctype);

	switch(*objctype)
	{
		case 'c':
			*(char*)dest = [value charValue];
			break;
		case 'C':
			*(unsigned char*)dest = [value unsignedCharValue];
			break;
		case 's':
			*(short*)dest = [value shortValue];
			break;
		case 'S':
			*(unsigned short*)dest = [value unsignedShortValue];
			break;
		case 'i':
			*(int*)dest = [value intValue];
			break;
		case 'I':
			*(unsigned int*)dest = [value unsignedIntValue];
			break;
		case 'l':
			*(long*)dest = [value longValue];
			break;
		case 'L':
			*(unsigned long*)dest = [value unsignedLongValue];
			break;
		case 'q':
			*(long long*)dest = [value longLongValue];
			break;
		case 'Q':
			*(unsigned long long*)dest = [value unsignedLongLongValue];
			break;
		case 'f':
			*(float*)dest = [value floatValue];
			break;
		case 'd':
			*(double*)dest = [value doubleValue];
			break;
		case 'B':
			*(BOOL*)dest = [value boolValue];
			break;
		case ':':
			*(SEL*)dest = [value selValue];
			break;
		case '#':
		case '@':
			*(id*)dest = value;
			return;
		case 'v':
			*(id*)dest = NULL;
			return;
		case '{':
		{
			if (0 == strncmp(objctype, "{_NSRect", 8))
			{
				*(NSRect*)dest = [value rectValue];
				break;
			}
			else if (0 == strncmp(objctype, "{_NSRange", 9))
			{
				*(NSRange*)dest = [value rangeValue];
				break;
			}
			else if (0 == strncmp(objctype, "{_NSPoint", 9))
			{
				*(NSPoint*)dest = [value pointValue];
				break;
			}
			else if (0 == strncmp(objctype, "{_NSSize", 8))
			{
				*(NSSize*)dest = [value sizeValue];
				break;
			}
		}
		default:
			[NSException raise: LKInterpreterException  
			            format: @"Unable to transmogriy object to"
			                    "compound type: %s\n", objctype];
	}
}

id LKSendMessage(NSString *className, id receiver, NSString *selName,
                 unsigned int argc, id *args)
{
	if (receiver == nil)
	{
		return nil;
	}
	SEL sel = sel_getUid([selName UTF8String]);
	NSMethodSignature *sig = [receiver methodSignatureForSelector: sel];
	if (nil == sig)
	{
		[NSException raise: LKInterpreterException
		            format: @"Couldn't determine type for selector %@", selName];
	}
	if (argc + 2 != [sig numberOfArguments])
	{
		[NSException raise: LKInterpreterException
					format: @"Tried to call %@ with %d arguments", selName, argc];
	}
	
	Class receiverClass;
	if (class_isMetaClass(object_getClass(receiver)))
	{
		receiverClass = object_getClass(NSClassFromString(className));
	}
	else
	{
		receiverClass = NSClassFromString(className);
	}
	
	void *methodIMP;
	if (*[sig methodReturnType] == '{')
	{
		methodIMP = class_getMethodImplementation_stret(receiverClass, sel);		
	}
	else
	{
		methodIMP = class_getMethodImplementation(receiverClass, sel);
	}
	
	// Prepare FFI types
	const char *returnObjCType = [sig methodReturnType];
	ffi_type *ffi_ret_ty = FFITypeForObjCType(returnObjCType);
	ffi_type *ffi_tys[argc + 2];
	for (unsigned int i = 0; i < (argc + 2); i++)
	{
		const char *objCType = [sig getArgumentTypeAtIndex: i];
		ffi_tys[i] = FFITypeForObjCType(objCType);
	}
	
	ffi_cif cif;
	if (FFI_OK != ffi_prep_cif(&cif,  FFI_DEFAULT_ABI, argc + 2, ffi_ret_ty, ffi_tys))
	{
		[NSException raise: LKInterpreterException
		            format: @"Error preparing call signature"];
	}
	
	// Prepare actual args. Use more space than needed
	char unboxedArgumentsBuffer[[sig numberOfArguments]][[sig frameLength]];
	void *unboxedArguments[[sig numberOfArguments]];
	unboxedArguments[0] = &receiver;
	unboxedArguments[1] = &sel;
	for (unsigned int i = 0; i < argc; i++)
	{
		const char *objCType = [sig getArgumentTypeAtIndex: i + 2];
		UnboxValue(args[i], unboxedArgumentsBuffer[i + 2], objCType);
		unboxedArguments[i + 2] = unboxedArgumentsBuffer[i + 2];
	}	
	
	char msgSendRet[[sig methodReturnLength]];
	ffi_call(&cif, methodIMP, &msgSendRet, unboxedArguments);
	
	return BoxValue(msgSendRet, [sig methodReturnType]);
}


id LKGetIvar(id receiver, NSString *name)
{
	Ivar ivar = class_getInstanceVariable([receiver class], [name UTF8String]);
	void *ivarAddress = (char*)receiver +ivar_getOffset(ivar);
	id result = BoxValue(ivarAddress, ivar_getTypeEncoding(ivar));
	return result;
}

void LKSetIvar(id receiver, NSString *name, id value)
{
	Ivar ivar = class_getInstanceVariable([receiver class], [name UTF8String]);
	void *ivarAddress = (char*)receiver + ivar_getOffset(ivar);
	const char *encoding = ivar_getTypeEncoding(ivar);
	if (encoding[0] == '@')
	{
		ASSIGN(*((id*)ivarAddress), value);
	}
	else
	{
		UnboxValue(value, ivarAddress, encoding);
	}
}

static void LKInterpreterFFITrampoline(ffi_cif *cif, void *ret, 
                                       void **args, void *user_data)
{
	const char *objctype = (const char*)user_data;
	
	id receiver = *((id*)args[0]);
	SEL cmd = *((SEL*)args[1]);
	LKMethod *methodASTNode = LKASTForMethod(object_getClass(receiver),
		[NSString stringWithUTF8String: sel_getName(cmd)]);
	
	id returnObject;
	if (cif->nargs - 2 == 0)
	{
		returnObject = [methodASTNode executeWithReciever: receiver
		                                        arguments: NULL
		                                            count: 0];
	}
	else 
	{
		id argumentObjects[cif->nargs - 2];
		
		const char *argtypes = objctype;
		// Skip the return type, recevier type, and selector type
		LKNextType(&argtypes);
		LKNextType(&argtypes);
		LKNextType(&argtypes);
		for (unsigned int i=0; i<cif->nargs - 2; i++)
		{
			argumentObjects[i] = BoxValue(args[i+2], argtypes);
			LKNextType(&argtypes);
		}
		returnObject = [methodASTNode executeWithReciever: receiver
		                                        arguments: argumentObjects
		                                            count: cif->nargs - 2];
	}
	
	UnboxValue(returnObject, ret, objctype);
}

IMP LKInterpreterIMPForType(NSString *typestr)
{
	// FIXME: use a map table
	if (nil == _InterpreterIMPs)
	{
		_InterpreterIMPs = [[NSMutableDictionary alloc] init];
	}
	if (nil != [_InterpreterIMPs objectForKey: typestr])
	{
		return (IMP)[[_InterpreterIMPs objectForKey: typestr] pointerValue];
	}
	
	const char *objctype = [typestr UTF8String];
	int nargs = LKCountObjCTypes(objctype);
	ffi_type *ffi_ret_ty;
	ffi_type **ffi_tys = malloc((nargs - 1) * sizeof(ffi_type*));
	
	ffi_ret_ty = FFITypeForObjCType(objctype);
	LKNextType(&objctype);
	for (unsigned int i=0; i<nargs-1; i++)
	{
		ffi_tys[i] = FFITypeForObjCType(objctype);
		LKNextType(&objctype);
	}
	
	ffi_cif *cif = malloc(sizeof(ffi_cif));
	if (FFI_OK != ffi_prep_cif(cif,
	                           FFI_DEFAULT_ABI, nargs - 1, ffi_ret_ty, ffi_tys))
	{
		[NSException raise: LKInterpreterException
		            format: @"Error preparing closure signature"];
	}
	
	void *user_data = strdup([typestr UTF8String]);
	ffi_closure *closure_exec;
	ffi_closure *closure_write = ffi_closure_alloc(sizeof(ffi_closure),
	                                               (void*)&closure_exec);
	if (FFI_OK != ffi_prep_closure_loc(closure_write, cif, 
	                                   LKInterpreterFFITrampoline, 
	                                   user_data, closure_exec))
	{
		[NSException raise: LKInterpreterException
		            format: @"Error preparing closure"];
	}
	
	[_InterpreterIMPs setObject: [NSValue valueWithPointer: closure_exec]
						 forKey: typestr];
	return (IMP)closure_exec;
}
