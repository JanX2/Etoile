/*#io
docCopyright("Steve Dekorte", 2002)
docLicense("BSD revised")
*/

#ifdef COLLECTOR_C 
#define IO_IN_C_FILE
#endif
#include "Common_inline.h"
#ifdef IO_DECLARE_INLINES

// inspecting markers -------------------

IOINLINE int Collector_markerIsWhite_(Collector *self, CollectorMarker *m)
{
	return (self->whites->color == m->color);
}

IOINLINE int Collector_markerIsGray_(Collector *self, CollectorMarker *m)
{
	return (COLLECTOR_GRAY == m->color);
}

IOINLINE int Collector_markerIsBlack_(Collector *self, CollectorMarker *m)
{
	return (self->blacks->color == m->color);
}

// changing marker colors -------------------

IOINLINE void Collector_makeWhite_(Collector *self, void *v)
{ 
	CollectorMarker_removeAndInsertAfter_((CollectorMarker*)v, self->whites);
}

IOINLINE void Collector_makeGray_(Collector *self, void *v)
{
	CollectorMarker_removeAndInsertAfter_((CollectorMarker*)v, self->grays);
}

IOINLINE void Collector_makeBlack_(Collector *self, void *v)
{ 
	CollectorMarker_removeAndInsertAfter_((CollectorMarker*)v, self->blacks);
}

IOINLINE void Collector_makeGrayIfWhite_(Collector *self, void *v)
{
	if (Collector_markerIsWhite_(self, (CollectorMarker*)v)) 
	{
		Collector_makeGray_(self, v);
	}
}

/*
 IOINLINE void Collector_makeFreed_(Collector *self, void *v)
 { 
	 CollectorMarker_removeAndInsertAfter_(v, self->freed);
 }
 */
 
IOINLINE void *Collector_value_addingRefTo_(Collector *self, void *v, void *ref)
{	 
	if (Collector_markerIsBlack_(self, (CollectorMarker*)v) && Collector_markerIsWhite_(self, (CollectorMarker*)ref))
	{
		Collector_makeGray_(self, ref);
	}
	
	return ref;
}

#undef IO_IN_C_FILE
#endif
