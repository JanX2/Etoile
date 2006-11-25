#import <AppKit/AppKit.h>

@class SyntaxHandler;

@interface SyntaxManager: NSObject
{
  NSArray *syntax;
}

+ (SyntaxManager *) syntaxManager;

- (SyntaxHandler *) syntaxHandlerForFile: (NSString *) filename;
- (SyntaxHandler *) syntaxHandlerForLanguage: (NSString *) lauguage;

@end


