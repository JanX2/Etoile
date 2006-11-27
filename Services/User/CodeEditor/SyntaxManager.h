#import <AppKit/AppKit.h>

@class SyntaxHandler;

@interface SyntaxManager: NSObject
{
  NSArray *syntax;
}

+ (SyntaxManager *) syntaxManager;

/* filename and language can be nil for default syntax */
- (SyntaxHandler *) syntaxHandlerForFile: (NSString *) filename;
- (SyntaxHandler *) syntaxHandlerForLanguage: (NSString *) lauguage;

@end


