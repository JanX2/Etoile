#import <Foundation/Foundation.h>
#import "ETGetOptionsDictionary.h"
#import "DocumentWeaver.h"

/**
 * Author: Nicolas Roard
 */

/**
 * Nouvelle classe
 */

@interface Nouvelle : NSObject

/**
 * pilou
 */
- (void) pilou;

/**
 * redou
 * @return redou
 */
+ (int) redou;

@end

@interface Grololo : Nouvelle
{
  /** a name */
  NSString* name;
}
- (void) rololo;
@end

/**
 * Display the help
 *
 * @task Display
 * @return du vent
 */
void printHelp ()
{
  NSString* help = 
  @"\n\n"
  "ETDocGenerator Help\n"
  "-------------------\n"
  "\n"
  "ETDocGenerator generates a final html page from an \n"
  "original document (an html formatted file or a gsdoc file)\n"
  "and a template.\n"
  "\n"
  "Document generation\n"
  "-------------------\n"
  "\n"
  "ETDocGenerator -i <input file> -t <template> -o <output>\n"
  "\t\t[-m <menu file>] [-c <class mapping file>]\n\n"
  "\t -i : the input file, which needs to be an html or a gsdoc file\n"
  "\t -o : the output file\n"
  "\t -t : the html template file\n"
  "\t -m : the menu file, if not indicated ETDocGenerator will look for a menu.html\n"
  "\t\t in the same directory as the input file\n"
  "\t -c : a file containing an xml plist with a mapping from class names to URL.\n"
  "\t\t If indicated, will add links to the mentioned types in the class methods.\n"
  "\t -p : a file containing an xml plist with a mapping from class names to URL.\n"
  "\t\t (used for the project classes). If indicated, will add links to the\n"
  "\t\t mentioned types in the class methods.\n"
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
 * A simple utility function to generate a class mapping from a list of class names
 *
 * @param classFile A plist file we can use as a base
 * @task Utility
 */
void generateClassMapping(NSString* classFile)
{
   NSString* content = [NSString stringWithContentsOfFile: classFile];
   NSArray* lines = [content componentsSeparatedByString: @"\n"];
   //  NSMutableDictionary* classMapping = [NSMutableDictionary new];
   NSMutableDictionary* classMapping = [NSDictionary dictionaryWithContentsOfFile: @"class-mapping-foundation.plist"];
   
   for (int i=0; i<[lines count]; i++)
   {
   NSString* line = [lines objectAtIndex: i];
   NSString* className = [line stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
   //    NSString* url = [NSString stringWithFormat: @"http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/%@_Class/Reference/Reference.html", className];
   NSString* url = [NSString stringWithFormat: @"http://developer.apple.com/documentation/Cocoa/Reference/ApplicationKit/Classes/%@_Class/Reference/Reference.html", className];
   if ([className length] > 0)
   [classMapping setObject: url forKey: className];
   NSLog (@"done class %@", className);
   }  
   [classMapping writeToFile: @"class-mapping.plist" atomically: YES];
   return;
}

/**
 * Display a simple error message.
 *
 * @task Display
 */
void printError()
{
  NSLog (@"Option(s) unrecognized, you may want to display the help (-h)!");
}

/**
 * Simple macro to check that the argument is different from NO
 * 
 * @param arg a NSValue
 * @return YES if the argument is different from NO
 */
#define VALID(arg) (arg != nil && ![arg isEqual: [NSNumber numberWithBool: NO]])

/**
 * Main function. 
 *
 * First, check the passed arguments using ETGetOptionsDictionary, then
 * constructs the DocumentWeaver object and generates the output file.
 *
 * @param argc numbers of arguments
 * @param argv array of char* with the arguments
 * @task Main
 */
void weaveDocument(int argc, const char* argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  NSDictionary* options = ETGetOptionsDictionary("i:o:t:m:hc:p:", argc, argv);
  NSString* inputFile = [options objectForKey: @"i"];
  NSString* outputFile = [options objectForKey: @"o"];
  NSString* templateFile = [options objectForKey: @"t"];
  NSString* menuFile = [options objectForKey: @"m"];
  NSString* classFile = [options objectForKey: @"c"];
  NSString* projectClassFile = [options objectForKey: @"p"];
  NSNumber* help = [options objectForKey: @"h"];
  
  //NS_DURING
  if (VALID(inputFile) && VALID(outputFile) && VALID(templateFile))
  {
    DocumentWeaver* document = [DocumentWeaver new];
    [document loadTemplate: templateFile];
    if ([document createDocumentUsingFile: inputFile])
    {
      if (VALID(menuFile))
      {
        [document setMenuWith: menuFile];
      }
      if (VALID(classFile))
      {
        NSMutableDictionary* classMapping = [NSMutableDictionary dictionaryWithContentsOfFile: classFile];
        [document setClassMapping: classMapping];
      }
      if (VALID(projectClassFile))
      {
        NSDictionary* projectClassMapping = [NSDictionary dictionaryWithContentsOfFile: projectClassFile];
        [document setProjectClassMapping: projectClassMapping];
      }
      [document writeDocument: outputFile];
      [document release];      
      return 0;
    }
    else
    {
      NSLog(@"Problem: Input file neither HTML or GSDOC");
    }
    [document release];      
  }  
  else if (VALID(help))
  {
    printHelp();
  }
  /*NS_HANDLER
    NSLog(@"Exception: %@", localException);
  NS_ENDHANDLER*/

  printError();

  [pool drain];
}

int main (int argc, const char * argv[]) {
  weaveDocument(argc, argv);
  return 0;
}
