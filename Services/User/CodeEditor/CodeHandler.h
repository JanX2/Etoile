/*
**  CodeHandler.h
**
**  Copyright (c) 2003
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

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

typedef enum _CodeCommentType {
  NoComment,
  MultipleLineComment,
  SingleLineComment
} CodeCommentType;

@protocol CodeHandler <NSObject>

/* Called by CodeParser */
- (void) string: (NSString *) element;
- (void) number: (NSString *) element;
- (void) spaceAndNewLine: (unichar) element;
- (void) symbol: (NSString *) element;
- (void) invisible: (unichar) element;

@end

