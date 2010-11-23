//
//  DocumentWeaver.h
//  ETDocGenerator
//
//  Created by Nicolas Roard (Home) on 6/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class DocHeader, DocMethod, DocFunction;

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
  NSString *weavedContent;

    DocHeader *header;
    NSMutableDictionary *classMethods;
    NSMutableDictionary *instanceMethods;
    NSMutableDictionary *functions;
    //NSMutableDictionary *macros;
}

/** Initialises and returns a new documentation page that combines the given 
input files. */
- (id) initWithDocumentFile: (NSString *)aDocumentPath
               templateFile: (NSString *)aTemplatePath 
                   menuFile: (NSString *)aMenuPath;

- (NSString *) name;

/** Returns a string representation of the documentation page by weaving the 
input files. */
- (NSString *) HTMLString;

/** Writes the documentation page to the given URL atomically. */
- (void) writeToURL: (NSURL *)outputURL;

- (void) setHeader: (DocHeader *)aHeader;
- (DocHeader *) header;
- (void) addClassMethod: (DocMethod *)aMethod;
- (void) addInstanceMethod: (DocMethod *)aMethod;
- (void) addFunction: (DocFunction *)aFunction;

/**
 * This method takes one of the dictionary populated
 * by the gsdoc parsing containing the methods, sort
 * them alphabetically by Tasks, and output the result
 * formated in HTML in the string passed in argument.
 * A title is also added, which uses a <h3> header.
 * @task Writing HTML
 */
- (void) outputMethods: (NSDictionary*) methods
             withTitle: (NSString*) aTitle
                    on: (NSMutableString*) html;

/**
 * Convenience method to generate the class methods output
 * @task Writing HTML
 */
- (void) outputClassMethodsOn: (NSMutableString *) html;

/**
 * Convenience method to generate the instance methods output
 * @task Writing HTML
 */
- (void) outputInstanceMethodsOn: (NSMutableString *) html;

/**
 * Convenience method to generate the list of functions output
 * @task Writing HTML
 */
- (void) outputFunctionsOn: (NSMutableString*) html;

- (NSString*) getMethods;

@end
