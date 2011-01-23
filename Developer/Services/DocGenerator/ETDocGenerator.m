/*
	Copyright (C) 2008 Nicolas Roard

	Author:  Nicolas Roard
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import "DocPageWeaver.h"
#import "DocIndex.h"
#import "DocPage.h"

/**
 * Displays the help
 *
 * @task Display
 */
void printHelp ()
{
  NSString* help = 
  @"\n\n"
  "ETDocGenerator Help\n"
  "-------------------\n"
  "\n"
  "ETDocGenerator generates html pages from a template and one or multiple \n"
  "original documents (html files, markdown files, gsdoc files, or any \n"
  "combination of the three).\n"
  "\n"
  "The generated html files are output in the current directory.\n"
  "\n"
  "Document generation\n"
  "-------------------\n"
  "\n"
  "ETDocGenerator [-c <code source directory>] [-r <raw source directory>] \n"
  "\t\t[-m <menu file>] -t <template> [-e <external mapping file>] \n"
  "\t\t[-p <project mapping file>] [<source file 1, source file 2, ...>]\n"
  "\n"
  "\t -n : the name of the documented project. \n"
  "\t -c : the directory which contains the .gsdoc files (incompatible with \n"
  "\t      explicit source files)\n"
  "\t -r : the Markdown and HTML directory which contains the .text and .html \n"
  "\t      files (incompatible with explicit source files)\n"
  "\t -t : the html template file\n"
  "\t -m : the menu file, if not indicated ETDocGenerator will look for a \n"
  "\t      menu.html in the raw source directory\n"
  "\t -e : a file containing an xml plist with a mapping from class names to URL.\n"
  "\t      If indicated, will add links to the mentioned types in the class methods.\n"
  "\t -p : a file containing an xml plist with a mapping from class names to URL.\n"
  "\t      (used for the project classes). If indicated, will add links to the\n"
  "\t      mentioned types in the class methods.\n\n"
  "\t -o : the ouput directory where the generated html files are saved.\n"
  "\t      If not indicated, etdocgen uses the current directory.\n"
  "\t  - : the source file paths (.gsdoc, .text and .html). If indicated, will \n"
  "\t      cause both -c and -r to be ignored.\n"
  "\n"
  "Template tags\n"
  "-------------\n"
  "\n"
  "<!-- etoile-header --> will insert the generated header from a gsdoc file\n"
  "<!-- etoile-methods --> will insert the methods extracted from a gsdoc file\n"
  "<!-- etoile-menu --> will insert the content of the menu file\n"
  "<!-- etoile-document --> will insert the content of the html document\n"
  "\n";
  
  NSLog(@"%@", help);
}

/**
 * A simple utility function to generate a class mapping from a list of class names.
 *
 * @param classFile A plist file we can use as a base
 * @task Utility
 */
