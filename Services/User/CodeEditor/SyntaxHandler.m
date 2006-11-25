/*
**  SyntaxHandler.m
**
**  Copyright (c) 2003, 2006
**
**  Author: Yen-Ju  <yjchenx gmail>
**
**  This library is free software; you can redistribute it and/or
**  modify it under the terms of the GNU Lesser General Public
**  License as published by the Free Software Foundation, in version 2.1
**  of the License
**
**  This library is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
**  Lesser General Public License for more details.
**
**  You should have received a copy of the GNU Lesser General Public
**  License along with this library; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import "SyntaxHandler.h"
#import "GNUstep.h"
#import <AppKit/AppKit.h>

@implementation SyntaxHandler

#define STRCMP(str) (!strcmp(cstr, str))

- (void) string: (NSString *) element
{
  const char *cstr = [element cString];
  unsigned int len = [element length];
  NSRange attributeRange = NSMakeRange(position, len);
  BOOL changeAttribute = NO;
  NSDictionary *attr = normalAttr;

  [super string: element];

  /* Comments */
  if (_commentType != NoComment)
    {
      changeAttribute = YES;
      attr = commentAttr;
    }
  else if (_stringBegin == YES)
    {
      changeAttribute = YES;
      attr = stringAttr;
    }
  else if ( (*cstr > 0x40) && (*cstr < 0x58) ) /* Capital */
    {
      /* KnownType */
      if (  STRCMP("SEL") || STRCMP("BOOL") ||
            STRCMP("Class") || STRCMP("Nil") || STRCMP("IBAction") ||
            STRCMP("IBOutlet")
         )

       {
         changeAttribute = YES;
         attr = keywordAttr;
       }
     /* Strings */
     else if ( 
               STRCMP("FALSE") || STRCMP("NO") || STRCMP("TRUE") ||
               STRCMP("YES")
             )
       {
         changeAttribute = YES;
         attr = keywordAttr;
       }
     else if ( (*cstr == 'N') && (*(cstr+1) == 'S') )
       {
         changeAttribute = YES;
         attr = keywordAttr;
       }
    }
  else if (len < 10)
    {
      /* Preprocessor */
      if (_preChar == '#')
        {
          if (
               STRCMP("import") || STRCMP("include") || STRCMP("ifdef") ||
               STRCMP("ifndef") || /*STRCMP("if defined") ||*/
               STRCMP("else") ||
               STRCMP("endif") || STRCMP("pragma") || STRCMP("define") ||
               STRCMP("warning") || STRCMP("error")
             )
           {
             attributeRange = NSMakeRange(position-1, len+1);
             changeAttribute = YES;
             attr = keywordAttr;
           }
        }
      else if (_preChar == '@')
        {
          if (
               STRCMP("class") || STRCMP("selector") ||
               STRCMP("interface") ||
               STRCMP("end") || STRCMP("encode") ||
               STRCMP("private") || STRCMP("protected")
             )
           {
             changeAttribute = YES;
             attr = keywordAttr;
           }
        }
      /* Keyword */
      else if ( 
           STRCMP("break") || STRCMP("extern") || STRCMP("continue") || 
           STRCMP("_cmd") || STRCMP("self") || STRCMP("super") || 
           STRCMP("return") || STRCMP("sizeof") || STRCMP("break") || 
           STRCMP("case") || STRCMP("default") || STRCMP("goto") || 
           STRCMP("switch") || STRCMP("if") || STRCMP("else") ||
           STRCMP("do") || STRCMP("shile") || STRCMP("for") || 
           STRCMP("while")
         )
       {
          changeAttribute = YES;
          attr = keywordAttr;
        }
      /* KnownType */
      else if ( 
                STRCMP("int") || STRCMP("long") || STRCMP("short") ||
                STRCMP("char") || STRCMP("float") || STRCMP("double") ||
                STRCMP("void") || STRCMP("union") || STRCMP("unichar") ||
                STRCMP("const") || STRCMP("signed") || STRCMP("unsigned") ||
                STRCMP("static") || STRCMP("volatile") ||
                STRCMP("enum") || STRCMP("id")
               )
        {
          changeAttribute = YES;
          attr = keywordAttr;
        }
      /* Strings */
      else if ( STRCMP("nil") )
        {
          changeAttribute = YES;
          attr = keywordAttr;
        }
    }
  else if ((len == 14) && (_preChar == '@'))
    {
      if ( STRCMP("implementation") )
        {
           changeAttribute = YES;
           attr = keywordAttr;
        }
    }

  position += len;
  _preChar = 0;

  if (changeAttribute)
    {
      attributeRange.location += _startRange.location;
      [_origin addAttributes: attr 
                       range: attributeRange];
    }
}

- (void) number: (NSString *) element 
{
  [super number: element];
  position += [element length];
  _preChar = 0;
}

- (void) spaceAndNewLine: (unichar) element 
{
  [super spaceAndNewLine: element];
  position++;
  _preChar = element;
}

- (void) symbol: (unichar) element 
{
  NSRange attributeRange;
  NSDictionary *attr;

  [super symbol: element];

  if ( ((_preChar == '/') && ((element == '*') || (element == '/'))) ||
       ((_preChar == '*') && (element == '/'))
     )
    {
      attr = commentAttr;
      attributeRange = NSMakeRange(position-1, 2);
      attributeRange.location += _startRange.location;
      [_origin addAttributes: attr
                       range: attributeRange];
    }
  else
    {
      if (_commentType != NoComment)
        {
          attr = commentAttr;
          attributeRange = NSMakeRange(position, 1);
          attributeRange.location += _startRange.location;
          [_origin addAttributes: attr
                           range: attributeRange];
        }
    }
  position++;
  _preChar = element;
}

- (void) invisible: (unichar) element
{
  [super invisible: element];
  position ++;
  _preChar = element;
}

- (void) setString: (NSMutableAttributedString *) string
{
  ASSIGN(_origin, string);
  _startRange = NSMakeRange(0, [_origin length]);
}

- (void) setRange: (NSRange) range
{
  _startRange = range;
}

- (id) init
{
  NSColor *stringColor, *keywordColor, *normalColor, *commentColor;

  self = [super init];
  _startRange = NSMakeRange(0, 0); 
  position = 0;

  /* cache */
  keywordColor = [NSColor redColor];
  commentColor = [NSColor grayColor];
  stringColor = [NSColor blueColor];
  normalColor = [NSColor blackColor];
#if 0
  preprocessorColor = [_rulesetManager colorForType: @"Preprocessor"];
  keywordsColor = [_rulesetManager colorForType: @"Keywords"];
  commentsColor = [_rulesetManager colorForType: @"Comments"];
  stringsColor = [_rulesetManager colorForType: @"Strings"];
  knowntypesColor = [_rulesetManager colorForType: @"KnownTypes"];
  normalColor = [_rulesetManager colorForType: @"Normal"];
#endif

#define MAKE_ATTRIBUTES(color) \
	[[NSDictionary alloc] initWithObjectsAndKeys: \
	color, NSForegroundColorAttributeName, \
	nil]; 

  normalAttr = MAKE_ATTRIBUTES(normalColor);
  keywordAttr = MAKE_ATTRIBUTES(keywordColor);
  commentAttr = MAKE_ATTRIBUTES(commentColor);
  stringAttr = MAKE_ATTRIBUTES(stringColor);

  return self;
}

- (void) dealloc
{
  DESTROY(_origin);
  DESTROY(commentAttr);
  DESTROY(stringAttr);
  DESTROY(keywordAttr);
  DESTROY(normalAttr);

  [super dealloc];
}

@end

