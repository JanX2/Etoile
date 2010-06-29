//
//  DocumentWeaver.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

/** A documentation page that weaves various HTML, GSDoc, Markdown and plist 
files (usually provided on the command-line), into a new HTML representation  
based on the template tags embedded in the HTML or Markdown content.

The resulting HTML document can be retrieved with -HTMLString or written 
to a file with -writeToURL:. */
@interface WeavedDocPage : NSObject 
{
  NSString *documentType;
  NSString *documentPath;
  NSString *documentContent;
  NSString *templateContent;
  NSString *sourcePath;
  NSString *menuContent;
  NSMutableDictionary *classMapping;
  NSDictionary *projectClassMapping;
  NSString *weavedContent;
}

/** Initialises and returns a new documentation page that combines the given 
input files. */
- (id) initWithDocumentFile: (NSString *)aDocumentPath
               templateFile: (NSString *)aTemplatePath 
                   menuFile: (NSString *)aMenuPath
           classMappingFile: (NSString *)aMappingPath
    projectClassMappingFile: (NSString *)aProjectMappingPath;

/** Returns a string representation of the documentation page by weaving the 
input files. */
- (NSString *) HTMLString;

/** Writes the documentation page to the given URL atomically. */
- (void) writeToURL: (NSURL *)outputURL;

@end