void generateClassMapping(NSString *classFile)
{
	NSString *content = [NSString stringWithContentsOfFile: classFile encoding: NSUTF8StringEncoding error: NULL];
	NSArray *lines = [content componentsSeparatedByString: @"\n"];
	//NSMutableDictionary *classMapping = [NSMutableDictionary new];
	NSMutableDictionary *classMapping = [NSDictionary dictionaryWithContentsOfFile: @"class-mapping-foundation.plist"];

	for (int i=0; i<[lines count]; i++)
	{
		NSString *line = [lines objectAtIndex: i];
		NSString *className = [line stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		//NSString *url = [NSString stringWithFormat: @"http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/%@_Class/Reference/Reference.html", className];
		NSString *url = [NSString stringWithFormat: @"http://developer.apple.com/documentation/Cocoa/Reference/ApplicationKit/Classes/%@_Class/Reference/Reference.html", className];

		if ([className length] > 0)
		{
			[classMapping setObject: url forKey: className];
		}
		NSLog (@"done class %@", className);
	}
	[classMapping writeToFile: @"class-mapping.plist" atomically: YES];
	return;
}

/**
 * Displays a simple error message.
 *
 * @task Display
 */
void printError()
{
  NSLog (@"Option(s) unrecognized, you may want to display the help (-h)!");
}

/**
 * Simple macro to check that the argument is different from NO.
 * 
 * @param arg a NSValue
 * @return YES if the argument is different from NO
 */
#define VALID(arg) (arg != nil && ![arg isEqual: [NSNumber numberWithBool: NO]])

/** @taskunit Finding Files */

NSString *indexFileInDirectory(NSString *aDirectory)
{
	NSArray *paths = [[NSFileManager defaultManager] directoryContentsAtPath: aDirectory];
	assert([[paths pathsMatchingExtensions: (A(@"igsdoc"))] count] == 1);
	NSString *indexFilename = [[paths pathsMatchingExtensions: A(@"igsdoc")] firstObject];

	return [aDirectory stringByAppendingPathComponent: indexFilename];
}

NSString *orderedSymbolDeclarationsFileInDirectory(NSString *aDirectory)
{
	NSArray *paths = [[NSFileManager defaultManager] directoryContentsAtPath: aDirectory];
	assert([paths containsObject: @"OrderedSymbolDeclarations.plist"]);
	return [aDirectory stringByAppendingPathComponent: @"OrderedSymbolDeclarations.plist"];
}

NSArray *sourceFilesByAddingSupportFilesFromDirectory(NSArray *sourceFiles, NSString *parserSourceDir)
{
	if ([[sourceFiles pathsMatchingExtensions: A(@"igsdoc")] isEmpty])
	{
		sourceFiles = [sourceFiles arrayByAddingObject: indexFileInDirectory(parserSourceDir)];
	}
	if ([(id)[[sourceFiles mappedCollection] lastPathComponent] containsObject: @"OrderedSymbolDeclarations.plist"] == NO)
	{
		sourceFiles = [sourceFiles arrayByAddingObject: orderedSymbolDeclarationsFileInDirectory(parserSourceDir)];
	}
	return sourceFiles;
}

/**
 * Main function. 
 *
 * First, checks the passed arguments using ETGetOptionsDictionary, then
 * constructs the DocPageWeaver object, makes it generate the documentation 
 * pages and write the returned pages as HTML files in the current directory.
 *
 * @param argc numbers of arguments
 * @param argv array of char* with the arguments
 * @task Main
 */
int main (int argc, const char * argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *options = ETGetOptionsDictionary("hn:c:r:t:m:e:p:o:", argc, (char **)argv);
	NSString *projectName = [options objectForKey: @"n"];
	NSArray *explicitSourceFiles = [options objectForKey: @""];
	NSString *parserSourceDir = [options objectForKey: @"c"];
	NSString *rawSourceDir = [options objectForKey: @"r"];
	NSString *templateFile = [options objectForKey: @"t"];
	NSString *menuFile = [options objectForKey: @"m"];
	NSString *externalClassFile = [options objectForKey: @"e"];
	//NSString * projectClassFile = [options objectForKey: @"p"];
	NSString *outputDir = [options objectForKey: @"o"];;
	NSNumber *help = [options objectForKey: @"h"];

	if (VALID(help))
	{
		printHelp();
		return 0;
	}
	// TODO: Argument checking by reusing printError(); when not handled by 
	// WeavedDocument

	DocPageWeaver *weaver = [DocPageWeaver alloc];

	if ([explicitSourceFiles isEmpty])
	{
		weaver = [weaver initWithParserSourceDirectory: parserSourceDir
		                                     fileTypes: A(@"gsdoc", @"igsdoc", @"plist")
		                            rawSourceDirectory: rawSourceDir
		                                  templateFile: templateFile];    
	}
	else
	{
		explicitSourceFiles = sourceFilesByAddingSupportFilesFromDirectory(explicitSourceFiles, parserSourceDir);
		weaver = [weaver initWithSourceFiles: explicitSourceFiles
		                        templateFile: templateFile];
	}

	[weaver setMenuFile: menuFile];
	[weaver setExternalMappingFile: externalClassFile];
	//[weaver setProjectMappingFile: projectClassFile];

	[[DocIndex currentIndex] setProjectName: projectName];

	NSArray *pages = [weaver weaveAllPages];

	if (outputDir == nil)
	{
		outputDir = [[NSFileManager defaultManager] currentDirectoryPath];
	}

	[[DocIndex currentIndex] regenerate];

	FOREACH(pages, page, DocPage *)
	{
		NSString *outputPath = [outputDir stringByAppendingPathComponent: [page name]];

		NSLog(@"Write %@ to %@", page, [outputPath stringByAppendingPathExtension: @"html"]);
		[page writeToURL: [NSURL fileURLWithPath: [outputPath stringByAppendingPathExtension: @"html"]]];
	}

	[pool drain];
	return 0;
}
