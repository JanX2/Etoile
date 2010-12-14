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

@class DocHeader, DocMethod, DocFunction, DocMacro, DocCDataType, DocConstant, WeavedDocPage, DocIndex;

@protocol CodeDocWeaving
- (void) weaveClassNamed: (NSString *)aClassName 
          superclassName: (NSString *)aSuperclassName;
- (void) weaveProtocolNamed: (NSString *)aProtocolName;
- (void) weaveCategoryNamed: (NSString *)aCategoryName
                  className: (NSString *)aClassName;
- (void) weaveHeader: (DocHeader *)aHeader;
- (void) weaveMethod: (DocMethod *)aMethod;
- (void) weaveFunction: (DocFunction *)aFunction;
- (void) weaveMacro: (DocMacro *)aMacro;
- (void) weaveConstant: (DocConstant *)aConstant;
- (void) weaveOtherDataType: (DocCDataType *)aDataType;
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
    NSString *templateDirPath;
    NSString *menuPath;
    NSString *externalMappingPath;
    NSString *projectMappingPath;
    DocIndex *docIndex;
    id currentParser;
    NSString *currentClassName;
	NSString *currentProtocolName;
	DocHeader *currentHeader;
    NSMutableArray *allWeavedPages;
    NSMutableArray *weavedPages;

	/* Main Page to collect ObjC constructs */
	WeavedDocPage *apiOverviewPage;

	/* Main Pages to collect C constructs */
	WeavedDocPage *functionPage;
	WeavedDocPage *constantPage;
	WeavedDocPage *macroPage;
	WeavedDocPage *otherDataTypePage;
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
- (NSString *) templateFileForSourceFile: (NSString *)aSourceFile;

/** @task Weaving Pages */

- (NSArray *) weaveAllPages;
/** Weaves one or more pages for the current source file.

You should usually call -weaveAllPages rather than this method directly.

See also -currentSourceFile. */
- (NSArray *) weaveCurrentSourcePages;

- (void) weaveNewPage;
- (void) weaveOverviewFile;

/** @task Progress and Status */

- (NSString *) currentSourceFile;
- (WeavedDocPage *) currentPage;
- (NSString *) currentClassName;
- (DocHeader *) currentHeader;

@end

