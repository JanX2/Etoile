/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import "DocPageWeaver.h"
#import "DocHeader.h"
#import "DocIndex.h"
#import "DocMethod.h"
#import "GSDocParser.h"
#import "WeavedDocPage.h"

@implementation DocPageWeaver

@synthesize projectName;

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

    /* Don't include igsdoc, we don't want to turn it into a page */
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
	DESTROY(projectName);
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

- (NSArray *) weaveAllPages
{
	[allWeavedPages removeAllObjects];
    [sourcePathQueue setArray: sourcePaths];

	while ([sourcePathQueue isEmpty] == NO)
    {
    	[allWeavedPages addObjectsFromArray: [self weaveCurrentSourcePages]];
        [sourcePathQueue removeObjectAtIndex: 0];
    }

    return [NSArray arrayWithArray: allWeavedPages];
}


- (NSArray *) weaveCurrentSourcePages
{
    [DocIndex setCurrentIndex: docIndex];
	[weavedPages removeAllObjects];
	DESTROY(currentParser);

	NSSet *skippedFileNames = S(@"ClassesTOC.gsdoc", 
		[[self projectName] stringByAppendingPathExtension: @"gsdoc"]);

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
        [currentParser setWeaver: self];
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

	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: [NSString stringWithFormat: @"%@(%@)", aClassName, aCategoryName]
	                 ofKind: @"categories"];
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
	if ([self currentPage] == nil)
	{
		[self weaveNewPage];

		ASSIGN(currentClassName, nil);
		ASSIGNCOPY(currentHeader, currentHeader);

		[[self currentPage] setHeader: currentHeader];
	}

	[[self currentPage] addFunction: aFunction];
	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: [aFunction name] 
	                 ofKind: @"functions"];
}

- (DocHeader *) currentHeader
{
	return currentHeader;
}

@end
