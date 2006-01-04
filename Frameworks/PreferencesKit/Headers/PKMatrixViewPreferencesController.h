#ifndef __PKMatrixViewPresentation__
#define __PKMatrixViewPresentation__

#include "PKPresentationBuilder.h"

@class PKMatrixView;

@interface PKMatrixViewPresentation : PKPresentationBuilder
{
  PKMatrixView *matrixView;
  NSArray *identifiers;
}

@end

#endif /* __PKMatrixViewPresentation__ */
