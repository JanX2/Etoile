/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import "DocPageWeaver.h"
#import "GSDocParser.h"
#import "WeavedDocPage.h"

@implementation DocPageWeaver

+ (Class) parserClassForFileType: (NSString *)aFileExtension
{
	if ([aFileExtension isEqual: @"gsdoc"])
		return [GSDocParser class];

	return Nil;
}

- (id) initWithSourceDirectory: (NSString *)aSourceDirPath
                     fileTypes: (NSArray *)fileExtensions
                  templateFile: (NSString *)aTemplatePath
{
	NSArray *paths = [[NSFileManager defaultManager] directoryContentsAtPath: aSourceDirPath];
	return [self initWithSourceFiles: [paths pathsMatchingExtensions: fileExtensions]
                        templateFile: aTemplatePath];
}

- (id) initWithSourceFiles: (NSArray *)paths
              templateFile: (NSString *)aTemplatePath
{
	SUPERINIT;
    ASSIGN(sourcePaths, [NSArray arrayWithArray: paths]);
    ASSIGN(templatePath, aTemplatePath);
    return self;
}

- (void) dealloc
{
	DESTROY(sourcePaths);
    DESTROY(templatePath);
    DESTROY(currentParser);
	DESTROY(currentClassName);
    DESTROY(weavedPages);
	[super dealloc];
}

- (NSArray *) weaveAllPages
{
	[allWeavedPages removeAllObjects];

	while ([sourcePathQueue isEmpty] == NO)
    {
    	[allWeavedPages addObjectsFromArray: [self weaveCurrentSourcePages]];
        [sourcePathQueue removeObjectAtIndex: 0];
    }

    return [NSArray arrayWithArray: allWeavedPages];
}


- (NSArray *) weaveCurrentSourcePages
{
	[weavedPages removeAllObjects];
	[currentParser release];

	NSString *sourceContent = [NSString stringWithContentsOfFile: [self currentSourceFile] 
                                                        encoding: NSUTF8StringEncoding 
                                                           error: NULL];
	currentParser = [[GSDocParser alloc] initWithString: sourceContent];
    [currentParser parseAndWeave];
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
	WeavedDocPage *page = [[WeavedDocPage alloc] initWithDocumentFile: nil
	                                templateFile: templatePath
	                                    menuFile: nil classMappingFile: nil projectClassMappingFile: nil];
    [weavedPages addObject: AUTORELEASE(page)];
}

- (BOOL) canWeaveMorePages
{
	return ([sourcePathQueue isEmpty] == NO);
}

- (void) weaveClassNamed: (NSString *)aClassName
{
	ASSIGN(currentClassName, aClassName);
    [self weaveNewPage];
}

- (void) weaveHeader: (DocHeader *)aHeader
{
	[[self currentPage] setHeader: aHeader];
}

- (void) weaveMethod: (DocMethod *)aMethod
{
	[[self currentPage] addMethod: aMethod];
}

- (void) weaveFunction: (DocFunction *)aFunction
{
	[[self currentPage] addFunction: aFunction];
}

@end
