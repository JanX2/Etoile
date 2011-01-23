/**
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

/** @group Weaving and Parsing
    @abstract A documentation source parser reports parsing result to a weaver through this protocol.

Any weaver must implement this protocol.<br /> 
When required, multiple weavers can be chained. For instance, parsing GSDoc 
documents requires to reorder the parsed declarations with DocDeclarationReorder 
before handing them to DocPageWeaver. Hence the weaver set on GSDocParser is 
then a DocDeclarationReorderer instance rather than a DocPageWeaver one.

Each time a documentation source document (e.g. a gsdoc file) has been parsed, 
the parser must invoke -finishWeaving.

New page creation is entirely up to the weaver e.g. in reaction to a 
CodeDocWeaving method called back by the parser.  */
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

/** 
@abstract A weaver such as DocPageWeaver controls a documentation source parser through this protocol.
@group Weaving and Parsing

Any documentation source parser must implement this protocol to let the weaver 
initiates the parsing. In addition, the parser must reports its parsing result 
to the weaver through the CodeDocWeaving protocol.<br />
Parsing usually involves to build new DocElement subclass instances and hand 
them to the weaver.  */
@protocol CodeDocParser
- (id) initWithString: (NSString *)aString;
- (void) setWeaver: (id <CodeDocWeaving>)aDocWeaver;
- (id <CodeDocWeaving>) weaver;
- (void) parseAndWeave;
@end

/** @group Page Generation

DocPageWeaver is DocGenerator core class that controls the documentation 
generation process.<br />
<em>etdocgen</em> tool creates a new page weaver based on the options and 
arguments the user provides on the command-line, then triggers the page 
generation with -weaveAllPages which in turn returns the final pages. 
See DocPage API to understand how these pages can be turned into HTML.

You initialize a new page weaver with various input documentation source files 
and an optional template file. Based on the source file types, DocPageWeaver looks up a 
parser. When no parser is available, it hands the file content directly to a new 
documentation page (see DocPage that provides a template-based substitution 
mechanism). Otherwise it delegates the source file parsing to the right parser 
e.g. GSDocParser, which will instantiate new doc elements and weave them through 
the CodeDocWeaving protocol as the parsing goes.

DocPageWeaver is free to weave multiple pages from a single source file, or 
gather doc elements and consolidate them onto a common page.<br />
So in addition to act as coordinator in the doc generation process, 
DocPageWeaver implements a strategy to organize the doc elements into a 
book-like structure.

By invoking -weaveNewPage based on some precise criterias (e.g. 
-weaveClassNamed:superclassName: was called), DocPageWeaver defines page 
generation rules which correspond to a precise book-like structure.<br />
The doc element arrangement on each weaved page is delegated to DocPage class 
and subclasses.

Subclassing altough experimental and untested, can be used to customize the 
existing page generation strategy or implement a new one. */
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
	NSMutableDictionary *categoryPages;

	/* Main Page to collect ObjC constructs */
	DocPage *apiOverviewPage;

	/* Main Pages to collect C constructs */
	DocPage *functionPage;
	DocPage *constantPage;
	DocPage *macroPage;
	DocPage *otherDataTypePage;
}

/** @taskunit Parser Choice */

/** Returns the right parser class or Nil for the given file type.

For <em>gsdoc</em>, returns GSDocParser. */
+ (Class) parserClassForFileType: (NSString *)aFileExtension;

/** @taskunit Initialization */

/** Initializes and returns a new weaver, which will attempt to gather and 
parse every files from the first directory argument that matches the given 
file types, and will look up additional files in HTML or Markdown to be directly 
inserted without parsing in the second directory argument. 

A page template file, usually in HTML can be passed as the last argument. Each 
DocPage class or subclass instantiated by DocPageWeaver will be initialized 
with this template, unless -templateFileForSourceFile: returns a custom one.

TODO: Specify the argument constraints precisely and clarify the template file 
use (it is currently ignored all the time). */
- (id) initWithParserSourceDirectory: (NSString *)aParserDirPath
                           fileTypes: (NSArray *)fileExtensions
                  rawSourceDirectory: (NSString *)otherDirPath
                        templateFile: (NSString *)aTemplatePath;
/** <init />
Initializes and returns a new weaver that will attempt to process and parse the 
given source file paths based on their file types.

A page template file, usually in HTML can be passed as the last argument. Each 
DocPage class or subclass instantiated by DocPageWeaver will be initialized 
with this template, unless templateFileForSourceFile: returns a custom one.

TODO: Specify the argument constraints precisely and clarify the template file 
use (it is currently ignored all the time). */
- (id) initWithSourceFiles: (NSArray *)paths
              templateFile: (NSString *)aTemplatePath;

/** @taskunit Additional Sources */

/** Sets the menu template file path. */
- (void) setMenuFile: (NSString *)aMenuPath;
/** Sets the external index file path. */
- (void) setExternalMappingFile: (NSString *)aMappingPath;

/** Returns the first source file path that matches the given file name.

The source paths are the ones passed to -initWithSourceFiles:templateFile:. */
- (NSString *) pathForRawSourceFileNamed: (NSString *)aName;
/** Returns the page template file path to be used to initialize new DocPage 
objects when processing the given source file.

By default, returns the path to <em>etoile-documentation-template.html</em> for 
a <em>gsdoc</em> file, otherwise returns the path to 
<em>etoile-documentation-markdown-template.html</em>.

Can be overriden to return custom page templates based on the file types or even 
some other criterias (for example the page weaver state). */
- (NSString *) templateFileForSourceFile: (NSString *)aSourceFile;

/** @taskunit Weaving Pages */

/** Weaves one or more pages from all the source files.

The number of weaved pages is unrelated to the number of source 
files. */
- (NSArray *) weaveAllPages;
/** Weaves one or more pages for the current source file.

You should usually call -weaveAllPages rather than this method directly.

See also -currentSourceFile. */
- (NSArray *) weaveCurrentSourcePages;

/** Starts a new page into which doc elements can be weaved.

Each time, -weaveNewPage is called, -currentPage changes. */
- (void) weaveNewPage;
/** Inserts an overview from a file if available, into the current page. */
- (void) weaveOverviewFile;

/** @taskunit Consolidated Symbol Pages */

/** Looks up the page on which the given category should be consolidated, if 
needed creates it, then makes it the current page.

By default, looks up the page that regroups the categories on the class that 
appears in the category symbol.

The category symbol syntax is <em>ClassName(CategoryName)</em>. */
- (void) weavePageForCategoryNamed: (NSString *)aCategoryName className: (NSString *)aClassName;

/** @taskunit Progress and Status */

/** Returns the documentation source file currently parsed. */
- (NSString *) currentSourceFile;
/** Returns the documentation page currently weaved. */
- (DocPage *) currentPage;
/** Returns the name of the class whose documentation is currently parsed from 
-currentSourceFile. */
- (NSString *) currentClassName;
/** Returns the header of the page currently weaved. See -currentPage. */
- (DocHeader *) currentHeader;

@end
