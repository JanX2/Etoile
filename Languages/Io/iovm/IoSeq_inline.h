/*   
docCopyright("Steve Dekorte", 2002)
docLicense("BSD revised")
*/

#ifdef IOSEQ_C 
#define IO_IN_C_FILE
#endif
#include "Common_inline.h"
#ifdef IO_DECLARE_INLINES

/*
IOINLINE int ISMUTABLESEQ(IoObject *self)
{
	return ISSEQ(self) && !(self->isSymbol);
}
*/

#undef IO_IN_C_FILE
#endif
