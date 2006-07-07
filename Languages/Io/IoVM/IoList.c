/*#io
List ioDoc(
           docCopyright("Steve Dekorte", 2002)
           docLicense("BSD revised")
           docObject("List")
           docInclude("_ioCode/List.io")
           docDescription("A mutable array of values. The first index is 0.")
		 docCategory("DataStructures")
           */

#include "IoList.h"
#include "IoObject.h"
#include "IoState.h"
#include "IoCFunction.h"
#include "IoSeq.h"
#include "IoState.h"
#include "IoNumber.h"
#include "IoBlock.h"
#include "Sorting.h"
#include <math.h>

#define LISTIVAR(self) ((List *)(IoObject_dataPointer(self)))

IoTag *IoList_tag(void *state)
{
	IoTag *tag = IoTag_newWithName_("List");
	tag->state = state;
	tag->freeFunc    = (TagFreeFunc *)IoList_free;
	tag->cloneFunc   = (TagCloneFunc *)IoList_rawClone;
	tag->markFunc    = (TagMarkFunc *)IoList_mark;
	tag->compareFunc = (TagCompareFunc *)IoList_compare;
	tag->writeToStoreOnStreamFunc  = (TagWriteToStoreOnStreamFunc *)IoList_writeToStore_stream_;
	tag->readFromStoreOnStreamFunc = (TagReadFromStoreOnStreamFunc *)IoList_readFromStore_stream_;
	return tag;
}

void IoList_writeToStore_stream_(IoObject *self, IoStore *store, BStream *stream)
{
	List *list = LISTIVAR(self);
	
	BStream_writeTaggedInt32_(stream, List_size(list));
	
	LIST_FOREACH(list, i, v,
		BStream_writeTaggedInt32_(stream, IoStore_pidForObject_(store, (IoObject *)v));
	);
}

void IoList_readFromStore_stream_(IoObject *self, IoStore *store, BStream *stream)
{
	List *list = LISTIVAR(self);
	int i, max = BStream_readTaggedInt32(stream);
	
	for (i = 0; i < max; i ++)
	{
		int pid = BStream_readTaggedInt32(stream);
		IoObject *v = IoStore_objectWithPid_(store, pid);
		List_append_(list, v);
	}    
}

IoList *IoList_proto(void *state)
{
	IoMethodTable methodTable[] = {
	{"with",        IoList_with},
	     
	// access 
	
	{"indexOf",     IoList_indexOf},  
	{"contains",    IoList_contains}, 
	{"containsIdenticalTo", IoList_containsIdenticalTo},
	{"capacity",    IoList_capacity},     
	{"size",        IoList_size},     
	
	// mutation 
	
	{"removeAll",   IoList_removeAll},     
	{"appendSeq",   IoList_appendSeq}, 
	{"append",      IoList_append},    
	{"prepend",     IoList_prepend},    
	{"push",        IoList_append},    
		
	{"addIfAbsent",    IoList_appendIfAbsent}, // old 
	{"appendIfAbsent", IoList_appendIfAbsent}, // old 
		
	{"remove",      IoList_remove},      
	{"pop",         IoList_pop},         
		
	{"atInsert",    IoList_atInsert},    
	{"at",          IoList_at},          
	{"atPut",       IoList_atPut},       
		
	{"removeAt",    IoList_removeAt},    
	{"swapIndices", IoList_swapIndices}, 
		
	{"preallocateToSize", IoList_preallocateToSize}, 
		
	{"first",          IoList_first},      
	{"last",           IoList_last},       
	{"slice",          IoList_slice},       
	{"sliceInPlace",   IoList_sliceInPlace},

		
	{"sortInPlace",           IoList_sortInPlace},     
	{"sortInPlaceBy",         IoList_sortInPlaceBy},   
	{"foreach",        IoList_foreach},  
	{"reverse",        IoList_reverse},  
	{"reverseForeach", IoList_reverseForeach}, 
	{NULL, NULL},
	};
	
	IoObject *self = IoObject_new(state);
	self->tag = IoList_tag(state);
	
	IoObject_setDataPointer_(self, List_new());
	IoState_registerProtoWithFunc_((IoState *)state, self, IoList_proto);
	
	IoObject_addMethodTable_(self, methodTable);
	return self;
}

