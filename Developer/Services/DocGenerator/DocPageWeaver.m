/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import "DocPageWeaver.h"
#import "DeclarationReorderer.h"
#import "DocHeader.h"
#import "DocIndex.h"
#import "DocMethod.h"
#import "DocTOCPage.h"
#import "GSDocParser.h"
#import "WeavedDocPage.h"

@implementation DocPageWeaver

+ (Class) parserClassForFileType: (NSString *)aFileExtension
{
	if ([aFileExtension isEqual: @"gsdoc"])
		return [GSDocParser class];

	return Nil;
}

- (id) initWithParserSourceDirectory: (NSString *)aParserDirPath
                           fileTypes: (NSArray *)fileExtensions
                  rawSourceDirectory: (NSString *)otherDirPath
                        templateFile: (NSString *)aTemplatePath
{
	NSArray *parserPaths = [[NSFileManager defaultManager] directoryContentsAtPath: aParserDirPath];
	NSArray *otherPaths = [[NSFileManager defaultManager] directoryContentsAtPath: otherDirPath];

	parserPaths = [[aParserDirPath stringsByAppendingPaths: parserPaths] pathsMatchingExtensions: fileExtensions];
	otherPaths = [[otherDirPath stringsByAppendingPaths: otherPaths] pathsMatchingExtensions: A(@"html", @"text")];

	return [self initWithSourceFiles: [parserPaths arrayByAddingObjectsFromArray: otherPaths]
						templateFile: aTemplatePath];
}

- (id) initWithSourceFiles: (NSArray *)paths
              templateFile: (NSString *)aTemplatePath
{
	SUPERINIT;

	ETAssert([[paths pathsMatchingExtensions: (A(@"igsdoc"))] count] <= 1);
	docIndex = [[HTMLDocIndex alloc] initWithGSDocIndexFile: 
		[[paths pathsMatchingExtensions: A(@"igsdoc")] firstObject]];
	[DocIndex setCurrentIndex: docIndex]; /* Also reset in -weaveCurrentSourcePages */

	NSDictionary *orderedSymbolDeclarations = [NSDictionary dictionaryWithContentsOfFile: 
		[[paths pathsMatchingExtensions: A(@"plist")] firstObject]];
	reorderingWeaver = (id)[[DeclarationReorderer alloc] initWithWeaver: self 
	                                                     orderedSymbols: orderedSymbolDeclarations];
	
	/* Don't include igsdoc or plist, we don't want to turn them into a page */
	ASSIGN(sourcePaths, [NSArray arrayWithArray: [paths pathsMatchingExtensions: A(@"gsdoc", @"html", @"text")]]);
	sourcePathQueue = [paths mutableCopy];
	ASSIGN(templatePath, aTemplatePath);
	ASSIGN(templateDirPath, [aTemplatePath stringByDeletingLastPathComponent]);
	allWeavedPages = [[NSMutableArray alloc] init];
	weavedPages = [[NSMutableArray alloc] init];

	return self;
}

- (void) dealloc
{
	DESTROY(sourcePaths);
	DESTROY(sourcePathQueue);
	DESTROY(templatePath);
	DESTROY(templateDirPath);
	DESTROY(menuPath);
	DESTROY(externalMappingPath);
	DESTROY(projectMappingPath);
	DESTROY(docIndex);
	DESTROY(currentParser);
	DESTROY(currentClassName);
	DESTROY(currentProtocolName);
	DESTROY(currentHeader);
	DESTROY(allWeavedPages);
	DESTROY(weavedPages);
	DESTROY(apiOverviewPage);
	DESTROY(functionPage);
	DESTROY(constantPage);
	DESTROY(macroPage);
	DESTROY(otherDataTypePage);
	[super dealloc];
}

- (NSString *) templateDirectory
{
	return templateDirPath;
}

- (void) setMenuFile: (NSString *)aMenuPath
{
	ASSIGN(menuPath, aMenuPath);
}

- (void) setExternalMappingFile: (NSString *)aMappingPath
{
	ASSIGN(externalMappingPath, aMappingPath);
	[docIndex setExternalRefs: [NSDictionary dictionaryWithContentsOfFile: aMappingPath]];
}

- (void) setProjectMappingFile: (NSString *)aMappingPath
{
	ASSIGN(projectMappingPath, aMappingPath);
}

- (NSString *) pathForRawSourceFileNamed: (NSString *)aName
{
	NSMutableArray *paths = [NSMutableArray arrayWithArray: sourcePaths];
	[[paths filter] hasSuffix: aName];
	ETAssert([paths count] <= 1);
	return [paths firstObject];
}

- (NSString *) templateFileForSourceFile: (NSString *)aSourceFile
{
	NSParameterAssert(aSourceFile != nil);

	if ([[aSourceFile pathExtension] isEqual: @"gsdoc"])
	{
		return [[self templateDirectory] 
			stringByAppendingPathComponent: @"etoile-documentation-template.html"];
	}
	else
	{
		return [[self templateDirectory] 
			stringByAppendingPathComponent: @"etoile-documentation-markdown-template.html"];
	}
}

