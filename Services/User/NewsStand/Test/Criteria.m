#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import <TRXML/TRXMLNode.h>
#import <TRXML/TRXMLDeclaration.h>

@interface Criteria: NSObject <UKTest>
@end

@implementation Criteria
- (void) testBasic
{
	NSString *string = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><criteriagroup condition=\"all\"><criteria field=\"Read\"><operator>1</operator><value>No</value></criteria></criteriagroup>";

	// READ
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
	UKTrue([parser parseFromSource: string]);
	return;
	TRXMLNode *child = [[decl elements] objectAtIndex: 0];
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
