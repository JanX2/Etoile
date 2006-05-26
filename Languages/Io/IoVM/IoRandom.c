/*#io
Random ioDoc(
             docCopyright("Steve Dekorte", 2002)
             docLicense("BSD revised")
             docObject("Random")
             docDescription("""A high quality and reasonably fast random number generator based on Makoto Matsumoto, Takuji Nishimura, and Eric Landry's implementation of the Mersenne Twister algorithm.
<p>
Reference: 
<p>
<i>
M. Matsumoto and T. Nishimura, <br>
"Mersenne Twister: A 623-Dimensionally Equidistributed Uniform Pseudo-RandomGen Number
                            Generator", <br>
ACM Transactions on Modeling and Computer Simulation, Vol. 8, No. 1, January 1998, pp 3--30.
</i>""")
		   docCategory("Math")
             */

#include "IoRandom.h"
#include "IoNumber.h"
#include "RandomGen.h"
#include "BStream.h"

#define IVAR(self) ((RandomGen *)(IoObject_dataPointer(self)))

void IoRandom_writeToStore_stream_(IoRandom *self, IoStore *store, BStream *stream)
{
	RandomGen *r = IVAR(self);
	int i;
	
	for (i = 0; i < RANDOMGEN_N; i ++)
	{
		BStream_writeTaggedUint32_(stream, r->mt[i]);
	}
	
	BStream_writeTaggedUint32_(stream, r->mti);
}

void *IoRandom_readFromStore_stream_(IoRandom *self, IoStore *store, BStream *stream)
{
	RandomGen *r = IVAR(self);
	int i;
	
	for (i = 0; i < RANDOMGEN_N; i ++)
	{
		r->mt[i] = BStream_readTaggedUint32(stream);
	}
	
	r->mti = BStream_readTaggedUint32(stream);
	return self;
}

IoTag *IoRandom_tag(void *state)
{
	IoTag *tag = IoTag_newWithName_("Random");
	tag->state = state;
	tag->cloneFunc = (TagCloneFunc *)IoRandom_rawClone;
	tag->freeFunc  = (TagFreeFunc *)IoRandom_free;
	tag->writeToStoreOnStreamFunc  = (TagWriteToStoreOnStreamFunc *)IoRandom_writeToStore_stream_;
	tag->readFromStoreOnStreamFunc = (TagReadFromStoreOnStreamFunc *)IoRandom_readFromStore_stream_;
	return tag;
}

IoRandom *IoRandom_proto(void *state)
{
	IoMethodTable methodTable[] = {
	{"value", IoRandom_value},
	{"setSeed", IoRandom_setSeed},
	{NULL, NULL},
	};
	
	IoObject *self = IoObject_new(state);
	
	self->tag = IoRandom_tag(state);
	IoObject_setDataPointer_(self, RandomGen_new());
	
	RandomGen_init(IVAR(self), 0);
	
	IoState_registerProtoWithFunc_((IoState *)state, self, IoRandom_proto);
	
	IoObject_addMethodTable_(self, methodTable);
	return self;
}

IoNumber *IoRandom_rawClone(IoRandom *proto)
{
	IoObject *self = IoObject_rawClonePrimitive(proto);
	IoObject_setDataPointer_(self, RandomGen_new());
	memcpy(IVAR(self), IVAR(proto), sizeof(RandomGen));
	return self;
}

void IoRandom_free(IoMessage *self) 
{
	RandomGen_free(IVAR(self));
}

IoObject *IoRandom_value(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("value(optionalArg1, optionalArg2)", 
		   "If called with:
<ul>
<li> no arguments, it returns a floating point 
random Number between 0 and 1.
<li> one argument, it returns a floating point random 
Number between 0 and optionalArg1.
<li> two arguments, it returns a floating point random 
Number between optionalArg1 and optionalArg2.
</ul>
")
	*/
	
	double f = RandomGen_randomDouble(IVAR(self));
	double result = 0;
	
	if (IoMessage_argCount(m) > 0)
	{
		double a = IoMessage_locals_doubleArgAt_(m, locals, 0);
		
		if (IoMessage_argCount(m) > 1)
		{
			double b = IoMessage_locals_doubleArgAt_(m, locals, 1);
			
			if (a == b ) 
			{ 
				result = a; 
			} 
			else 
			{ 
				result = a + (b - a) * f; 
			}
		}
		else
		{
			if (a == 0) 
			{ 
				result = 0; 
			} 
			else 
			{ 
				result = a * f; 
			}
		}
	}
	else
	{
		result = f;
	}
	
	return IONUMBER(result);
}

IoObject *IoRandom_setSeed(IoObject *self, IoObject *locals, IoMessage *m)
{
	/*#io
	docSlot("setSeed(aNumber)", 
		   "Sets the random number generator seed to the unsign int version of aNumber.")
	*/
	
	unsigned long v = IoMessage_locals_longArgAt_(m, locals, 0);
	RandomGen_init(IVAR(self), v);
	return self;
}
