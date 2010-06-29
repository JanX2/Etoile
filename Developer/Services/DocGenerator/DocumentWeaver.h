//
//  DocumentWeaver.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DocumentWeaver : NSObject 
{
  NSString* template;
  NSString* sourcePath;
  NSString* menu;
  NSMutableDictionary* classMapping;
  NSDictionary* projectClassMapping;
}

- (void) loadTemplate: (NSString*) inputTemplate;
- (void) setSourcePathWith: (NSString*) aFile;

- (void) insert: (NSString*) content forTag: (NSString*) aTag;
- (void) insertMenu;
- (void) insertProjectClassesList;

- (void) setMenuWith: (NSString*) aFile;
- (void) setClassMappingWith: (NSString*) aFile;
- (void) setProjectClassMapping: (NSDictionary*) aMapping;
- (BOOL) createDocumentUsingFile: (NSString*) aFile;
- (void) createDocumentUsingHTMLFile: (NSString*) htmlFile;
- (void) createDocumentUsingGSDocFile: (NSString*) gsdocFile;

- (void) writeDocument: (NSString*) outputFile;

@end