IoList *IoList_rawClone(IoList *proto) 
{ 
	IoObject *self = IoObject_rawClonePrimitive(proto);
	self->tag = proto->tag;
	IoObject_setDataPointer_(self, List_clone(LISTIVAR(proto)));
	return self; 
}

IoList *IoList_new(void *state)
{
	IoObject *proto = IoState_protoWithInitFunction_((IoState *)state, IoList_proto);
	return IOCLONE(proto);
}

IoList *IoList_newWithList_(void *state, List *list)
{
	IoList *self = IoList_new(state);
	//printf("IoList_newWithList_ %p %p\n", (void *)self, (void *)list);
	List_free(IoObject_dataPointer(self));
	IoObject_setDataPointer_(self, list);
	return self;
}

void IoList_free(IoList *self) 
{
	if (NULL == LISTIVAR(self)) 
	{ 
		printf("IoList_free(%p) already freed\n", (void *)self);
		exit(1);
	}
	//printf("IoList_free(%p) List_free(%p)\n", (void *)self, (void *)LISTIVAR(self));
	
	List_free(LISTIVAR(self));
	IoObject_setDataPointer_(self, 0x0);

}

void IoList_mark(IoList *self) 
{ 
	LIST_FOREACH(LISTIVAR(self), i, item, IoObject_shouldMark(item));
}

int IoList_compare(IoObject *self, IoList *otherList)
{
	if (!ISLIST(otherList)) 
	{ 
		return -((ptrdiff_t)self->tag - (ptrdiff_t)otherList->tag); 
	}
	else
	{
		size_t s1 =  List_size(LISTIVAR(self));
		size_t s2 =  List_size(LISTIVAR(otherList));
		size_t i;
		
		if (s1 != s2) 
		{ 
			return s1 > s2 ? 1 : -1; 
		}
		
		for (i = 0; i < s1; i ++)
		{
			IoObject *v1 = LIST_AT_(LISTIVAR(self), i);
			IoObject *v2 = LIST_AT_(LISTIVAR(otherList), i);
			int c = IoObject_compare(v1, v2);
			
			if (c) 
			{ 
				return c; 
			}
		}
	}
	return 0;
}

List *IoList_rawList(IoList *self)
{ 
	return LISTIVAR(self); 
}

IoObject *IoList_rawAt_(IoObject *self, int i)
{ 
	return List_at_(LISTIVAR(self), i); 
}

void IoList_rawAt_put_(IoObject *self, int i, IoObject *v)
{
	List_at_put_(LISTIVAR(self), i, IOREF(v)); 
}

void IoList_rawAppend_(IoObject *self, IoObject *v)
{ 
	List_append_(LISTIVAR(self), IOREF(v)); 
}

void IoList_rawRemove_(IoObject *self, IoObject *v)
{ 
	List_remove_(LISTIVAR(self), IOREF(v)); 
}

void IoList_rawAddBaseList_(IoObject *self, List *otherList)
{
	List *list = LISTIVAR(self);	
	LIST_FOREACH(otherList, i, v, List_append_(list, IOREF((IoObject *)v)); );
}

void IoList_rawAddIoList_(IoObject *self, IoList *other)
{
	IoList_rawAddBaseList_(self, LISTIVAR(other));
}

size_t IoList_rawSize(IoList *self) 
{ 
	return List_size(LISTIVAR(self)); 
}

int IoList_rawIndexOf_(IoObject *self, IoObject *v)
{
	List *list = LISTIVAR(self);

	LIST_FOREACH(list, i, item, 
		if (IoObject_compare(v, (IoObject *)item) == 0) 
		{
			return i;
		}
	);
	
	return -1;
}

