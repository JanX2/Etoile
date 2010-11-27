/*
	Copyright (C) 2008 Nicolas Roard

	Authors:  Nicolas Roard, 
	          Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import "WeavedDocPage.h"
#import "DocHeader.h"
#import "DocFunction.h"
#import "DocIndex.h"
#import "DocMethod.h"
#import "GSDocParser.h"
#import "HtmlElement.h"


@implementation WeavedDocPage

- (NSString *) sourcePath
{
	return [documentPath stringByDeletingLastPathComponent];
}

- (NSString *) defaultMenuFile
{
	NSFileManager* fm = [NSFileManager defaultManager];
	return [[[fm currentDirectoryPath] 
		stringByAppendingPathComponent: [self sourcePath]]
		stringByAppendingPathComponent: @"menu.html"];
}

- (NSSet *) validDocumentTypes
{
	return S(@"gsdoc", @"html");
}

- (id) initWithDocumentFile: (NSString *)aDocumentPath
               templateFile: (NSString *)aTemplatePath 
                   menuFile: (NSString *)aMenuPath
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *finalMenuPath = aMenuPath;

	if (nil == aMenuPath)
	{
		finalMenuPath = [self defaultMenuFile];
	}

	INVALIDARG_EXCEPTION_TEST(aDocumentPath, [fileManager fileExistsAtPath: aDocumentPath]);
	INVALIDARG_EXCEPTION_TEST(aTemplatePath, [fileManager fileExistsAtPath: aTemplatePath]);
	INVALIDARG_EXCEPTION_TEST(finalMenuPath, [fileManager fileExistsAtPath: finalMenuPath]);
	if (NO == [[self validDocumentTypes] containsObject: [aDocumentPath pathExtension]])
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"The input document type must be .html or .gsdoc"];
	}

	SUPERINIT;

	ASSIGN(documentPath, aDocumentPath);
	ASSIGN(documentType, [aDocumentPath pathExtension]);
	ASSIGN(documentContent, [NSString stringWithContentsOfFile: aDocumentPath encoding: NSUTF8StringEncoding error: NULL]);
	ASSIGN(templateContent, [NSString stringWithContentsOfFile: aTemplatePath encoding: NSUTF8StringEncoding error: NULL]);
	ASSIGN(menuContent, [NSString stringWithContentsOfFile: finalMenuPath encoding: NSUTF8StringEncoding error: NULL]);

	classMethods = [NSMutableDictionary new];
	instanceMethods = [NSMutableDictionary new];
	functions = [NSMutableDictionary new];

	return self;
}

- (id) init
{
	return nil;
}

- (void) dealloc
{
	[documentPath release];
	[documentType release];
	[documentContent release];
	[templateContent release];
	[menuContent release];
	[weavedContent release];
	[header release];
	[classMethods release];
	[instanceMethods release];
	[functions release];
	[super dealloc];
}

- (NSString *) name
{
	if ([header className] != nil)
		return [header className];

	return [[documentPath lastPathComponent] stringByDeletingPathExtension];
}

- (void) insert: (NSString *)content forTag: (NSString *)aTag
{
	NSParameterAssert(nil != content);
	NSParameterAssert(nil != weavedContent);

	ASSIGN(weavedContent, [weavedContent stringByReplacingOccurrencesOfString: aTag 
	                                                               withString: content]);
}

- (void) insertHTMLDocument
{
	[self insert: documentContent forTag: @"<!-- etoile-document -->"];
}

- (void) insertGSDocDocument
{
	// FIXME: HOM broken on NSString *mainContentStrings = [[[self mainContentHTMLRepresentation] mappedCollection] content];
	// [[mainContentStrings rightFold] stringByAppendingString: @""];
	[self insert: [[self mainContentHTMLRepresentations] componentsJoinedByString: @""]
	      forTag: @"<!-- etoile-methods -->"];
	[self insert: [[header HTMLRepresentation] content] 
	      forTag:  @"<!-- etoile-header -->"];
}

- (void) insertDocument
{
	if ([documentType isEqual: @"gsdoc"])
	{
		[self insertGSDocDocument];
	}
	else if ([documentType isEqual: @"html"])
	{
		[self insertHTMLDocument];
	}
	else
	{
		ETAssertUnreachable();
	}
}

- (void) insertMenu
{
	[self insert: menuContent forTag: @"<!-- etoile-menu -->"];
}

- (void) insertProjectClassList
{
	DocIndex *docIndex = [DocIndex currentIndex];
	NSArray *classNames = [[docIndex projectSymbolNamesOfKind: @"classes"]
		sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	H list = UL;
	
	FOREACH(classNames, className, NSString *)
	{
		[list and: [LI with: [docIndex linkForClassName: className]]];
	}

	[self insert: [[DIV id: @"project-classes-list" with: list] content] 
	      forTag: @"<!-- etoile-list-classes -->"];
}

- (void) weave
{
	ASSIGN(weavedContent, templateContent);

	[self insertDocument];
	[self insertMenu];
	[self insertProjectClassList];
}

- (void) writeToURL: (NSURL *)outputURL
{
	[[self HTMLString] writeToURL: outputURL atomically: YES encoding: NSUTF8StringEncoding error: NULL];
}

- (void) setHeader: (DocHeader *)aHeader
{
	ASSIGN(header, aHeader);
}

- (DocHeader *) header
{
	return header;
}

- (void) addClassMethod: (DocMethod *)aMethod
{
	NSMutableArray *array = [classMethods objectForKey: [aMethod task]];
	if (array == nil)
	{
		array = [NSMutableArray new];
		[classMethods setObject: array forKey: [aMethod task]];
		[array release];
	}
	[array addObject: aMethod];
}

- (void) addInstanceMethod: (DocMethod *)aMethod
{
	NSMutableArray *array = [instanceMethods objectForKey: [aMethod task]];
	if (array == nil)
	{
		array = [NSMutableArray new];
		[instanceMethods setObject: array forKey: [aMethod task]];
		[array release];
	}
	[array addObject: aMethod];
}

- (void) addFunction: (DocFunction *)aFunction
{
	NSMutableArray *array = [functions objectForKey: [aFunction task]];
	if (array == nil)
	{
		array = [NSMutableArray new];
		[functions setObject: array forKey: [aFunction task]];
		[array release];
	}
	[array addObject: aFunction];
}

- (NSString *) HTMLString
{
	[self weave];
	return weavedContent;
}

- (NSArray *) mainContentHTMLRepresentations
{
	return [NSArray arrayWithObjects: 
		[self HTMLRepresentationWithTitle: @"Functions" subroutines: functions],
		[self HTMLRepresentationWithTitle: @"Class Methods" subroutines: classMethods],
		[self HTMLRepresentationWithTitle: @"Instance Methods" subroutines: instanceMethods], nil];
}

- (HtmlElement *) HTMLRepresentationWithTitle: (NSString *)aTitle 
                                  subroutines: (NSDictionary *)subroutinesByTask
{
	if ([subroutinesByTask isEmpty])
		return [HtmlElement blankElement];

	NSArray *unsortedTasks = [subroutinesByTask allKeys];
	NSArray *tasks = [unsortedTasks sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
	NSString *titleWithoutSpaces = [[aTitle componentsSeparatedByCharactersInSet: 
		[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString: @"-"];
	HtmlElement *html = [DIV class: [titleWithoutSpaces lowercaseString]];

	[html add: [H3 with: aTitle]];
	
	for (NSString *task in tasks)
	{
		[html add: [H4 with: task]];

		NSArray *subroutinesInTask = [[subroutinesByTask objectForKey: task] 
			sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];

		for (DocSubroutine *subroutine in subroutinesInTask)
		{
			[html add: [subroutine HTMLRepresentation]];
		}
	}

	return html;
}

@end
