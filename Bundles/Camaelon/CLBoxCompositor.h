#ifndef __CLBoxCompositor_H__
#define __CLBoxCompositor_H__

#include "CLCompositor.h"

@interface CLBoxCompositor : CLCompositor
{
	CLFill fillType;
	NSColor* colorFill;
}
- (void) setFill: (CLFill) filling; 
- (void) setFillColor: (NSColor*) color; 
@end

#endif // __CLBoxCompositor_H__
