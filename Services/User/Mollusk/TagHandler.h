/*
**  TagHandler.h
**
**  Copyright (c) 2003 - 2006
**
**  Author: Yen-Ju  <yjchenx gmail>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import "CodeHandler.h"
#import <Foundation/Foundation.h>

/** It extract tag (<xxx>) and content (string between tag)
 *  and call -tag: and -content: alternatively.
 *
 *
 *  Ex. "first <second> third </fourth> fifth sixth <seventh>" will be
 *  Content: @"first "
 *      Tag: @"second"
 *  Content: @" third "
 *      Tag: @"/fourth"
 *  Content: @" fifth "
 *  Content: @" sixth "
 *      Tag: @"seventh"
 */

typedef enum _ErrorType {
  InvalidCharacterInTag = 1 // '<<', '>>', etc;
} ErrorType;

@interface TagHandler: NSObject <CodeHandler>
{
  NSMutableString *_tag, *_content;
  BOOL _inTag;
  unichar _preSymbol;
}

// Override by subclass

- (void) tag: (NSString *) tag;
- (void) content: (NSString *) content;
- (void) special: (NSString *) special;
- (void) error: (ErrorType) type;

@end

