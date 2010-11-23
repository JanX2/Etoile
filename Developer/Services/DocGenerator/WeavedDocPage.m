//
//  DocumentWeaver.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "WeavedDocPage.h"
#import "DocHeader.h"
#import "DocFunction.h"
#import "DocMethod.h"
#import "GSDocParser.h"
#import "HtmlElement.h"


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

	classMethods = [NSMutableDictionary new];
	instanceMethods = [NSMutableDictionary new];
	functions = [NSMutableDictionary new];

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
	[header release];
	[classMethods release];
	[instanceMethods release];
	[functions release];
	[super dealloc];
}

- (NSString *) name
{
	if ([header className] != nil)
    	return [header className];

	return [[documentPath lastPathComponent] stringByDeletingPathExtension];
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
	[self insert: [self getMethods] forTag: @"<!-- etoile-methods -->"];
	[self insert: [[header HTMLDescription] content] forTag:  @"<!-- etoile-header -->"];
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

- (void) weave
{
	ASSIGN(weavedContent, templateContent);

	[self insertDocument];
	[self insertMenu];
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

- (void) setHeader: (DocHeader *)aHeader
{
	ASSIGN(header, aHeader);
}

- (DocHeader *) header
{
	return header;
}

- (void) addClassMethod: (DocMethod *)aMethod
{
	NSMutableArray *array = [classMethods objectForKey: [aMethod task]];
	if (array == nil)
	{
		array = [NSMutableArray new];
		[classMethods setObject: array forKey: [aMethod task]];
		[array release];
	}
	[array addObject: aMethod];
}

- (void) addInstanceMethod: (DocMethod *)aMethod
{
	NSMutableArray *array = [instanceMethods objectForKey: [aMethod task]];
	if (array == nil)
	{
		array = [NSMutableArray new];
		[instanceMethods setObject: array forKey: [aMethod task]];
		[array release];
	}
	[array addObject: aMethod];
}

- (void) addFunction: (DocFunction *)aFunction
{
	NSMutableArray* array = [functions objectForKey: [aFunction task]];
	if (array == nil)
	{
		array = [NSMutableArray new];
		[functions setObject: array forKey: [aFunction task]];
		[array release];
	}
	[array addObject: aFunction];
}

- (void) outputMethods: (NSDictionary*) methods withTitle: (NSString*) aTitle on: (NSMutableString*) html
{
  NSArray* unsortedTasks = [methods allKeys];
  NSArray* tasks = [unsortedTasks sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
  if ([tasks count] > 0)
  {
    [html appendFormat: @"<h3>%@</h3>", aTitle];
  }
  for (int i=0; i<[tasks count]; i++)
  {
    NSString* key = [tasks objectAtIndex: i];
    [html appendFormat: @"<h4>%@</h4>", key];
    NSArray* unsortedArray = [methods objectForKey: key];
    NSArray* array = [unsortedArray sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    for (int j=0; j<[array count]; j++)
    {
      DocMethod* m = [array objectAtIndex: j];
      [html appendString: [[m HTMLDescription] content]];
    }
  }
}

- (void) outputClassMethodsOn: (NSMutableString *) html  
{
  [self outputMethods: classMethods withTitle: @"Class Methods" on: html];
}

- (void) outputInstanceMethodsOn: (NSMutableString *) html  
{
  [self outputMethods: instanceMethods withTitle: @"Instance Methods" on: html];
}

- (void) outputFunctionsOn: (NSMutableString*) html
{
  [self outputMethods: functions withTitle: @"Functions" on: html];
}

- (NSString*) getMethods
{
  NSMutableString* methods = [NSMutableString new];
  [self outputFunctionsOn: methods];
  [self outputClassMethodsOn: methods];
  [self outputInstanceMethodsOn: methods];
  return [methods autorelease];
}

@end