void IoList_checkIndex(IoObject *self, IoMessage *m, char allowsExtending, int index, const char *methodName)
{
	int max = List_size(LISTIVAR(self));
	
	if (allowsExtending)
	{
		max += 1;
	}
	
	if (index < 0 || index >= max)
	{
		IoState_error_(IOSTATE, m, "index out of bounds\n");
	}
}

// immutable -------------------------------------------------------- 

IoObject *IoList_with(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("with(anObject, ...)", 
		   "Returns a new List containing the arguments. ")
	*/
	
	int n, argCount = IoMessage_argCount(m);
	IoList *ioList = IOCLONE(self);
	
	for (n = 0; n < argCount; n ++)
	{
		IoObject *v = IoMessage_locals_valueArgAt_(m, locals, n);
		IoList_rawAppend_(ioList, v);
	}
	
	return ioList;
}


IoObject *IoList_indexOf(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("indexOf(anObject)", 
		   "Returns the index of the first occurrence of anObject 
in the receiver. Returns Nil if the receiver doesn't contain anObject. ")
	*/
	
	int count = IoMessage_argCount(m);
	
	IOASSERT(count, "remove requires at least one argument");
	
	{
		IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
		int i = IoList_rawIndexOf_(self, v);
		
		return i == -1 ? IONIL(self) : 
			(IoObject *)IONUMBER(IoList_rawIndexOf_(self, v));
	}
}

IoObject *IoList_contains(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("contains(anObject)", 
		   "Returns true if the receiver contains anObject, otherwise returns false. ")
	*/
	
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	return IOBOOL(self, IoList_rawIndexOf_(self, v) != -1);
}

IoObject *IoList_containsIdenticalTo(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("containsIdenticalTo(anObject)", 
		   "Returns true if the receiver contains a value identical to anObject, otherwise returns false. ")
	*/
	
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 0);
	return IOBOOL(self, List_contains_(LISTIVAR(self), v) != 0);
}

IoObject *IoList_capacity(IoObject *self, IoObject *locals, IoMessage *m)
{
    /*#io
	docSlot("capacity", "Returns the number of potential elements the receiver can hold before it needs to grow.")
    */
    return IONUMBER(LISTIVAR(self)->memSize / sizeof(void *));
}

IoObject *IoList_size(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("size", "Returns the number of items in the receiver. ")
	*/
	
	return IONUMBER(List_size(LISTIVAR(self))); 
}

IoObject *IoList_at(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("at(index)", 
		   "Returns the value at index. Returns Nil if the index is out of bounds. ")
	*/
	
	int index = IoMessage_locals_intArgAt_(m, locals, 0);
	IoObject *v;
	/*IoList_checkIndex(self, m, 0, index, "Io List at");*/
	v = List_at_(LISTIVAR(self), index);
	return (v) ? v : IONIL(self);
}

