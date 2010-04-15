#import <Foundation/NSObject.h>

@protocol ETTeXScannerDelegate
- (void)beginCommand: (NSString*)aCommand;
- (void)beginOptArg;
- (void)endOptArg;
- (void)beginArgument;
- (void)endArgument;
- (void)handleText: (NSString*)aString;
@end

@class ETTeXScanner;
@class ETTextTreeBuilder;
@class ETTextDocument;
@class NSMutableSet;
@class NSMutableDictionary;

@protocol ETTeXParsing <ETTeXScannerDelegate, NSObject>
@property (nonatomic, assign) id<ETTeXParsing> parent;
@property (nonatomic, retain) ETTextTreeBuilder *builder;
@property (nonatomic, retain) ETTextDocument *document;
@property (nonatomic, retain) ETTeXScanner *scanner;
@end

@interface ETTeXParser : NSObject <ETTeXParsing>
{
	NSMutableDictionary *commandHandlers;
	NSMutableSet *unknownTags;
}
- (void)registerDelegate: (Class)aClass forCommand: (NSString*)command;
@end

@interface ETTeXScanner : NSObject
@property (assign, nonatomic) id<ETTeXScannerDelegate> delegate;
- (void) parseString: (NSString*)aString;
@end
