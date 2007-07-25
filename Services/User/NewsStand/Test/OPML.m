#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import <TRXML/TRXMLNode.h>
#import <TRXML/TRXMLDeclaration.h>

@interface OPML: NSObject <UKTest>
@end

@implementation OPML
- (void) testBasic
{
	// WRITE
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLNode *tree = [TRXMLNode TRXMLNodeWithType: @"opml" attributes: [NSDictionary dictionaryWithObject:@"1.0" forKey:@"version"]];
	TRXMLNode *head = [TRXMLNode TRXMLNodeWithType: @"head" attributes: nil];
	TRXMLNode *node = [TRXMLNode TRXMLNodeWithType: @"title" attributes: nil];
	[node setCData: @"Vienna Subscriptions"];
	[head addChild: node];
	node = [TRXMLNode TRXMLNodeWithType: @"dateCreated" attributes: nil];
	[node setCData: [[NSCalendarDate date] description]];
	[head addChild: node];
	[tree addChild: head];
	[decl addChild: tree];
	
	NSString *s = [decl stringValue];
	NSLog(@"%@", s);

	// READ
	TRXMLDeclaration *decl_o = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl_o];
	UKTrue([parser parseFromSource: s]);
	TRXMLNode *child = [[decl_o elements] objectAtIndex: 0];
//	NSLog(@"=== %@", [child type]);
	UKStringsEqual(@"opml", [child type]);
	UKIntsEqual(1, [child children]);
	TRXMLNode *head_o = [[child elements] objectAtIndex: 0];
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
