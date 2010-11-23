/** <abstract>WeavedDocPage represents a documentation page.</abstract>

	Copyright (C) 2008 Nicolas Roard

	Authors:  Nicolas Roard, 
	          Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class DocHeader, DocMethod, DocFunction;

/** A documentation page that weaves various HTML, GSDoc, Markdown and plist 
files (usually provided on the command-line), into a new HTML representation  
based on the template tags embedded in the HTML or Markdown content.

You usually don't instantiate this class, but give the documentation input files 
to DocPageWeaver which will create new WeavedDocPages instances and return 
them.<br />
The returned pages can then be written to disk with -writeToURL: or 
their HTML representation retrieved with -HTMLString.

Subclasses can be written to customize the presentation and how the various 
elements (methods, macros, menu etc.) are laid out. Subclassing support is 
experimental and untested. */
@interface WeavedDocPage : NSObject 
{
	NSString *documentType;
	NSString *documentPath;
	NSString *documentContent;
	NSString *templateContent;
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

/** Returns the page name.

Can be used as a file name when saving the page, as <em>etdocgen</em> does. */
- (NSString *) name;

/** Returns a string representation of the page by weaving the input files. */
- (NSString *) HTMLString;

/** Writes the page to the given URL atomically. */
- (void) writeToURL: (NSURL *)outputURL;

/** Sets the page header. */
- (void) setHeader: (DocHeader *)aHeader;
/** Returns the page header. */
- (DocHeader *) header;
/** Adds a class method documentation to the page. */
- (void) addClassMethod: (DocMethod *)aMethod;
/** Adds a instance method documentation to the page. */
- (void) addInstanceMethod: (DocMethod *)aMethod;
/** Adds a function documentation to the page. */
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
