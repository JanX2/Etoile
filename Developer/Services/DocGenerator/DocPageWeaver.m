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

- (void) weaveNewPage
{
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
    [self weaveNewPage];
	[[self currentPage] setHeader: aHeader];
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
	ASSIGN(currentClassName, aClassName);
    [[self currentHeader] setClassName: aClassName];
    [[self currentHeader] setSuperClassName: aSuperclassName];
	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: aClassName 
	                 ofKind: @"classes"];
}

- (void) weaveProtocolNamed: (NSString *)aProtocolName 
{
    [[self currentHeader] setProtocolName: aProtocolName];
	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: aProtocolName 
	                 ofKind: @"protocols"];
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
	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: [aMethod refMarkupWithClassName: [self currentClassName]] 
	                 ofKind: @"methods"];
}

- (void) weaveFunction: (DocFunction *)aFunction
{
	[[self currentPage] addFunction: aFunction];
	[docIndex setProjectRef: [[self currentPage] name] 
	          forSymbolName: [aFunction name] 
	                 ofKind: @"functions"];
}

- (DocHeader *) currentHeader
{
	return [[self currentPage] header];
}

@end
