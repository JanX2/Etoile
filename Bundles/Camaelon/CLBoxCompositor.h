#ifndef __CLBoxCompositor_H__
#define __CLBoxCompositor_H__

#include "CLCompositor.h"

@interface CLBoxCompositor : CLCompositor
{
	CLFill fillType;
	NSColor* colorFill;
	float topHeight;
	float bottomHeight;
}
- (float) topHeight;
- (float) bottomHeight;
- (void) setFill: (CLFill) filling; 
- (void) setFillColor: (NSColor*) color; 
@end

#endif // __CLBoxCompositor_H__
