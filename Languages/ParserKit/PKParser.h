#import <Foundation/Foundation.h>
#import <LanguageKit/LanguageKit.h>
@interface PKParser: NSObject
{
	id input;
	id rules;
	id delegate;
}

+ (BOOL)supportsGrammar: (NSString*)grammarName;

+ (NSArray*)loadGrammarsFromBundle: (NSBundle*)bundle;

+ (NSArray*)loadGrammarsFromString: (NSString*)string;

- (id)initWithGrammar: (NSString*)grammarName;

- (void)setDelegate: (id)delegate;

- (id)match: (id)inputStream rule: (NSString*)ruleName;

- (id)getEmptyMatch: (id) list;
@end

@interface PKInputStream : NSObject
{
	id memo;
	id stream;
	id position;
	id positionStack;
	id environmentStack;
}
- (id) position;
- (unsigned long long) length;
- (id) stream;
-(id) lastPosition;
- (id) initWithStream: (id) input;
@end

@interface PKParseMatch : NSObject
{
	id input;
	id range;
	id action;
	id delegate;
}
- (id) sequenceWith: (id) match;
- (id) initWithInput: (id) list length: (id) length;
- (id) isSuccess;
- (id) isFailure;
- (id) isEmpty;
- (id) matchText;
@end

@interface PKParserAbstractGenerator : NSObject
{
	id delegate;
	id specialCharToChar;
}
@end


@interface PKParserASTGenerator : PKParserAbstractGenerator
{
	id externalParsers;
	id inputStreamDeclaration;
	id tempDecl;
	id methodStatements;
	id currentTempsCount;
}
 
- (id)genTemp;
@end

@interface PKEnvironmentStack : NSObject
@end


