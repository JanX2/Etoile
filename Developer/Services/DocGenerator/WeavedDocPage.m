//
//  DocumentWeaver.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "WeavedDocPage.h"
#import "GSDocParserDelegate.h"
#import "HtmlElement.h"
#import "GSDocParser.h"

@implementation WeavedDocPage

- (NSString *) sourcePath
{
	return [documentPath stringByDeletingLastPathComponent];
}

- (NSString *) defaultMenuFile
{
	NSFileManager* fm = [NSFileManager defaultManager];
	return [[[fm currentDirectoryPath] 
		stringByAppendingPathComponent: [self sourcePath]]
		stringByAppendingPathComponent: @"menu.html"];
}

- (NSSet *) validDocumentTypes
{
	return S(@"gsdoc", @"html");
}

- (id) initWithDocumentFile: (NSString *)aDocumentPath
               templateFile: (NSString *)aTemplatePath 
                   menuFile: (NSString *)aMenuPath
           classMappingFile: (NSString *)aMappingPath
    projectClassMappingFile: (NSString *)aProjectMappingPath;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *finalMenuPath = aMenuPath;

	if (nil == aMenuPath)
	{
		finalMenuPath = [self defaultMenuFile];
	}

	INVALIDARG_EXCEPTION_TEST(aDocumentPath, [fileManager fileExistsAtPath: aDocumentPath]);
	INVALIDARG_EXCEPTION_TEST(aTemplatePath, [fileManager fileExistsAtPath: aTemplatePath]);
	INVALIDARG_EXCEPTION_TEST(finalMenuPath, [fileManager fileExistsAtPath: finalMenuPath]);
	INVALIDARG_EXCEPTION_TEST(aProjectMappingPath, [fileManager fileExistsAtPath: aProjectMappingPath]);
	if (NO == [[self validDocumentTypes] containsObject: [aDocumentPath pathExtension]])
	{
		[NSException raise: NSInvalidArgumentException
		            format: @"The input document type must be .html or .gsdoc"];
	}
	

	SUPERINIT;

	ASSIGN(documentPath, aDocumentPath);
	ASSIGN(documentType, [aDocumentPath pathExtension]);
	ASSIGN(documentContent, [NSString stringWithContentsOfFile: aDocumentPath]);
	ASSIGN(templateContent, [NSString stringWithContentsOfFile: aTemplatePath]);
	ASSIGN(menuContent, [NSString stringWithContentsOfFile: finalMenuPath]);
	ASSIGN(classMapping, [NSDictionary dictionaryWithContentsOfFile: aMappingPath]);
	ASSIGN(projectClassMapping, [NSDictionary dictionaryWithContentsOfFile: aProjectMappingPath]);

	return self;
}

- (id) init
{
  return nil;
}

- (void) dealloc
{
	[documentPath release];
	[documentType release];
	[documentContent release];
	[templateContent release];
	[menuContent release];
	[classMapping release];
	[projectClassMapping release];
	[weavedContent release];
	[super dealloc];
}

- (void) insert: (NSString *)content forTag: (NSString *)aTag
{
	NSParameterAssert(nil != content);
	NSParameterAssert(nil != weavedContent);

	ASSIGN(weavedContent, [weavedContent stringByReplacingOccurrencesOfString: aTag 
	                                                               withString: content]);
}

- (void) insertHTMLDocument
{
	[self insert: documentContent forTag: @"<!-- etoile-document -->"];
}

- (void) insertGSDocDocument
{
	NSXMLParser* parser = [[NSXMLParser alloc] initWithData: 
						   [documentContent dataUsingEncoding: NSUTF8StringEncoding]];
	
	//GSDocParser* delegate = [GSDocParser new];
	//[delegate setGSDocDirectory: [gsdocFile stringByDeletingLastPathComponent]];
	//[delegate setGSDocFile: gsdocFile];
	
	GSDocParserDelegate* delegate = [GSDocParserDelegate new];
	
	[parser setDelegate: delegate];
	[parser parse];
	
	[self insert: [delegate getMethods] forTag: @"<!-- etoile-methods -->"];
	[self insert: [delegate getHeader] forTag:  @"<!-- etoile-header -->"];
	
	[delegate release];  
	[parser release];
}

- (void) insertDocument
{
	if ([documentType isEqual: @"gsdoc"])
	{
		[self insertGSDocDocument];
	}
	else if ([documentType isEqual: @"html"])
	{
		[self insertHTMLDocument];
	}
	else
	{
		ETAssertUnreachable();
	}
}

- (void) insertMenu
{
	[self insert: menuContent forTag: @"<!-- etoile-menu -->"];
}

- (void) insertProjectClassesList
{
	if (nil == projectClassMapping)
  		return;
	
    NSArray *classNames = [[projectClassMapping allKeys] 
		sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    H list = UL;
	
    FOREACH(classNames, className, NSString *)
    {
		NSString *url = [projectClassMapping objectForKey: className]; 
		NSString *link = [NSString stringWithFormat: @"<a href=\"%@\">%@</a>", url, className];
	
		[list and: [LI with: link]];
    }

    [self insert: [[DIV id: @"project-classes-list" with: list] content] 
	      forTag: @"<!-- etoile-list-classes -->"];
}

- (void) insertClassesLinks
{
	if (nil == classMapping)
		return;
	
    // Add the list of our project classes
    [classMapping addEntriesFromDictionary: projectClassMapping];
	
    NSArray *classNames = [[classMapping allKeys] 
		sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    
    // FIXME: This is the _wrong_ way to insert those links -- as we'll miss for example
    // NSConditionLock vs NSCondition (both will point to NSCondition). What should be done
    // is to insert the links in the gsdoc generator directly, and for the html document
    // do correct replacing, not this crude one. But well, that'll be for next version.
    // (Plus this loop is not exactly an efficient way to do this)
    FOREACH(classNames, className, NSString *)
    {
		NSString *url = [classMapping objectForKey: className];
		NSString *link = [NSString stringWithFormat: @"<a href=\"%@\">%@</a>", url, className];
		
		[self insert: link forTag: className];
    }
}

- (void) weave
{
	ASSIGN(weavedContent, templateContent);

	[self insertDocument];
	[self insertMenu];
	[self insertClassesLinks];
	[self insertProjectClassesList];
}

- (NSString *) HTMLString
{
	[self weave];
	return weavedContent;
}

- (void) writeToURL: (NSURL *)outputURL
{
	[[self HTMLString] writeToURL: outputURL atomically: YES];
}

@end
