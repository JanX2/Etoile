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
	id paragraphType;
	BOOL isInParagraph;
	id root;
}
- (void)registerDelegate: (Class)aClass forCommand: (NSString*)command;
- (void)beginParagraph;
- (void)endParagraph;
- (void)addTextToParagraph: (NSString*)aString;
- root;
@end

@interface ETTeXScanner : NSObject
@property (assign, nonatomic) id<ETTeXScannerDelegate> delegate;
- (void) parseString: (NSString*)aString;
@end
