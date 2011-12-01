#import "SCKSyntaxHighlighter.h"
#import <Cocoa/Cocoa.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "SCKTextTypes.h"
#include <time.h>

static NSDictionary *noAttributes;

@implementation SCKSyntaxHighlighter
@synthesize tokenAttributes, semanticAttributes;
+ (void)initialize
{
	noAttributes = [NSDictionary dictionary];
}
- (id)init
{
	SUPERINIT;
	NSDictionary *comment = D([NSColor grayColor], NSForegroundColorAttributeName);
	NSDictionary *keyword = D([NSColor redColor], NSForegroundColorAttributeName);
	NSDictionary *literal = D([NSColor redColor], NSForegroundColorAttributeName);
	tokenAttributes = [D(
			comment, SCKTextTokenTypeComment,
			noAttributes, SCKTextTokenTypePunctuation,
			keyword, SCKTextTokenTypeKeyword,
			literal, SCKTextTokenTypeLiteral)
				mutableCopy];

	semanticAttributes = [D(
			D([NSColor blueColor], NSForegroundColorAttributeName), SCKTextTypeDeclRef,
			D([NSColor brownColor], NSForegroundColorAttributeName), SCKTextTypeMessageSend,
			//D([NSColor greenColor], NSForegroundColorAttributeName), SCKTextTypeDeclaration,
			D([NSColor magentaColor], NSForegroundColorAttributeName), SCKTextTypeMacroInstantiation,
			D([NSColor magentaColor], NSForegroundColorAttributeName), SCKTextTypeMacroDefinition,
			D([NSColor orangeColor], NSForegroundColorAttributeName), SCKTextTypePreprocessorDirective,
			D([NSColor purpleColor], NSForegroundColorAttributeName), SCKTextTypeReference)
				mutableCopy];
	return self;
}

- (void)transformString: (NSMutableAttributedString*)source;
{
	clock_t c1 = clock();
	NSUInteger end = [source length];
	NSUInteger i = 0;
	NSRange r;
	do
	{
		NSDictionary *attrs = [source attributesAtIndex: i
		                          longestEffectiveRange: &r
		                                        inRange: NSMakeRange(i, end-i)];
		i = r.location + r.length;
		NSString *token = [attrs objectForKey: kSCKTextTokenType];
		NSString *semantic = [attrs objectForKey: kSCKTextSemanticType];
		NSDictionary *diagnostic = [attrs objectForKey: kSCKDiagnostic];
		// Skip ranges that have attributes other than semantic markup
		if ((nil == semantic) && (nil == token)) continue;
		if (semantic == SCKTextTypePreprocessorDirective)
		{
			attrs = [semanticAttributes objectForKey: semantic];
		}
		else if (token == nil || token != SCKTextTokenTypeIdentifier)
		{
			attrs = [tokenAttributes objectForKey: token];
		}
		else 
		{
			NSString *semantic = [attrs objectForKey: kSCKTextSemanticType];
			attrs = [semanticAttributes objectForKey: semantic];
			//NSLog(@"Applying semantic attributes: %@", semantic);
		}
		if (nil == attrs)
		{
			attrs = noAttributes;
		}
		[source setAttributes: attrs
		                range: r];
		// Re-apply the diagnostic
		if (nil != diagnostic)
		{
			[source addAttribute: NSToolTipAttributeName
			               value: [diagnostic objectForKey: kSCKDiagnosticText]
			               range: r];
			[source addAttribute: NSBackgroundColorAttributeName
			               value: [NSColor redColor]
			               range: r];
		}
	} while (i < end);
	clock_t c2 = clock();
	NSLog(@"Generating presentation markup took %f seconds.  .",
		((double)c2 - (double)c1) / (double)CLOCKS_PER_SEC);
}
@end

