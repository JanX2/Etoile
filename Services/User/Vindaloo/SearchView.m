/*
 * Copyright (C) 2005  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SearchView.h"
#import "ToolViewBuilder.h"
#import "SearchController.h"

@interface SearchView (Private)
- (void) myCreateControls;
@end

@implementation SearchView

- (id) initWithFrame: (NSRect)aFrame controller: (SearchController*)aController;
{
   if (![super initWithFrame: aFrame])
      return nil;
   
   controller = aController;
   percentCompleted = 0;

   [self myCreateControls];
   [searchTF setDelegate: self];
   [self showProgress: NO];

   return self;
}

- (BOOL) hasSearchText;
{
   return [[[searchTF stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] length] > 0;
}

- (NSString*) searchText;
{
   return [searchTF stringValue];
}

- (void) focusSearchText;
{
   [[self window] makeFirstResponder: searchTF];
}

- (void) showProgress: (BOOL)flag;
{
   if (!flag)
      [percentCompletedTF setStringValue: @""];
   else
      [self setPercentCompleted: percentCompleted];
}

- (void) setPercentCompleted: (int)percent;
{
   percentCompleted = percent;
   [percentCompletedTF setStringValue: [NSString stringWithFormat: @"%3d%% completed", percent]];
}

- (void) controlTextDidChange: (NSNotification*)notification
{
   [controller userDidModifySearchText];
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation SearchView (Private)

- (void) myCreateControls;
{
   searchTF = [[[NSTextField alloc] initWithFrame: NSZeroRect] autorelease];
   [searchTF setFont: [NSFont controlContentFontOfSize: [NSFont systemFontSize]]];
   [searchTF setAlignment: NSLeftTextAlignment];
   [searchTF sizeToFit];
   [searchTF setFrameSize: NSMakeSize(120, NSHeight([searchTF frame]))];
   
   percentCompletedTF = [[[NSTextField alloc] initWithFrame: NSZeroRect] autorelease];
   [percentCompletedTF setEditable: NO];
   [percentCompletedTF setSelectable: NO];
   [percentCompletedTF setBordered: NO];
   [percentCompletedTF setBezeled: NO];
   [percentCompletedTF setDrawsBackground: NO];
   [percentCompletedTF setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
   [percentCompletedTF setAlignment: NSLeftTextAlignment];
   [percentCompletedTF setStringValue: @"100% completed"];
   [percentCompletedTF sizeToFit];

   ToolViewBuilder* builder = [ToolViewBuilder builderWithView: self yBorder: 2.0];
   [builder setSpacing: 0.0];
   [[builder advance: 5.0] addViewVerticallyCentered: searchTF];
   [[builder advance: 5.0] addViewVerticallyCentered: percentCompletedTF];
}

@end
