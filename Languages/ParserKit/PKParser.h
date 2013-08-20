#import <Foundation/Foundation.h>

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
