#include "Index/LCTermEnum.h"
#include "Index/LCTerm.h"

/** Abstract class for enumerating terms.

  <p>Term enumerations are always ordered by Term.compareTo().  Each term in
  the enumeration is greater than all that precede it.  */

@implementation LCTermEnum

  /** Increments the enumeration to the next element.  True if one exists.*/
- (BOOL) next
{
  return NO;
}

  /** Returns the current Term in the enumeration.*/
- (LCTerm *) term
{
  return nil;
}

  /** Returns the docFreq of the current Term in the enumeration.*/
- (long) docFreq
{
  return -1;
}

  /** Closes the enumeration to further activity, freeing resources. */
- (void) close
{
}
  
// Term Vector support
  
  /** Skips terms to the first beyond the current whose value is
   * greater or equal to <i>target</i>. <p>Returns true iff there is such
   * an entry.  <p>Behaves as if written: <pre>
   *   public boolean skipTo(Term target) {
   *     do {
   *       if (!next())
   * 	     return false;
   *     } while (target > term());
   *     return true;
   *   }
   * </pre>
   * Some implementations are considerably more efficient than that.
   */
- (BOOL) skipTo: (LCTerm *) target
{
  do {
    if (![self next])
      return NO;
  } while ([target compare: [self term]] == NSOrderedDescending);
  // } while (target.compareTo(term()) > 0);

  return YES;
}

@end
