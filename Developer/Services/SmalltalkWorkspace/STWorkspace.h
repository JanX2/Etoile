#import <Cocoa/Cocoa.h>
#import <LanguageKit/LanguageKit.h>

@interface STWorkspace : NSDocument
{
  NSObject<LKParser> *_parser;
  LKInterpreterContext *_interpreterContext;
  NSTextView *_textView;
}

- (IBAction) doSelection: (id)sender;
- (IBAction) printSelection: (id)sender;

- (id) runCode: (NSString *)code;
- (NSRange) selectedRange;
- (NSString *) selectedString;

@end

@interface STWorkspace(CompilerDelegate)<LKCompilerDelegate>

- (BOOL)compiler: (LKCompiler*)aCompiler
generatedWarning: (NSString*)aWarning
         details: (NSDictionary*)info;

- (BOOL)compiler: (LKCompiler*)aCompiler
  generatedError: (NSString*)anError
         details: (NSDictionary*)info;

@end