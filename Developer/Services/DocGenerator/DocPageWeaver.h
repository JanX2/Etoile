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

@class DocHeader, DocMethod, DocFunction, DocMacro, DocCDataType, DocConstant, DocPage, DocIndex;

@protocol CodeDocWeaving <NSObject>
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
- (void) finishWeaving;
- (DocHeader *) currentHeader;
@end

@protocol CodeDocParser
- (id) initWithString: (NSString *)aString;
- (void) setWeaver: (id <CodeDocWeaving>)aDocWeaver;
- (id <CodeDocWeaving>) weaver;
- (void) parseAndWeave;
@end

/** @group Page Generation */
@interface DocPageWeaver : NSObject <CodeDocWeaving>
{
	@private
	/* Documentation Source & Templates */
	NSArray *sourcePaths;
	NSMutableArray *sourcePathQueue;
	NSString *templatePath;
	NSString *templateDirPath;
	NSString *menuPath;
	NSString *externalMappingPath;
	NSString *projectMappingPath;

	/* Documentation index built during the weaving/parsing */
	DocIndex *docIndex;

	/* Decorator to reorder GSDocParser parsing output */
	id <CodeDocWeaving> reorderingWeaver;

	/* Parser whose weaver is set to the receiver or reorderingWeaver */	
	id currentParser;

	/* Current Parsing/Weaving State */
	NSString *currentClassName;
	NSString *currentProtocolName;
	DocHeader *currentHeader;
	NSMutableArray *weavedPages;

	NSMutableArray *allWeavedPages;

	/* Main Page to collect ObjC constructs */
	DocPage *apiOverviewPage;

	/* Main Pages to collect C constructs */
	DocPage *functionPage;
	DocPage *constantPage;
	DocPage *macroPage;
	DocPage *otherDataTypePage;
}

/** @task Parser Choice */

+ (Class) parserClassForFileType: (NSString *)aFileExtension;

/** @task Initialization */

- (id) initWithParserSourceDirectory: (NSString *)aParserDirPath
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
- (DocPage *) currentPage;
- (NSString *) currentClassName;
- (DocHeader *) currentHeader;

@end

