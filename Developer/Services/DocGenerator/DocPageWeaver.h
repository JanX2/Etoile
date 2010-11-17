/** <title>DocPageWeaver</title>

	<abstract>A documentation builder that produce pages based on the input 
	content.</abstract>

	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class DocHeader, DocMethod, DocFunction, WeavedDocPage;

@protocol CodeDocWeaving
- (void) weaveClassNamed: (NSString *)aClassName 
          superclassName: (NSString *)aSuperclassName;
- (void) weaveHeader: (DocHeader *)aHeader;
- (void) weaveMethod: (DocMethod *)aMethod;
- (void) weaveFunction: (DocFunction *)aFunction;
- (DocHeader *) currentHeader;
@end

@protocol CodeDocParser
- (id) initWithString: (NSString *)aString;
- (void) setWeaver: (id <CodeDocWeaving>)aDocWeaver;
- (id <CodeDocWeaving>) weaver;
- (void) parseAndWeave;
@end

@interface DocPageWeaver : NSObject <CodeDocWeaving>
{
	@private
	NSArray *sourcePaths;
    NSMutableArray *sourcePathQueue;
    NSString *templatePath;
    NSString *menuPath;
    NSString *externalMappingPath;
    NSString *projectMappingPath;
    id currentParser;
    NSString *currentClassName;
    NSMutableArray *allWeavedPages;
    NSMutableArray *weavedPages;
}

/** @task Parser Choice */

+ (Class) parserClassForFileType: (NSString *)aFileExtension;

/** @task Initialization */

- (id) initWithParserSourceDirectory: (NSString *)aSourceDirPath
                           fileTypes: (NSArray *)fileExtensions
                  rawSourceDirectory: (NSString *)otherDirPath
                        templateFile: (NSString *)aTemplatePath;
- (id) initWithSourceFiles: (NSArray *)paths
              templateFile: (NSString *)aTemplatePath;
              
/** @task Additional Sources */

- (void) setMenuFile: (NSString *)aMenuPath;
- (void) setExternalMappingFile: (NSString *)aMappingPath;
- (void) setProjectMappingFile: (NSString *)aMappingPath;

- (NSString *) pathForRawSourceFileNamed: (NSString *)aName;

/** @task Weaving Pages */

- (NSArray *) weaveAllPages;
- (NSArray *) weaveCurrentSourcePages;

- (void) weaveNewPage;
- (void) weaveOverviewFile;

/** @task Progress and Status */

- (NSString *) currentSourceFile;
- (WeavedDocPage *) currentPage;
- (NSString *) currentClassName;
- (DocHeader *) currentHeader;

@end

