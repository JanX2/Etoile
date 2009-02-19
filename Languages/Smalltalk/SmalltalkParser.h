#import <EtoileFoundation/EtoileFoundation.h>

@class LKAST;
@protocol LKParser;

/**
 * Smalltalk parser class.  This class implements a tokeniser and calls a
 * parser created using the Lemon parser generator.
 */
@interface SmalltalkParser : NSObject <LKParser> {
  LKAST *ast;
}
/**
 * Used by the Lemon implementation to feed the generated AST back so the
 * Parser can return it.
 */
- (void) setAST:(LKAST*)ast;
@end