- (WeavedDocPage *) weaveMainPageOfClass: (Class)aPageClass withName: (NSString *)aName documentFile: (NSString *)aDocumentFile
{
	NSString *templateFile = [[self templateDirectory] stringByAppendingPathComponent: @"etoile-documentation-template.html"];	
	WeavedDocPage *page = [[aPageClass alloc] initWithDocumentFile: aDocumentFile
	                                                     templateFile: templateFile                                       
	                                                         menuFile: menuPath];

	[page setHeader: AUTORELEASE([[DocHeader alloc] init])];
	[[page header] setName: aName];
	[[page header] setTitle: aName];

	[allWeavedPages addObject: AUTORELEASE(page)];
	return page;
}

- (WeavedDocPage *) weaveMainPageWithName: (NSString *)aName documentFile: (NSString *)aDocumentFile
{
	return [self weaveMainPageOfClass: [WeavedDocPage class] withName: aName documentFile: aDocumentFile];
}

- (void) weaveMainPages
{
	// TODO: Perhaps pass an overview to insert in the header... or use the document file?
	ASSIGN(apiOverviewPage, [self weaveMainPageOfClass: [DocTOCPage class] withName: @"APIOverview" documentFile: nil]);
	ASSIGN(functionPage, [self weaveMainPageWithName: @"Functions" documentFile: nil]);
	ASSIGN(constantPage, [self weaveMainPageWithName: @"Constants" documentFile: nil]);
	ASSIGN(macroPage, [self weaveMainPageWithName: @"Macros" documentFile: nil]);
	ASSIGN(otherDataTypePage, [self weaveMainPageWithName: @"Other Data Types" documentFile: nil]);
}

- (void) weavePagesFromSourceFiles
{
	while ([sourcePathQueue isEmpty] == NO)
	{
		[allWeavedPages addObjectsFromArray: [self weaveCurrentSourcePages]];
		[sourcePathQueue removeObjectAtIndex: 0];
	}
}

- (NSArray *) weaveAllPages
{
	/* Prepare the receiver to use -weaveCurrentSourcePages as many times as needed 
	   to get all the source paths processed */
	[allWeavedPages removeAllObjects];
	[sourcePathQueue setArray: sourcePaths];

	[self weaveMainPages];
	[self weavePagesFromSourceFiles];

	return [NSArray arrayWithArray: allWeavedPages];
}

- (NSArray *) weaveCurrentSourcePages
{
	[DocIndex setCurrentIndex: docIndex];
	[weavedPages removeAllObjects];
	DESTROY(currentParser);

	NSSet *skippedFileNames = S(@"ClassesTOC.gsdoc", 
		[[docIndex projectName] stringByAppendingPathExtension: @"gsdoc"]);

	if ([skippedFileNames containsObject: [[self currentSourceFile] lastPathComponent]])
	{
		NSLog(@" --- Skipping %@ ---- ", [self currentSourceFile]);
		return [NSArray array];
	}

	Class parserClass = [[self class] parserClassForFileType: 
		[[self currentSourceFile] pathExtension]];

	NSLog(@" --- Weaving %@ ---- ", [self currentSourceFile]);

	if (parserClass == Nil)
	{
		[self weaveNewPage];
	}
	else
	{
		NSString *sourceContent = [NSString stringWithContentsOfFile: [self currentSourceFile] 
		                                                    encoding: NSUTF8StringEncoding 
		                                                       error: NULL];

		currentParser = [[parserClass alloc] initWithString: sourceContent];
		[currentParser setWeaver: reorderingWeaver];
		[currentParser parseAndWeave];
	}

	return [NSArray arrayWithArray: weavedPages];
}

- (NSString *) currentSourceFile
{
	return [sourcePathQueue firstObject];
}

- (WeavedDocPage *) currentPage
{
	return [weavedPages lastObject];
}

- (NSString *) currentClassName
{
	return currentClassName;
}

- (NSString *) currentProtocolName
{
	return currentProtocolName;
}

- (void) weaveNewPage
{
	/* Don't release the current header because the header precedes class, 
	   protocol and category declarations in GSDoc format.
	   The header can be valid for multiple pages too. e.g. When a gsdoc file 
	   contains multiple class documentations. */
	DESTROY(currentClassName);
	DESTROY(currentProtocolName);

	WeavedDocPage *page = [[WeavedDocPage alloc] initWithDocumentFile: [self currentSourceFile]
	                                templateFile: [self templateFileForSourceFile: [self currentSourceFile]]
	                                    menuFile: menuPath];
    [weavedPages addObject: AUTORELEASE(page)];
}

