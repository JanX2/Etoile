// -*-objc-*-

#import <Foundation/Foundation.h>

@interface NSString (DictLineParsing)

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
-(NSArray*) parseDictLine;

/**
 * Splits the string into its dict-style components (see documentation
 * for @see(parseDictLine) for more information) and returns the
 * component with the index given in the index argument.
 */
-(NSString*) dictLineComponent: (int)index;

@end

