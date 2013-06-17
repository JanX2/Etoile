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
  "etdocgen Help\n"
  "-------------------\n"
  "\n"
  "etdocgen generates HTML pages from a template and one or multiple \n"
  "source documents. Valid source documents are HTML files, Markdown files, C \n"
  "and Objective-C header and source files, GSDoc files or any combination of \n"
  "the previous.\n"
  "\n"
  "The generated HTML files are output in the current directory.\n"
  "\n"
  "Document generation\n"
  "-------------------\n"
  "\n"
  "etdocgen [-c <code source directory>] [-r <raw source directory>] \n"
  "\t\t[-m <menu file>] -t <template> [-e <external mapping file>] \n"
  "\t\t[<source file 1, source file 2, ...>]\n"
  "\n"
  "\t -n : the name of the documented project. \n"
  "\t -c : the directory which contains the .h, .m, .c or .gsdoc files \n"
  "\t      (incompatible with explicit source files). Don't mix GSDoc files \n"
  "\t      along C and Objective-C files in the same directory unless you are \n"
  "\t      sure the GSDoc files don't cover the API in the C and Objective-C \n"
  "\t      files, and overwriting can be ruled out in the documentation output.\n"
  "\t -r : the Markdown and HTML directory which contains the .text and .html \n"
  "\t      files (incompatible with explicit source files)\n"
  "\t -t : the html template file\n"
  "\t -m : the menu file, if not indicated etdocgen will look for a menu.html \n"
  "\t      in the raw source directory\n"
  "\t -e : a file containing an XML plist with a mapping from class names to URL.\n"
  "\t      If indicated, will add links to the mentioned types in the class methods.\n"
  "\t -o : the ouput directory where the generated HTML files are saved.\n"
  "\t      If not indicated, etdocgen uses the current directory.\n"
  "\t  - : the source file paths (.h, .c, .m, .gsdoc, .text and .html). If \n"
  "\t      indicated, will cause both -c and -r to be ignored.\n"
  "\n"
  "Template tags\n"
  "-------------\n"
  "\n"
  "<!-- etoile-header --> will insert the generated header from one or several \n"
  "GSDoc files or C/Objective-C files.\n"
  "<!-- etoile-methods --> will insert the methods extracted from either a GSDoc \n"
  "file or an Objective-C header file.\n"
  "<!-- etoile-menu --> will insert the content of the menu file.\n"
  "<!-- etoile-document --> will insert the content of the HTML document.\n"
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

/** @taskunit Finding Files */

NSString *indexFileInDirectory(NSString *aDirectory)
{
	NSArray *paths =  [[NSFileManager defaultManager]
		contentsOfDirectoryAtPath: aDirectory error: NULL];
	assert([[paths pathsMatchingExtensions: (A(@"igsdoc"))] count] == 1);
	NSString *indexFilename = [[paths pathsMatchingExtensions: A(@"igsdoc")] firstObject];

	return [aDirectory stringByAppendingPathComponent: indexFilename];
}

NSString *orderedSymbolDeclarationsFileInDirectory(NSString *aDirectory)
{
	NSArray *paths =  [[NSFileManager defaultManager]
		contentsOfDirectoryAtPath: aDirectory error: NULL];
	assert([paths containsObject: @"OrderedSymbolDeclarations.plist"]);
	return [aDirectory stringByAppendingPathComponent: @"OrderedSymbolDeclarations.plist"];
}

NSArray *sourceFilesByAddingSupportFilesFromDirectory(NSArray *sourceFiles, NSString *parserSourceDir)
{
	if (parserSourceDir == nil)
		return [NSArray array];

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

BOOL checkOptions(NSDictionary *options)
{
	for (NSString *key in options)
	{
		BOOL isNonOptionArg = [key isEqual: @""];

		if (isNonOptionArg)
			continue;

		id value = [options objectForKey: key];
		BOOL isValidString = ([value isEqual: @""] == NO && [[value stringValue] hasPrefix: @"-"] == NO);
		BOOL isValidNumber = [value isNumber];

		if (isValidNumber == NO && isValidString == NO)
		{
			NSLog(@"Found invalid argument %@ for option %@", value, key);
			return NO;
		}
	}
	return YES;
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
	@autoreleasepool {
		NSDictionary *options = ETGetOptionsDictionary("hn:c:r:t:m:e:o:i:", argc, (char **)argv);

		if (checkOptions(options) == NO)
		{
			return EXIT_FAILURE;
		}

		NSString *projectName = [options objectForKey: @"n"];
		NSArray *explicitSourceFiles = [options objectForKey: @""];
		NSString *parserSourceDir = [options objectForKey: @"c"];
		NSString *rawSourceDir = [options objectForKey: @"r"];
		NSString *supportDir = [options objectForKey: @"i"];
		NSString *templateFile = [options objectForKey: @"t"];
		NSString *menuFile = [options objectForKey: @"m"];
		NSString *externalClassFile = [options objectForKey: @"e"];
		NSString *outputDir = [options objectForKey: @"o"];;
		NSNumber *help = [options objectForKey: @"h"];

		if ([help boolValue])
		{
			printHelp();
			return EXIT_SUCCESS;
		}

		DocPageWeaver *weaver = [DocPageWeaver alloc];

		if (parserSourceDir != nil || rawSourceDir != nil)
		{
			NSArray *rawSourceDirs = (rawSourceDir != nil ? [NSArray arrayWithObject: rawSourceDir] : [NSArray array]);

			weaver = [weaver initWithParserSourceDirectory: parserSourceDir
			                                     fileTypes: A(@"gsdoc", @"igsdoc", @"plist")
			                          rawSourceDirectories: rawSourceDirs
			                         additionalSourceFiles: explicitSourceFiles
			                                  templateFile: templateFile];    
		}
		else
		{
			explicitSourceFiles = sourceFilesByAddingSupportFilesFromDirectory(explicitSourceFiles, supportDir);
			weaver = [weaver initWithSourceFiles: explicitSourceFiles
			                        templateFile: templateFile];
		}

		[weaver setMenuFile: menuFile];
		[weaver setExternalMappingFile: externalClassFile];

		[[DocIndex currentIndex] setProjectName: projectName];

		NSArray *pages = [weaver weaveAllPages];

		if (outputDir == nil)
		{
			outputDir = [[NSFileManager defaultManager] currentDirectoryPath];
		}

		[[DocIndex currentIndex] setOutputDirectory: outputDir];
		[[DocIndex currentIndex] regenerate];

		NSMutableSet *usedPaths = [NSMutableSet set];

		for (DocPage *page in pages)
		{
			NSString *outputPath = [outputDir stringByAppendingPathComponent: [page name]];
			
			// FIXME: Doesn't compile... ETAssert([usedPaths containsObject: outputPath] == NO);
			assert([usedPaths containsObject: outputPath] == NO);
			//NSLog(@"Write %@ to %@", page, [outputPath stringByAppendingPathExtension: @"html"]);

			[page writeToURL: [NSURL fileURLWithPath: [outputPath stringByAppendingPathExtension: @"html"]]];

			[usedPaths addObject: outputPath];
		}

	}
	return EXIT_SUCCESS;
}