- (BOOL) canWeaveMorePages
{
	return ([sourcePathQueue isEmpty] == NO);
}

- (void) weaveHeader: (DocHeader *)aHeader
{
	/* We set the header on the current page in methods such as -weaveClassNamed:superclassName: */
	ASSIGN(currentHeader, aHeader);
 	[self weaveOverviewFile];
}

- (void) weaveOverviewFile
{
	ETAssert([self currentHeader] != nil);

	// Check if there's an overview file, if so use it
	NSString* overviewName = [NSString stringWithFormat: @"%@-overview.html",
		[[[self currentSourceFile] lastPathComponent] stringByDeletingPathExtension]];
	NSString *overviewFile = [self pathForRawSourceFileNamed: overviewName];

	if (overviewFile != nil)
	{
		[[self currentHeader] setFileOverview: overviewFile];
		return;
	}

	overviewName = [NSString stringWithFormat: @"%@-overview.html", [self currentClassName]];
	overviewFile = [self pathForRawSourceFileNamed: overviewName];

	if (overviewFile != nil)
	{
		[[self currentHeader] setFileOverview: overviewFile];
		return;
	}
}

- (void) weaveClassNamed: (NSString *)aClassName 
          superclassName: (NSString *)aSuperclassName
{
	[self weaveNewPage];

	ASSIGN(currentClassName, aClassName);
	ASSIGNCOPY(currentHeader, currentHeader);

	[[self currentPage] setHeader: currentHeader];

	[[self currentHeader] setClassName: aClassName];
	[[self currentHeader] setSuperClassName: aSuperclassName];

	[apiOverviewPage addSubheader: currentHeader];

	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: aClassName 
	                 ofKind: @"classes"];
}

- (void) weaveProtocolNamed: (NSString *)aProtocolName 
{
	[self weaveNewPage];

	ASSIGN(currentProtocolName, aProtocolName);
	ASSIGNCOPY(currentHeader, currentHeader);

	[[self currentPage] setHeader: currentHeader];

	[[self currentHeader] setProtocolName: aProtocolName];

	[apiOverviewPage addSubheader: currentHeader];

	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: aProtocolName 
	                 ofKind: @"protocols"];
}

- (void) weaveCategoryNamed: (NSString *)aCategoryName
                  className: (NSString *)aClassName
{
	[self weaveNewPage];

	ASSIGN(currentClassName, aClassName);
	ASSIGNCOPY(currentHeader, currentHeader);

	[[self currentPage] setHeader: currentHeader];

	[[self currentHeader] setCategoryName: aCategoryName];
	[[self currentHeader] setClassName: aClassName];

	[apiOverviewPage addSubheader: currentHeader];

	NSString *categorySymbol = [NSString stringWithFormat: @"%@(%@)", aClassName, aCategoryName];
	NSString *kind = @"categories";

	if ([docIndex isInformalProtocolSymbolName: categorySymbol])
	{
		kind = @"protocols";
	}
	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: categorySymbol
	                 ofKind: kind];
}

- (void) weaveMethod: (DocMethod *)aMethod
{
	if ([aMethod isClassMethod])
	{
		[[self currentPage] addClassMethod: aMethod];
	}
	else
	{
		[[self currentPage] addInstanceMethod: aMethod];
	}

	NSString *refMarkup = nil;

	if ([self currentClassName] != nil)
	{
		refMarkup = [aMethod refMarkupWithClassName: [self currentClassName]]; 
	}
	else
	{
		ETAssert([self currentProtocolName] != nil);
		refMarkup = [aMethod refMarkupWithProtocolName: [self currentProtocolName]];
	}
	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: refMarkup
	                 ofKind: @"methods"];
}

- (void) weaveFunction: (DocFunction *)aFunction
{
	[functionPage addFunction: aFunction];

	[docIndex setProjectRef: [functionPage name] 
	          forSymbolName: [aFunction name] 
	                 ofKind: @"functions"];
}

- (void) weaveMacro: (DocMacro *)aMacro
{
	[macroPage addMacro: aMacro];

	[docIndex setProjectRef: [macroPage name] 
	          forSymbolName: [aMacro name] 
	                 ofKind: @"macros"];
}
- (void) weaveConstant: (DocConstant *)aConstant
{
	[constantPage addConstant: aConstant];
	[docIndex setProjectRef: [constantPage name] 
	          forSymbolName: [aConstant name] 
	                 ofKind: @"constants"];
}

- (void) weaveOtherDataType: (DocCDataType *)aDataType
{
	[otherDataTypePage addOtherDataType: aDataType];
	// TODO: Would be nice to put these in the doc index too
	/*[docIndex setProjectRef: [otherDataTypePage name] 
	          forSymbolName: [aDataType name] 
	                 ofKind: @"constants"];*/
}

- (void) finishWeaving
{

}

- (DocHeader *) currentHeader
{
	return currentHeader;
}

@end
