#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/CoreObject.h>
#import "EtoileText.h"

@interface Visitor : NSObject <ETTextVisitor>
{
	NSUInteger depth;
	NSMutableString *tex;
}
@end
@implementation Visitor
- (id)init
{
	SUPERINIT;
	tex = [NSMutableString new];
	return self;
}
- (void)startTextNode: (id<ETText>)aNode
{
	NSString *typeName = [aNode.textType valueForKey: kETTextStyleName];
	if (nil != typeName)
	{
		[tex appendFormat: @"\\%@{", typeName];
	}
	depth++;
}
- (void)visitTextNode: (id<ETText>)aNode
{
	[tex appendString: [aNode stringValue]];
}
- (void)endTextNode: (id<ETText>)aNode
{
	;
	if (nil != [aNode.textType valueForKey: kETTextStyleName])
	{
		[tex appendString: @"}"];
	}
	depth--;
	if (depth == 0)
	{
		NSLog(@"%@", tex);
	}

}
@end

@interface HTMLParser : NSObject
{
	id<ETText>html;
}
@end
@implementation HTMLParser
- (id<ETText>)parseHTMLFromString: (NSString*)aString
{
	html = nil;
	ETXMLParser *parser = [ETXMLParser new];
	ETXMLTextParser *delegate = 
		[[ETXMLTextParser alloc] initWithXMLParser: parser
		                                    parent: (id)self
		                                       key: @"HTML"];
	delegate.document = [ETTextDocument new];
	[parser parseFromSource: aString];
	[parser release];
	return html;
}
- (void)addChild: (id<ETText>)aNode forKey: (NSString*)aKey
{
	html = [[aNode retain] autorelease];
}
@end

@interface TeXScannerDelegate : NSObject <ETTeXScannerDelegate>
{
	@public
	NSMutableSet *commands;
}
@end
@implementation TeXScannerDelegate
- (id)init
{
	SUPERINIT;
	commands = [NSMutableSet new];
	return self;
}
- (void)dealloc
{
	NSLog(@"Used commands: %@", commands);
	[commands release];
	[super dealloc];
}
- (void)beginCommand: (NSString*)aCommand
{
	[commands addObject: aCommand];
	NSLog(@"Command: %@", aCommand);
}
- (void)beginOptArg
{
	NSLog(@"[");
}
- (void)endOptArg
{
	NSLog(@"]");
}
- (void)beginArgument
{
	NSLog(@"{");
}
- (void)endArgument
{
	NSLog(@"}");
}
- (void)handleText: (NSString*)aString
{
	NSLog(@"Text: %@", aString);
}
@end


int main(void)
{
	[NSAutoreleasePool new];
	ETTextFragment *text = [[ETTextFragment alloc] initWithString: @"This is a test"];
	text.textType = D(@"p", kETTextStyleName);
	NSLog(@"%@", text);
	id<ETText> part1 = [text splitAtIndex: 5];
	NSLog(@"%@", part1);
	NSLog(@"%@", text);
	ETTextTree *tree = [ETTextTree textTreeWithChildren: A(part1, text)];
	tree.textType = D(@"div", kETTextStyleName);
	[tree visitWithVisitor: [Visitor new]];
	NSLog(@"%@", tree);
	id<ETText>tree1 = [tree splitAtIndex: 8];
	NSLog(@"%@%@", tree1, tree);
	HTMLParser *parser = [HTMLParser new];
	id<ETText> html = [parser parseHTMLFromString: @"<p>This is a string containing <b>bold</b> text</p>"];
	NSLog(@"%@", html);
	[html visitWithVisitor: [Visitor new]];

	TeXScannerDelegate *d = [TeXScannerDelegate new];
	ETTeXScanner *s = [ETTeXScanner new];
	NSString * tex = [NSString stringWithContentsOfFile: @"/tmp/tex"];
	s.delegate = d;
	[s parseString: tex];
	[d release];
	ETTeXParser *d2 = [ETTeXParser new];
	d2.scanner = s;
	s.delegate = d2;
	[s parseString: tex];
	NSLog(@"Parsed TeX: %@", d2.builder.textTree);
	return 0;
}
