#import <Foundation/NSObject.h>

@protocol ETTeXScannerDelegate
- (void)beginCommand: (NSString*)aCommand;
- (void)beginOptArg;
- (void)endOptArg;
- (void)beginArgument;
- (void)endArgument;
- (void)handleText: (NSString*)aString;
@end

@interface ETTeXScanner : NSObject
@property (assign, nonatomic) id<ETTeXScannerDelegate> delegate;
- (void) parseString: (NSString*)aString;
@end
