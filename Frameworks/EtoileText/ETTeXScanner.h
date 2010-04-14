#import <Foundation/NSObject.h>

@protocol ETTeXScannerDelegate
- (void)beginCommand: (NSString*)aCommand;
- (void)beginOptArg;
- (void)endOptArg;
- (void)beginArgument;
- (void)endArgument;
- (void)handleText: (NSString*)aString;
@end

@protocol ETTeXParsing <ETTeXScannerDelegate, NSObject>
@property (nonatomic, assign) id<ETTeXParsing> parent;
@property (nonatomic, retain) id<ETText> text;
@end

@class ETTeXScanner;

@interface ETTeXParser : NSObject <ETTeXParsing>
{
	NSMutableDictionary *commandHandlers;
}
@property (nonatomic, retain) ETTeXScanner *scanner;
- (void)registerDelegate: (Class)aClass forCommand: (NSString*)command;
@end

@interface ETTeXScanner : NSObject
@property (assign, nonatomic) id<ETTeXScannerDelegate> delegate;
- (void) parseString: (NSString*)aString;
@end
