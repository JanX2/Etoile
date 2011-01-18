/**
	<abstract>A documentation index that can be used to create links.</abstract>

	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2010
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class DocElement;

/** @group Link Generation

DocIndex represents an autgsdoc-compatible documentation index.

It must be initialized with the igsdoc file corresponding to the gsdoc sources 
passed to the DocPageWeaver instance in use.

Concrete subclasses such DocHTMLIndex can be used to create links. For example, 
DocHTMLIndex can be used in -[DocElement HTMLRepresentation] code to wrap every 
symbol name in a HTML link. */
@interface DocIndex : NSObject
{
	@private
	NSString *projectName;
	NSDictionary *indexContent;
	NSDictionary *externalRefs;
	NSDictionary *projectRefs;
	NSMutableDictionary *mergedRefs;
}

+ (id) currentIndex;
+ (void) setCurrentIndex: (DocIndex *)anIndex;

- (id) initWithGSDocIndexFile: (NSString *)anIndexFile;

/** Returns whether the given symbol name is declared as an an informal 
protocol in the GSDoc index. */
- (BOOL) isInformalProtocolSymbolName: (NSString *)aSymbolName;

@property (retain, nonatomic) NSString *projectName;
@property (retain, nonatomic) NSDictionary *externalRefs;

- (void) setProjectRef: (NSString *)aRef
         forSymbolName: (NSString *)aSymbol
                ofKind: (NSString *)aKind;

/** Returns all the symbol names present in the project that match the given 
kind.

Valid kinds are the ones returned by -symbolKinds.

For example, 'classes' would return 'DocIndex', 'DocElement', 'DocMethod' etc. */
- (NSArray *) projectSymbolNamesOfKind: (NSString *)aKind;

/* Returns the supported symbol kinds in the index.

Will return:
<list>
<item>'classes'</item>
<item>'protocols'</item>
<item>'categories'</item>
<item>'methods'</item>
<item>'functions'</item>
<item>'macros'</item>
<item>'constants'</item>
<list> */
- (NSArray *) symbolKinds;

/** Regenerates the index refs by merging external refs, project refs and custom 
refs. 

You must call this method before generating the document output e.g. invoking 
-HTMLRepresentation on any doc element. */
- (void) regenerate;

- (NSString *) linkForSymbolName: (NSString *)aSymbol ofKind: (NSString *)aKind;
- (NSString *) linkWithName: (NSString *)aName forSymbolName: (NSString *)aSymbol ofKind: (NSString *)aKind;
- (NSString *) linkForClassName: (NSString *)aClassName;
- (NSString *) linkForProtocolName: (NSString *)aProtocolName;

- (NSString *) linkForGSDocRef: (NSString *)aRef;
- (NSString *) linkForLocalMethodRef: (NSString *)aRef relativeTo: (DocElement *)anElement;

- (NSString *) linkWithName: (NSString *)aName ref: (NSString *)aRef anchor: (NSString *)anAnchor;
- (NSString *) refFileExtension;

@end

/** @group Link Generation */
@interface DocHTMLIndex : DocIndex
{

}

@end

