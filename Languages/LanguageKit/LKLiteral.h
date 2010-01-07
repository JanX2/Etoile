#import "LKAST.h"

@interface LKLiteral : LKAST {
  /** String representation of value.  Used because this can be a literal too
   * big to fit in a SmallInt. */
  NSString * value;
}
+ (id) literalFromString:(NSString*)aString;
@end

@interface LKNumberLiteral : LKLiteral {}
/**
 * Creates a constant literal with the specified name.
 */
+ (id) literalFromSymbol:(NSString*)aString;
@end

/**
 * Floating point literal value.
 */
@interface LKFloatLiteral : LKNumberLiteral @end

@interface LKStringLiteral : LKLiteral {}
@end
