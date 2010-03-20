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
	[tex appendFormat: @"\\%@{", [aNode.type objectForKey: @"typeName"]];
	depth++;
}
- (void)visitTextNode: (id<ETText>)aNode
{
	[tex appendString: [aNode stringValue]];
}
- (void)endTextNode: (id<ETText>)aNode
{
	[tex appendString: @"}"];
	depth--;
	if (depth == 0)
	{
		NSLog(@"%@", tex);
	}

}
@end

int main(void)
{
	[NSAutoreleasePool new];
	ETTextFragment *text = [[ETTextFragment alloc] initWithString: @"This is a test"];
	text.type = D(@"p", @"typeName");
	NSLog(@"%@", text);
	ETTextFragment *part1 = [text splitAtIndex: 5];
	NSLog(@"%@", part1);
	NSLog(@"%@", text);
	ETTextTree *tree = [ETTextTree textTreeWithChildren: A(part1, text)];
	tree.type = D(@"div", @"typeName");
	[tree visitWithVisitor: [Visitor new]];
	NSLog(@"%@", tree);
	id<ETText>tree1 = [tree splitAtIndex: 8];
	NSLog(@"%@%@", tree1, tree);
}
