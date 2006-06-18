
#import "NSString+DictLineParsing.h"

@implementation NSString (DictLineParsing)

/**
 * Splits a Dict-protocol-style string into its components and returns
 * an array with those components. A string like this consists of one
 * or more strings that are separated by a whitespace. A string that
 * contains whitespaces itself can be put into quotation marks.
 *
 * Example:
 * The string
 *     '151 "Awful" gcide "The Collaborative International Dict..."'
 *
 * would decode to:
 *     ['151', 'Awful', 'gcide', 'The Collaborative Internation...']
 */
-(NSArray*) parseDictLine
{
  NSScanner* scanner = [NSScanner scannerWithString: self];
  
  NSCharacterSet* space =
    [NSCharacterSet characterSetWithCharactersInString: @" "];
  
  NSCharacterSet* quotationMarks =
    [NSCharacterSet characterSetWithCharactersInString: @"\""];
  
  NSMutableArray* result = [NSMutableArray arrayWithCapacity: 4];
  
  while ([scanner isAtEnd] == NO) {
    // Location: At the beginning of a word, possible quotation
    //           marks not yet eaten.
    
    BOOL isQuoted = [scanner scanCharactersFromSet: quotationMarks
			     intoString: (NSString**) nil];
    
    if (isQuoted) {
      // Location: At the beginning of a word, right after the quotation
      //           mark. (FIXME: This is assuming there is no empty string!)
      
      NSString* word;
      
      [scanner scanUpToCharactersFromSet: quotationMarks
	       intoString: &word];
      
      [result addObject: [word retain]];
      
      // Location: At the end of a word, with the pointer pointing to
      //           the closing quotation marks
      
      // eat closing quotation marks
      [scanner scanCharactersFromSet: quotationMarks
	       intoString: (NSString**) nil];
      
      // Location: At the end of a word, after the quotation mark
    } else {
      // Case 2: The word is not quoted, parse to the next whitespace!
      
      // Location: At the beginning of a word without quotation marks
      NSString* word;
      
      [scanner scanUpToCharactersFromSet: space intoString: &word];
      
      [result addObject: [word retain]];
      // Location: At the end of a non-quoted word.
    }
    
    // Location: At the end of a word, we still need to eat some white
    //           spaces to reach the next word.
    [scanner scanCharactersFromSet: space
	     intoString: (NSString**) nil];
    
  } //end of while loop
  
  return result;
}

-(NSString*) dictLineComponent: (int)index
{
  NSArray* array = [self parseDictLine];
  
  if (array == nil)
    return nil;
  
  NSString* component = (NSString*) [array objectAtIndex: index];
  
  return component; // implicitely: returns nil if component was nil
}

@end
