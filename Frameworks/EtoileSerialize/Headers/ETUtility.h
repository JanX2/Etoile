/**
 * <author name="David Chisnall"></author>
 */
#import <Foundation/Foundation.h>

/** 
 * Turn a pointer into a CORef.
 */
//TODO: 64-bit version of this.
#define COREF_FROM_ID(x) ((CORef)(unsigned long)x)
/**
 * CoreObject reference type, used to uniquely identify serialized objects
 * within a serialized object graph.
 */
typedef uint32_t CORef;
