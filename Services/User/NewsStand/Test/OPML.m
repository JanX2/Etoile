#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import <ETXML/ETXMLNode.h>
#import <ETXML/ETXMLDeclaration.h>

@interface OPML: NSObject <UKTest>
@end

@implementation OPML
- (void) testBasic
{
	// WRITE
	ETXMLDeclaration *decl = [ETXMLDeclaration ETXMLDeclaration];
	ETXMLNode *tree = [ETXMLNode ETXMLNodeWithType: @"opml" attributes: [NSDictionary dictionaryWithObject:@"1.0" forKey:@"version"]];
	ETXMLNode *head = [ETXMLNode ETXMLNodeWithType: @"head" attributes: nil];
	ETXMLNode *node = [ETXMLNode ETXMLNodeWithType: @"title" attributes: nil];
	[node setCData: @"Vienna Subscriptions"];
	[head addChild: node];
	node = [ETXMLNode ETXMLNodeWithType: @"dateCreated" attributes: nil];
	[node setCData: [[NSCalendarDate date] description]];
	[head addChild: node];
	[tree addChild: head];
	[decl addChild: tree];
	
	NSString *s = [decl stringValue];
	NSLog(@"%@", s);

	// READ
	ETXMLDeclaration *decl_o = [ETXMLDeclaration ETXMLDeclaration];
	ETXMLParser *parser = [ETXMLParser parserWithContentHandler: decl_o];
	UKTrue([parser parseFromSource: s]);
	ETXMLNode *child = [[decl_o elements] objectAtIndex: 0];
//	NSLog(@"=== %@", [child type]);
	UKStringsEqual(@"opml", [child type]);
	UKIntsEqual(1, [child children]);
	ETXMLNode *head_o = [[child elements] objectAtIndex: 0];
	UKNotNil(head_o); // head
	UKStringsEqual(@"head", [head_o type]);
	UKIntsEqual(2, [head_o children]);
	NSSet *set = [head_o getChildrenWithName: @"title"];
	UKIntsEqual(1, [set count]);
	child = [[set allObjects] objectAtIndex: 0];
	UKNotNil(child); // title
	set = [head_o getChildrenWithName: @"dateCreated"];
	UKIntsEqual(1, [set count]);
	child = [[set allObjects] objectAtIndex: 0];
	UKNotNil(child); // datecreated
}
@end
