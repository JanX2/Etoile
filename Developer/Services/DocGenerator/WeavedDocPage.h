/** <abstract>WeavedDocPage represents a documentation page.</abstract>

	Copyright (C) 2008 Nicolas Roard

	Authors:  Nicolas Roard, 
	          Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>

@class DocHeader, DocMethod, DocFunction, HtmlElement;

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

/** @task Initialization and Identity */

/** Initialises and returns a new documentation page that combines the given 
input files. */
- (id) initWithDocumentFile: (NSString *)aDocumentPath
               templateFile: (NSString *)aTemplatePath 
                   menuFile: (NSString *)aMenuPath;

/** Returns the page name.

Can be used as a file name when saving the page, as <em>etdocgen</em> does. */
- (NSString *) name;

/** @task Writing to File */

/** Writes the page to the given URL atomically. */
- (void) writeToURL: (NSURL *)outputURL;

/** @task Page Building */

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

/** @task HTML Generation */

/** Returns a string representation of the whole page by weaving the input files. */
- (NSString *) HTMLString;
/** Returns the main page content rendered as an HtmlElement array, including 
elements such as <em>Instance Methods</em>,<em>Macros</em> etc.

Menu, navigation bar etc. are not present in the returned HTML representation 
unlike -HTMLString which does include them in its ouput. */
- (NSArray *) mainContentHTMLRepresentations;
/** Returns the given methods or functions rendered as a HTML element tree.

Both methods and functions are sorted by tasks before being rendered to HTML.

Task names are output with a &lt;h4&gt; header.<br />
A title is also added, which uses a &lt;h3;&gt; header.

See also DocSubroutine, DocMethod and DocFunction. */
- (HtmlElement *) HTMLRepresentationWithTitle: (NSString *) aTitle 
                                  subroutines: (NSDictionary *)subroutinesByTask;
@end
