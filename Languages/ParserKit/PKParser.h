#import <Foundation/Foundation.h>

@interface PKParser: NSObject
{
	@private
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
