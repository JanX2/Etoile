//
//  DocumentWeaver.m
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DocumentWeaver.h"
#import "GSDocParserDelegate.h"
#import "HtmlElement.h"
#import "GSDocParser.h"

@implementation DocumentWeaver

- (void) dealloc
{
  [template release];
  [sourcePath release];
  [menu release];
  [super dealloc];
}

- (void) loadTemplate: (NSString*) inputTemplate
{
  template = [NSString stringWithContentsOfFile: inputTemplate];
  [template retain];
}

- (void) insert: (NSString*) content forTag: (NSString*) aTag
{
  NSParameterAssert(content != nil);
  NSString* after = [template stringByReplacingOccurrencesOfString: aTag withString: content];
  [template release];
  [after retain];
  template = after;
}

- (void) setSourcePathWith: (NSString*) aFile
{
  [sourcePath release];
  sourcePath = [aFile stringByDeletingLastPathComponent];
  if ([sourcePath length] == 0)
  {
    [sourcePath release];
    sourcePath = [[NSString alloc] initWithString: @"."];
  }
  [sourcePath retain];
}

- (void) setMenuWith: (NSString*) aFile
{
  [menu release];
  menu = [NSString stringWithContentsOfFile: aFile];
  [menu retain];
}

- (void) setClassMapping: (NSDictionary*) aMapping
{
  [aMapping retain];
  [classMapping release];
  classMapping = aMapping;
}

- (void) setProjectClassMapping: (NSDictionary*) aMapping
{
  [aMapping retain];
  [projectClassMapping release];
  projectClassMapping = aMapping;
}

- (BOOL) createDocumentUsingFile: (NSString*) aFile
{
  if ([[aFile pathExtension] isEqualToString: @"gsdoc"])
  {
    [self createDocumentUsingGSDocFile: aFile];
    return YES;
  }
  else if ([[aFile pathExtension] isEqualToString: @"html"])
  {
    [self createDocumentUsingHTMLFile: aFile];
    return YES;
  }
  return NO;
}

- (void) createDocumentUsingHTMLFile: (NSString*) htmlFile
{
  [self setSourcePathWith: htmlFile];
  NSString* content = [NSString stringWithContentsOfFile: htmlFile];
  [self insert: content forTag: @"<!-- etoile-document -->"];
}

- (void) createDocumentUsingGSDocFile: (NSString*) gsdocFile
{
  [self setSourcePathWith: gsdocFile];
  NSURL *xmlURL = [NSURL fileURLWithPath: gsdocFile];
  NSXMLParser* parser = [[NSXMLParser alloc] initWithContentsOfURL: xmlURL];
  GSDocParserDelegate* delegate = [GSDocParserDelegate new];
  //GSDocParser* delegate = [GSDocParser new];
  [parser setDelegate: delegate];
  //[delegate setGSDocDirectory: [gsdocFile stringByDeletingLastPathComponent]];
  //[delegate setGSDocFile: gsdocFile];
  [parser parse];
  [self insert: [delegate getMethods] forTag: @"<!-- etoile-methods -->"];
  [self insert: [delegate getHeader] forTag:  @"<!-- etoile-header -->"];
  [delegate release];  
  [parser release];
}

- (void) insertMenu
{
  if (menu == nil)
  {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* menuPath = [[[fm currentDirectoryPath] 
		stringByAppendingPathComponent: sourcePath]
		stringByAppendingPathComponent: @"menu.html"];

    if ([fm fileExistsAtPath: menuPath])
    {
      menu = [NSString stringWithContentsOfFile: menuPath];
      [menu retain];
    }
	else
	{
		NSLog(@"WARNING: Found no menu.html at %@", menuPath);
	}
	if (menu == nil)
	{
		NSLog(@"WARNING: No menu available to replace the template tag");
		return;
	}
  }
  [self insert: menu forTag: @"<!-- etoile-menu -->"];
}

- (void) insertProjectClassesList
{
  if (projectClassMapping)
  {
    NSArray* uclasses = [projectClassMapping allKeys];
    NSArray* classes = [uclasses sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    H list = UL;
    for (int i=0; i<[classes count]; i++)
    {
      NSString* className = [classes objectAtIndex: i];
      NSString* url = [projectClassMapping objectForKey: className]; 
      NSString* link = [NSString stringWithFormat: @"<a href=\"%@\">%@</a>", url, className];
      [list and: [LI with: link]];
    }
    H divList = [DIV id: @"project-classes-list" with: list];
    [self insert: [divList content] forTag: @"<!-- etoile-list-classes -->"];
  }
}

- (void) insertClassesLinks
{
  if (classMapping)
  {
    // Add the list of our project classes
    [classMapping addEntriesFromDictionary: projectClassMapping];

    NSArray* uclasses = [classMapping allKeys];
    NSArray* classes = [uclasses sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    
    // FIXME: This is the _wrong_ way to insert those links -- as we'll miss for example
    // NSConditionLock vs NSCondition (both will point to NSCondition). What should be done
    // is to insert the links in the gsdoc generator directly, and for the html document
    // do correct replacing, not this crude one. But well, that'll be for next version.
    // (Plus this loop is not exactly an efficient way to do this)
    for (int i=0; i<[classes count]; i++)
    {
      NSString* className = [classes objectAtIndex: i];
      NSString* url = [classMapping objectForKey: className];
      NSString* link = [NSString stringWithFormat: @"<a href=\"%@\">%@</a>", url, className];

      [self insert: link forTag: className];
    }
  }
}

- (void) writeDocument: (NSString*) outputFile
{
  [self insertMenu];
//  [self insertClassesLinks];
  [self insertProjectClassesList];
  [template writeToFile: outputFile atomically: YES];
}

@end
