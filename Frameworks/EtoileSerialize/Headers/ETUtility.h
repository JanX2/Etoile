/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>

/**
 * Macros to turn a pointer into a CORef.
 */
#if defined (__LP64__)
	#define COREF_FROM_ID(x) [[ESCORefTable sharedCORefTable] CORefFromPointer: x]
	#define COREF_TABLE_USE [[ESCORefTable sharedCORefTable] use];
	#define COREF_TABLE_DONE [[ESCORefTable sharedCORefTable] done];
#else
	#define COREF_FROM_ID(x) ((CORef)(unsigned long)x)
	#define COREF_TABLE_USE 
	#define COREF_TABLE_DONE
#endif

/**
 * CoreObject reference type, used to uniquely identify serialized objects
 * within a serialized object graph.
 */
typedef uint32_t CORef;