IoObject *IoList_first(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("first(optionalSize)", 
		   "Returns the first item or Nil if the list is empty. 
If optionalSize is provided, that number of the first items in the list are returned. ")
	*/
	
	if (IoMessage_argCount(m) == 0)
	{
		IoObject *result = List_at_(LISTIVAR(self), 0);
		
		return result ? result : ((IoState *)IOSTATE)->ioNil; 
	}
	else
	{
		int end = IoMessage_locals_intArgAt_(m, locals, 0);
		
		if (end < 0)
		{
			return IoList_new(IOSTATE);
		}
		else
		{
			List *list = List_cloneSlice(LISTIVAR(self), 0, end - 1);
			return IoList_newWithList_(IOSTATE, list);
		}
	}
}

IoObject *IoList_last(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("last(optionalSize)", 
		   "Returns the last item or Nil if the list is empty. 
If optionalSize is provided, that number of the last items in the list are returned. ")
	*/
	
	if (IoMessage_argCount(m) == 0)
	{
		IoObject *result = List_at_(LISTIVAR(self), List_size(LISTIVAR(self))-1);
		return result ? result : ((IoState *)IOSTATE)->ioNil;
	}
	else
	{
		size_t size = IoList_rawSize(self);
		int start = size - IoMessage_locals_intArgAt_(m, locals, 0);
		List *list;
		
		if (start < 0) 
		{
			start = 0;
		}
		
		list = List_cloneSlice(LISTIVAR(self), start, size);
		return IoList_newWithList_(IOSTATE, list);
	}
}

IoObject *IoList_slice(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("slice(startIndex, endIndex)", 
		   "Returns a new string containing the subset of the 
receiver from the startIndex to the endIndex. The endIndex argument 
is optional. If not given, it is assumed to be the end of the string. ")
	*/
	
	List *list;
	int start, end;
	
	start = IoMessage_locals_intArgAt_(m, locals, 0);
	
	if (IoMessage_argCount(m) == 2)
	{
		end = IoMessage_locals_intArgAt_(m, locals, 1);
	}
	else
	{
		end = IoList_rawSize(self);
	}
	
	list = List_cloneSlice(LISTIVAR(self), start, end);
	return IoList_newWithList_(IOSTATE, list);
}

IoObject *IoList_sliceInPlace(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("sliceInPlace(startIndex, endIndex)", 
		   "Returns the receiver containing the subset of the 
receiver from the startIndex to the endIndex. The endIndex argument 
is optional. If not given, it is assumed to be the end of the string. ")
	*/
	
	int start, end;
	
	start = IoMessage_locals_intArgAt_(m, locals, 0);
	
	if (IoMessage_argCount(m) == 2)
	{
		end = IoMessage_locals_intArgAt_(m, locals, 1);
	}
	else
	{
		end = IoList_rawSize(self);
	}
	
	List_sliceInPlace(LISTIVAR(self), start, end);
	return self;
}

IoObject *IoList_each(IoObject *self, IoObject *locals, IoMessage *m)
{	
	IoState *state = IOSTATE;
	IoObject *result = IONIL(self);
	IoMessage *doMessage = IoMessage_rawArgAt_(m, 0);
	List *list = LISTIVAR(self);
	
	IoState_pushRetainPool(state);
	
	LIST_SAFEFOREACH(list, i, v, 
		IoState_clearTopPool(state);
		result = IoMessage_locals_performOn_(doMessage, locals, (IoObject *)v);
		if (IoState_handleStatus(IOSTATE)) goto done;
	);
	
done:
	IoState_popRetainPoolExceptFor_(state, result);
	return result;
}


IoObject *IoList_foreach(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("foreach(optionalIndex, value, message)", 
		   """Loops over the list values setting the specified index and 
value slots and executing the message. Returns the result of the last 
execution of the message. Example:
<pre>list(1, 2, 3) foreach(i, v, writeln(i, " = ", v))
list(1, 2, 3) foreach(v, writeln(v))</pre>
""")
	*/
	
	IoState *state = IOSTATE;
	IoObject *result = IONIL(self);
	IoSymbol *slotName = 0x0;
	IoSymbol *valueName;
	IoMessage *doMessage;
	List *list = LISTIVAR(self);
	
	if (IoMessage_argCount(m) == 1)
	{
		return IoList_each(self, locals, m);
	}
	
	IoMessage_foreachArgs(m, self, &slotName, &valueName, &doMessage);
	
	IoState_pushRetainPool(state);

	if (slotName)
	{
		LIST_SAFEFOREACH(list, i, value,
			IoState_clearTopPool(state);
			IoObject_setSlot_to_(locals, slotName, IONUMBER(i));
			IoObject_setSlot_to_(locals, valueName, (IoObject *)value);
			result = IoMessage_locals_performOn_(doMessage, locals, locals);
			if (IoState_handleStatus(IOSTATE)) goto done;
		);
	} 
	else
	{
		LIST_SAFEFOREACH(list, i, value,
				   IoState_clearTopPool(state);
				   IoObject_setSlot_to_(locals, valueName, (IoObject *)value);
				   result = IoMessage_locals_performOn_(doMessage, locals, locals);
				   if (IoState_handleStatus(IOSTATE)) goto done;
				   );			
	}

done:
		IoState_popRetainPoolExceptFor_(state, result);
	return result;
}

IoObject *IoList_reverseForeach(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("reverseForeach(index, value, message)", "Same as foreach, but in reverse order.")
	*/
	
	IoState *state = IOSTATE;
	IoObject *result = IONIL(self);
	IoSymbol *slotName, *valueName;
	IoMessage *doMessage;
	int i;
	
	IoMessage_foreachArgs(m, self, &slotName, &valueName, &doMessage);
	
	IoState_pushRetainPool(state);
	
	for (i = List_size(LISTIVAR(self)) - 1; i >= 0; i --)
	{
		IoState_clearTopPool(state);
		{
			IoObject *value = (IoObject *)LIST_AT_(LISTIVAR(self), i);
			
			if (slotName)
			{
				IoObject_setSlot_to_(locals, slotName, IONUMBER(i));
			}
			
			IoObject_setSlot_to_(locals, valueName, value);
			result = IoMessage_locals_performOn_(doMessage, locals, locals);
			
			if (IoState_handleStatus(IOSTATE)) 
			{
				goto done;
			}
		}
		if(i > List_size(LISTIVAR(self)) - 1) { i = List_size(LISTIVAR(self)) - 1; }
	}
done:
		IoState_popRetainPoolExceptFor_(state, result);
	return result;
}

// mutable -------------------------------------------------------- 

IoObject *IoList_appendIfAbsent(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("appendIfAbsent(anObject)", 
		   "Adds each value not already contained by the receiver, returns self. ")
	*/
	
	int n;
	
	for (n = 0; n < IoMessage_argCount(m); n ++)
	{
		IoObject *v = IoMessage_locals_valueArgAt_(m, locals, n);
		
		if (IoList_rawIndexOf_(self, v) == -1)
		{
			IoState_stackRetain_(IOSTATE, v);
			List_append_(LISTIVAR(self), IOREF(v));
		}
	}
	
	return self;
}

IoObject *IoList_appendSeq(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("appendSeq(aList1, aList2, ...)", 
		   "Add the items in the lists to the receiver. Returns self.")
	*/
	
	int i;
	
	for (i = 0; i < IoMessage_argCount(m); i ++)
	{
		IoObject *other = IoMessage_locals_valueArgAt_(m, locals, i);
		
		IOASSERT(ISLIST(other), "requires List objects as arguments");
		
		if (other == self)
		{
			IoState_error_(IOSTATE, m, "can't add a list to itself\n");
		}
		else
		{
			List *selfList  = LISTIVAR(self);
			List *otherList = LISTIVAR(other);
			int i, max = List_size(otherList);
			
			for (i = 0; i < max; i ++)
			{
				IoObject *v = List_at_(otherList, i);
				List_append_(selfList, IOREF(v));
			}
		}
	}
	return self;
}

IoObject *IoList_append(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("append(anObject1, anObject2, ...)", 
		   """Appends the arguments to the end of the list. Returns self.""")
	*/
	/*#io
	docSlot("push(anObject1, anObject2, ...)", 
		   "Same as add(anObject1, anObject2, ...).")
	*/
	
	int n;
	
	IOASSERT(IoMessage_argCount(m), "requires at least one argument");
	
	for (n = 0; n < IoMessage_argCount(m); n ++)
	{
		IoObject *v = IoMessage_locals_valueArgAt_(m, locals, n);
		List_append_(LISTIVAR(self), IOREF(v));
	}
	
	return self;
}

IoObject *IoList_prepend(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("prepend(anObject1, anObject2, ...)", 
		   "Inserts the values at the beginning of the list. Returns self.")
	*/
	
	int n;
	
	IOASSERT(IoMessage_argCount(m), "requires at least one argument");
	
	for (n = 0; n < IoMessage_argCount(m); n ++)
	{
		IoObject *v = IoMessage_locals_valueArgAt_(m, locals, n);
		List_at_insert_(LISTIVAR(self), 0, IOREF(v));
	}
	
	return self;
}


IoObject *IoList_remove(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("remove(anObject, ...)", 
		   "Removes all occurrences of the arguments from the receiver. Returns self. ")
	*/
	
	int count = IoMessage_argCount(m);
	int j;
	
	IOASSERT(count, "requires at least one argument");

	for (j = 0; j < count; j++)
	{
		IoObject *v = IoMessage_locals_valueArgAt_(m, locals, j);

		// a quick pass to remove values with equal pointers 
		List_remove_(LISTIVAR(self), v); 
		
		// slow pass to remove values that match comparision test 
		for (;;)
		{
			int i = IoList_rawIndexOf_(self, v);
			
			if (i == -1)
			{
				break;
			}
			
			List_removeIndex_(LISTIVAR(self), i);
		}
	}
	
	return self;
}

IoObject *IoList_pop(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("pop", 
		   "Returns the last item in the list and removes it 
from the receiver. Returns nil if the receiver is empty. ")
	*/
	
	IoObject *v = List_pop(LISTIVAR(self));
	return (v) ? v : IONIL(self);
}

IoObject *IoList_atInsert(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*
	 docSlot("atInsert(index, anObject)", 
		    "Inserts anObject at the index specified by index. 
	 Adds anObject if the index equals the current count of the receiver. 
	 Raises an exception if the index is out of bounds. Returns self. ")
	 */
	
	int index = IoMessage_locals_intArgAt_(m, locals, 0);
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 1);
	
	IoList_checkIndex(self, m, 1, index, "List atInsert");
	List_at_insert_(LISTIVAR(self), index, IOREF(v));
	return self;
}

IoObject *IoList_removeAt(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("removeAt(index)", 
		   "Removes the item at the specified index and returns the value removed. 
Raises an exception if the index is out of bounds. ")
	*/
	
	int index = IoMessage_locals_intArgAt_(m, locals, 0);
	IoObject *v = List_at_(LISTIVAR(self), index);
	
	IoList_checkIndex(self, m, 0, index, "Io List atInsert");
	List_removeIndex_(LISTIVAR(self), index);
	return (v) ? v : IONIL(self);
}

void IoList_rawAtPut(IoObject *self, int i, IoObject *v)
{
	while (List_size(LISTIVAR(self)) < i) /* not efficient */
	{ 
		List_append_(LISTIVAR(self), IONIL(self)); 
	} 
	
	List_at_put_(LISTIVAR(self), i, IOREF(v));
}

IoObject *IoList_atPut(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("atPut(index, anObject)", 
		   "Replaces the existing value at index with anObject. 
Raises an exception if the index is out of bounds. Returns self.")
	*/
	
	int index = IoMessage_locals_intArgAt_(m, locals, 0);
	IoObject *v = IoMessage_locals_valueArgAt_(m, locals, 1);
	
	IoList_checkIndex(self, m, 0, index, "Io List atPut");
	IoList_rawAtPut(self, index, v);
	return self;
}

IoObject *IoList_removeAll(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("empty", "Removes all items from the receiver.") 
	*/
	
	List_removeAll(LISTIVAR(self)); 
	return self;
}

IoObject *IoList_swapIndices(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("swapIndices(index1, index2)", 
		   "Exchanges the object at index1 with the object at index2. 
Raises an exception if either index is out of bounds. Returns self.")
	*/
	
	int i = IoMessage_locals_intArgAt_(m, locals, 0);
	int j = IoMessage_locals_intArgAt_(m, locals, 1);
	
	IoList_checkIndex(self, m, 0, i, "List swapIndices");
	IoList_checkIndex(self, m, 0, j, "List swapIndices");
	List_swap_with_(LISTIVAR(self), i, j);
	return self;
}

IoObject *IoList_reverse(IoObject *self, IoObject *locals, IoMessage *m)
{ 
	/*#io
	docSlot("reverse", 
		   "Reverses the ordering of all the items in the receiver. Returns self.") 
	*/
	
	List_reverse(LISTIVAR(self)); 
	return self; 
}

IoObject *IoList_preallocateToSize(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("preallocateToSize(aNumber)", 
		   "Preallocate array memory to hold aNumber number of items.")
	*/
	
	int newSize = IoMessage_locals_intArgAt_(m, locals, 0);
	List_preallocateToSize_(LISTIVAR(self), newSize);
	return self;
}

// sorting -----------------------------------------------

typedef struct
{
	IoState *state;
	IoObject *locals;
	IoMessage *exp;
	List *list;
} MSortContext;

int MSortContext_compareForSort(MSortContext *self, int i, int j)
{
	IoObject *a = List_at_(self->list, i);
	IoObject *b = List_at_(self->list, j);
	int r;
	
	IoState_pushRetainPool(self->state);
	
	a = IoMessage_locals_performOn_(self->exp, self->locals, a);
	b = IoMessage_locals_performOn_(self->exp, self->locals, b);
	r = IoObject_compare(a, b);
	
	IoState_popRetainPool(self->state);
	return r;
}

void MSortContext_swapForSort(MSortContext *self, int i, int j)
{ 
	List_swap_with_(self->list, i, j); 
}

IoObject *IoList_sortInPlace(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("sortInPlace(optionalExpression)", 
		   "Sorts the list using the compare method on the items. Returns self.
If an optionalExpression is provided, the sort is done on the result of the evaluation 
of the optionalExpression on each value.")
	*/
	
	if (IoMessage_argCount(m) == 0)
	{
		List_qsort(LISTIVAR(self), (ListSortCallback *)IoObject_sortCompare);
	} 
	else 
	{
		MSortContext sc;
		MSortContext *sortContext = &sc; 
		sortContext->state = IOSTATE;
		
		sortContext->list = LISTIVAR(self);
		sortContext->locals = locals;
		sortContext->exp = IoMessage_rawArgAt_(m, 0);
		
		Sorting_context_comp_swap_size_type_(sortContext, 
										(SDSortCompareCallback *)MSortContext_compareForSort, 
										(SDSortSwapCallback *)MSortContext_swapForSort, 
										List_size(LISTIVAR(self)), SDQuickSort);    
		
	}
	
	return self;
}

typedef struct
{
	IoState *state;
	IoObject *locals;
	IoBlock *block;
	IoMessage *blockMsg;
	IoMessage *argMsg1;
	IoMessage *argMsg2;
	List *list;
} SortContext;

int SortContext_compareForSort(SortContext *self, int i, int j)
{
	IoObject *cr;
	IoState_pushRetainPool(self->state);
	
	IoMessage_cachedResult_(self->argMsg1, LIST_AT_(self->list, i));
	IoMessage_cachedResult_(self->argMsg2, LIST_AT_(self->list, j));
	cr = IoBlock_activate(self->block, self->locals, self->locals, self->blockMsg, self->locals);
	//cr = IoMessage_locals_performOn_(self->block->message, self->locals, self->locals);
	
	IoState_popRetainPool(self->state);
	return ISFALSE(cr) ? 1 : -1;
}

void SortContext_swapForSort(SortContext *self, int i, int j)
{ 
	List_swap_with_(self->list, i, j); 
}

IoObject *IoList_sortInPlaceBy(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("sortBy(aBlock)", 
		   "Sort the list using aBlock as the compare function. Returns self.")
	*/
	
	SortContext sc;
	SortContext *sortContext = &sc; 
	sortContext->state = IOSTATE;
	
	sortContext->list = LISTIVAR(self);
	sortContext->locals = locals;
	sortContext->block = IoMessage_locals_blockArgAt_(m, locals, 0);
	sortContext->blockMsg = IoMessage_new(IOSTATE);
	sortContext->argMsg1  = IoMessage_new(IOSTATE);
	sortContext->argMsg2  = IoMessage_new(IOSTATE);
	
	IoMessage_addArg_(sortContext->blockMsg, sortContext->argMsg1);
	IoMessage_addArg_(sortContext->blockMsg, sortContext->argMsg2);
	
	Sorting_context_comp_swap_size_type_(sortContext, 
									(SDSortCompareCallback *)SortContext_compareForSort, 
									(SDSortSwapCallback *)SortContext_swapForSort, 
									List_size(LISTIVAR(self)), SDQuickSort);
	
	return self;
}
