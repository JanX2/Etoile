/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import "DocPageWeaver.h"
#import "DocCategoryPage.h"
#import "DocDeclarationReorderer.h"
#import "DocElement.h"
#import "DocHeader.h"
#import "DocIndex.h"
#import "DocMethod.h"
#import "DocPage.h"
#import "DocTOCPage.h"
#import "GSDocParser.h"
#import "DocPage.h"

@implementation DocPageWeaver

+ (Class) parserClassForFileType: (NSString *)aFileExtension
{
	if ([aFileExtension isEqual: @"gsdoc"])
		return [GSDocParser class];

	return Nil;
}


/* Although we collect README, INSTALL and NEWS in each raw source directory 
provided through etdocgen option. In practice, 'documentation.make' provides  
them explicitly as arguments, mostly because getopt has no built-in support to 
handle multiple values (e.g. array) per option. We could work around that by 
accepting a plist enclosing in quotes, but that doesn't seem worth the investment 
presently. */
- (NSArray *) commonRawSourceFilesInDirectory: (NSString *)dirPath
{
	NSString *readMePath = [dirPath stringByAppendingPathComponent: @"README"];
	NSString *installPath = [dirPath stringByAppendingPathComponent: @"INSTALL"];
	NSString *newsPath = [dirPath stringByAppendingPathComponent: @"NEWS"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableArray *files = [NSMutableArray array];

	for (NSString *path in A(readMePath, installPath, newsPath))
	{
		if ([fm fileExistsAtPath: path] == NO)
			continue;
		
		[files addObject: path];
	}

	return files;
}

- (id) initWithParserSourceDirectory: (NSString *)aParserDirPath
                           fileTypes: (NSArray *)fileExtensions
                rawSourceDirectories: (NSArray *)otherDirPaths
               additionalSourceFiles: (NSArray *)additionalSourceFiles
                        templateFile: (NSString *)aTemplatePath
{
	NSArray *parserFileNames = [[NSFileManager defaultManager] directoryContentsAtPath: aParserDirPath];
	NSArray *parserFiles = [[aParserDirPath stringsByAppendingPaths: parserFileNames] pathsMatchingExtensions: fileExtensions];
	NSMutableArray *otherFiles = [NSMutableArray array];

	// NOTE: We are provided with a single raw source dir through etdocgen 
	// option, which means this loop use is limited presently.
	for (NSString *dirPath in otherDirPaths)
	{
		NSArray *otherFileNames = [[NSFileManager defaultManager] directoryContentsAtPath: dirPath];

		if (otherFileNames == nil)
		{
			otherFileNames = [NSArray array];
		}
	
		[otherFiles addObjectsFromArray: 
			[[dirPath stringsByAppendingPaths: otherFileNames] pathsMatchingExtensions: A(@"html", @"text")]];
		[otherFiles addObjectsFromArray: [self commonRawSourceFilesInDirectory: dirPath]];
	}

	NSArray *collectedSourceFiles = [[parserFiles arrayByAddingObjectsFromArray: otherFiles] 
		arrayByAddingObjectsFromArray: additionalSourceFiles];

	return [self initWithSourceFiles: collectedSourceFiles
						templateFile: aTemplatePath];
}

- (NSArray *) validSourceFilesInFiles: (NSArray *)sourceFiles
{
	NSMutableArray *commonFiles = [NSMutableArray arrayWithArray: sourceFiles];
	
	[[commonFiles filter] hasSuffix: [A(@"README", @"INSTALL", @"NEWS") each]];
	
	return [commonFiles arrayByAddingObjectsFromArray: 
		[sourceFiles pathsMatchingExtensions: A(@"gsdoc", @"html", @"text")]];
}

- (id) initWithSourceFiles: (NSArray *)paths
              templateFile: (NSString *)aTemplatePath
{
	SUPERINIT;

	ETAssert([[paths pathsMatchingExtensions: (A(@"igsdoc"))] count] == 1);
	docIndex = [[DocHTMLIndex alloc] initWithGSDocIndexFile: 
		[[paths pathsMatchingExtensions: A(@"igsdoc")] firstObject]];
	[DocIndex setCurrentIndex: docIndex]; /* Also reset in -weaveCurrentSourcePages */

	// FIXME: Retrieve OrderedSymbolDeclarations.plist based on the entire file 
	// name and not just the extension.
	ETAssert([[paths pathsMatchingExtensions: (A(@"plist"))] count] == 1);
	NSDictionary *orderedSymbolDeclarations = [NSDictionary dictionaryWithContentsOfFile: 
		[[paths pathsMatchingExtensions: A(@"plist")] firstObject]];
	reorderingWeaver = (id)[[DocDeclarationReorderer alloc] initWithWeaver: self 
	                                                     orderedSymbols: orderedSymbolDeclarations];
	
	/* Don't include igsdoc or plist, we don't want to turn them into a page */
	ASSIGN(sourcePaths, [self validSourceFilesInFiles: paths]);
	sourcePathQueue = [paths mutableCopy];
	ASSIGN(templatePath, aTemplatePath);
	ASSIGN(templateDirPath, [aTemplatePath stringByDeletingLastPathComponent]);
	allWeavedPages = [[NSMutableArray alloc] init];
	weavedPages = [[NSMutableArray alloc] init];
	categoryPages = [[NSMutableDictionary alloc] init];

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
	DESTROY(categoryPages);
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

- (DocPage *) weaveMainPageOfClass: (Class)aPageClass withName: (NSString *)aName overview: (NSString *)anOverview
{
	NSString *templateFile = [[self templateDirectory] stringByAppendingPathComponent: @"etoile-documentation-template.html"];	
	DocPage *page = [[aPageClass alloc] initWithDocumentFile: nil
	                                                     templateFile: templateFile                                       
	                                                         menuFile: menuPath];

	[page setHeader: AUTORELEASE([[DocHeader alloc] init])];
	[[page header] setName: aName];
	[[page header] setTitle: aName];
	[[page header] setAbstract: anOverview];

	[allWeavedPages addObject: AUTORELEASE(page)];
	return page;
}

- (DocPage *) weaveMainPageWithName: (NSString *)aName overview: (NSString *)anOverview
{
	return [self weaveMainPageOfClass: [DocPage class] withName: aName overview: anOverview];
}

- (void) weaveMainPages
{
	// TODO: Perhaps pass an overview to insert in the header... or use the document file?
	ASSIGN(apiOverviewPage, [self weaveMainPageOfClass: [DocTOCPage class] withName: @"API Overview" overview: @"Classes, Protocols and Categories by Groups"]);

	NSString *functionOverview = [NSString stringWithFormat: @"All the public Functions in %@", [docIndex projectName]];
	ASSIGN(functionPage, [self weaveMainPageWithName: @"Functions" overview: functionOverview]);

	NSString *constantOverview = 
		[NSString stringWithFormat: @"All the public Constants, Enums and Unions in %@", [docIndex projectName]];
	ASSIGN(constantPage, [self weaveMainPageWithName: @"Constants" overview: constantOverview]);

	NSString *macroOverview = 
		[NSString stringWithFormat: @"All the public Macros in %@", [docIndex projectName]];
	ASSIGN(macroPage, [self weaveMainPageWithName: @"Macros" overview: macroOverview]);

	NSString *otherOverview = 
		[NSString stringWithFormat: @"All the public Structures and Function Pointers in %@", [docIndex projectName]];
	ASSIGN(otherDataTypePage, [self weaveMainPageWithName: @"Other Data Types" overview: otherOverview]);
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

- (DocPage *) currentPage
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

- (void) resetCurrentPageRelatedState
{
	/* Don't release the current header because the header precedes class, 
	   protocol and category declarations in GSDoc format.
	   The header can be valid for multiple pages too. e.g. When a gsdoc file 
	   contains multiple class documentations. */
	DESTROY(currentClassName);
	DESTROY(currentProtocolName);
}

- (void) weaveNewPageOfClass: (Class)aPageClass
{
	[self resetCurrentPageRelatedState];

	DocPage *page = [[aPageClass alloc] initWithDocumentFile: [self currentSourceFile]
	                                templateFile: [self templateFileForSourceFile: [self currentSourceFile]]
	                                    menuFile: menuPath];
    [weavedPages addObject: AUTORELEASE(page)];
}

- (void) weaveNewPage
{
	[self weaveNewPageOfClass: [DocPage class]];
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
	[[self currentHeader] setSuperclassName: aSuperclassName];

	[apiOverviewPage addSubheader: currentHeader];

	[[self currentHeader] setOwnerSymbolName: aClassName];
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

	[[self currentHeader] setOwnerSymbolName: [NSString stringWithFormat: @"(%@)", aProtocolName]];
	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: aProtocolName 
	                 ofKind: @"protocols"];
}

- (void) weaveCategoryNamed: (NSString *)aCategoryName
                  className: (NSString *)aClassName
{
	[self weavePageForCategoryNamed: aCategoryName className: aClassName];

	ASSIGN(currentClassName, aClassName);
	ASSIGNCOPY(currentHeader, currentHeader);

	[currentHeader setCategoryName: aCategoryName];
	[currentHeader setClassName: aClassName];
	// FIXME: Is it really necessary to set both title and name separatly?
	[currentHeader setTitle: aCategoryName];

	DocElementGroup *category = AUTORELEASE([[DocElementGroup alloc] 
		initWithHeader: currentHeader subgroupKey: @"task"]);

	[(DocCategoryPage *)[self currentPage] addMethodGroup: category];

	[apiOverviewPage addSubheader: currentHeader];

	NSString *categorySymbol = [NSString stringWithFormat: @"%@(%@)", aClassName, aCategoryName];
	NSString *kind = @"categories";

	if ([docIndex isInformalProtocolSymbolName: categorySymbol])
	{
		kind = @"protocols";
	}
	[[self currentHeader] setOwnerSymbolName: categorySymbol];
	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: categorySymbol
	                 ofKind: kind];
}

- (void) weaveMethod: (DocMethod *)aMethod
{
	[[self currentPage] addMethod: aMethod];

	NSString *refMarkup = nil;
	NSString *ownerSymbol = nil;

	if ([self currentClassName] != nil)
	{
		refMarkup = [aMethod refMarkupWithClassName: [self currentClassName]];
		ownerSymbol = [self currentClassName];

		NSString *currentCategoryName = [[self currentHeader] categoryName];
		
		if (currentCategoryName != nil)
		{
			ownerSymbol = [NSString stringWithFormat: @"%@(%@)", 
				[self currentClassName], currentCategoryName];
		}
	}
	else
	{
		ETAssert([self currentProtocolName] != nil);
		refMarkup = [aMethod refMarkupWithProtocolName: [self currentProtocolName]];
		ownerSymbol = [NSString stringWithFormat: @"(%@)", [self currentProtocolName]];
	}
	[aMethod setOwnerSymbolName: ownerSymbol];
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

- (void) makeCurrentPage: (DocPage *)aPage
{
	/* For a category page, the page could have been generated with the current source 
	   file or a previous one. In the former case, weavedPages holds the page, 
	   in the latter allWeavedPages holds the page. */
	[allWeavedPages removeObject: aPage];
	[weavedPages removeObject: aPage];

	/* -currentPage returns the last object */
	[weavedPages addObject: aPage];

	[self resetCurrentPageRelatedState];
}

- (void) weavePageForCategoryNamed: (NSString *)aCategoryName className: (NSString *)aClassName
{
	DocPage *page = [categoryPages objectForKey: aClassName];

	if (page == nil)
	{
		[self weaveNewPageOfClass: [DocCategoryPage class]];
		page = [self currentPage];

		[categoryPages setObject: page forKey: aClassName];

		[page setHeader: AUTORELEASE([[DocHeader alloc] init])];
		[[page header] setName: [NSString stringWithFormat: @"%@ Categories", aClassName]];
		[[page header] setTitle: [NSString stringWithFormat: @"%@ categories documentation", aClassName]];
		[[page header] setAbstract: [NSString stringWithFormat: @"All the public Categories which extend %@ class.", aClassName]];
	}
	else
	{
		[self makeCurrentPage: page];
	}
}

- (DocHeader *) currentHeader
{
	return currentHeader;
}

@end
