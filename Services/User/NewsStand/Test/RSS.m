#import <Foundation/Foundation.h>
#import <UnitKit/UnitKit.h>
#import <TRXML/TRXMLNode.h>
#import <TRXML/TRXMLDeclaration.h>

@interface RSS: NSObject <UKTest>
@end

@implementation RSS
- (void) testCDATA
{
	NSData *data = [NSData dataWithContentsOfFile: @"cdata.xml"];
	NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];

	// READ
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
	UKTrue([parser parseFromSource: string]);
//	UKNotNil([[decl getChildrenWithName: @"rss"] anyObject]);
}
- (void) test0
{
	NSString *string = @"<A><b></b><c></c>\t</A>";
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
	UKTrue([parser parseFromSource: string]);
	int i, count = [[decl elements] count];
	UKIntsEqual(1, [[decl elements] count]);
	TRXMLNode *node = [[decl elements] objectAtIndex: 0];
	UKStringsEqual(@"A", [node type]);
	count = [[node elements] count];
	NSLog(@"%d", count);
}

- (void) test1
{
	NSString *string = @"<A><!--msn 20070323 --></A>";
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
	UKTrue([parser parseFromSource: string]);
#if 0
	int count = [[decl elements] count];
	UKIntsEqual(1, [[decl elements] count]);
#endif
#if 0
	TRXMLNode *node = [[decl elements] objectAtIndex: 0];
	UKStringsEqual(@"A", [node type]);
#endif
}

#if 1
- (void) test2
{
	NSData *data = [NSData dataWithContentsOfFile: @"test3.xml"];
	NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	// READ
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
	UKTrue([parser parseFromSource: string]);
	int i, count = [[decl elements] count];
	for (i = 0; i < count; i++)
	{
		id o = [[decl elements] objectAtIndex: i];
		if ([o isKindOfClass: [TRXMLNode class]])
		{
			NSLog(@"Element Type %@", [o type]);
		}
		else
		{
			NSLog(@"Element cdata %@", o);
		}
	}
//	UKIntsEqual(1, [[decl elements] count]);
#if 0
	TRXMLNode *node = [[decl elements] objectAtIndex: 0];
	UKStringsEqual(@"item", [node type]);
	count = [[node elements] count];
	NSLog(@"%d", count);
//	UKNotNil([[decl getChildrenWithName: @"rss"] anyObject]);
#endif
}
#endif
#if 0
- (void) testRSS091
{
}

- (void) testRSS092
{
	NSData *data = [NSData dataWithContentsOfFile: @"sampleRss092.xml"];
	NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];

	// READ
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
	UKTrue([parser parseFromSource: string]);
	UKNotNil([[decl getChildrenWithName: @"rss"] anyObject]);
	TRXMLNode *node = [[decl elements] objectAtIndex: 0];
	UKStringsEqual(@"rss", [node type]);
	UKStringsEqual(@"0.92", [node get: @"version"]);
}

- (void) testRSS10
{
	NSData *data = [NSData dataWithContentsOfFile: @"RSS10.xml"];
	NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];

	// READ
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
	UKTrue([parser parseFromSource: string]);
	UKNotNil([[decl getChildrenWithName: @"rdf:RDF"] anyObject]);
	TRXMLNode *node = [[decl elements] objectAtIndex: 0];
	UKStringsEqual(@"rdf:RDF", [node type]);
}

- (void) testRSS20
{
	NSData *data = [NSData dataWithContentsOfFile: @"rss2sample.xml"];
	NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];

	// READ
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
	UKTrue([parser parseFromSource: string]);
	UKNotNil([[decl getChildrenWithName: @"rss"] anyObject]);
	TRXMLNode *node = [[decl elements] objectAtIndex: 0];
	UKStringsEqual(@"rss", [node type]);
	UKStringsEqual(@"2.0", [node get: @"version"]);
	UKIntsEqual(1, [node children]);
	TRXMLNode *channel = [[node elements] objectAtIndex: 0];
	UKNotNil(channel); // channel
	UKStringsEqual(@"channel", [channel type]);
	node = [[channel getChildrenWithName: @"title"] anyObject];
	UKNotNil(node);
	UKStringsEqual(@"Liftoff News", [node cdata]);
	NSSet *items = [channel getChildrenWithName: @"item"];
	UKIntsEqual(4, [items count]);
	node = [items anyObject];
	UKIntsEqual(1, [[node getChildrenWithName: @"title"] count]);
}

- (void) testAtom10
{
	NSData *data = [NSData dataWithContentsOfFile: @"Atom10.xml"];
	NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];

	// READ
	TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
	UKTrue([parser parseFromSource: string]);
	UKNotNil([[decl getChildrenWithName: @"feed"] anyObject]);
	TRXMLNode *feed = [[decl elements] objectAtIndex: 0];
	UKStringsEqual(@"feed", [feed type]);
	UKStringsEqual(@"http://www.w3.org/2005/Atom", [feed get: @"xmlns"]);
	TRXMLNode *node = [[feed getChildrenWithName: @"title"] anyObject];
	UKStringsEqual(@"dive into mark", [node cdata]);
	node = [[feed getChildrenWithName: @"subtitle"] anyObject];
	NSLog(@"Subtitle %@", [node cdata]);
	node = [[feed getChildrenWithName: @"entry"] anyObject];
	node = [[node getChildrenWithName: @"title"] anyObject];
	UKStringsEqual(@"Atom draft-07 snapshot", [node cdata]);
}
#endif
@end
