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

#import "SearchController.h"

enum searchThreadLockConditions {
   ConditionThreadInactive,
   ConditionThreadReady
};

@interface SearchController (Private)
- (void) myRestartSearchAfterTime: (NSTimeInterval)interval;
- (void) myRestartSearch;
- (void) myAbortCurrentSearch;
- (void) mySearchWillStart;
- (void) mySearchDidFoundHit: (PopplerTextHit*)hit;
- (void) mySearchDidCompletePage: (PopplerPage*)page;
- (void) mySearchDidFinish;
- (int) myPercentCompleted;
@end

@implementation SearchController

- (id) init
{
   if (![super init])
      return nil;
   
   document = nil;
   currentSearch = nil;
   searchView = nil;
   searchViewVisible = NO;
   searchThreadLock = [[NSConditionLock alloc] initWithCondition: ConditionThreadInactive];
   timer = nil;
   hits = nil;
   pagesCompleted = 0;

   return self;
}

- (void) dealloc
{
   [hits release];
   [timer release];
   [searchThreadLock release];
   [currentSearch release];
   [searchView release];
   [super dealloc];
}

- (void) awakeFromNib
{
   searchView = [[SearchView alloc] initWithFrame: NSZeroRect controller: self];
   [searchView setAutoresizingMask: NSViewMaxXMargin | NSViewMinYMargin];
}

- (void) setDocument: (Document*)aDocument;
{
   document = aDocument;
}

- (void) showView;
{
   if (searchViewVisible)
      return;
   
   // reserve space for view
   [scrollView setFrameSize: NSMakeSize(NSWidth([scrollView frame]), NSHeight([scrollView frame])- NSHeight([searchView frame]))];
   
   // arrange search view at the top of the window's content view
   [searchView setFrameOrigin: NSMakePoint(0, NSHeight([NSWindow contentRectForFrameRect: [window frame] styleMask: [window styleMask]]) - NSHeight([searchView frame]))];
   [searchView setFrameSize: NSMakeSize(NSWidth([scrollView frame]), NSHeight([searchView frame]))];
   [[window contentView] addSubview: searchView];
   
   [searchView focusSearchText];
   
   searchViewVisible = YES;
}

- (void) hideView;
{
   if (!searchViewVisible)
      return;
         
   [searchView removeFromSuperview];
   [scrollView setFrameSize: NSMakeSize(NSWidth([scrollView frame]), NSHeight([scrollView frame]) + NSHeight([searchView frame]))];
   
   searchViewVisible = NO;
}

- (void) userDidModifySearchText;
{
   [self myAbortCurrentSearch];
   [self myRestartSearchAfterTime: 0.250];
}

- (void) forceQuit;
{
   if (!currentSearch || ![currentSearch running])
      return;
      
   [self myAbortCurrentSearch];
   [searchThreadLock lockWhenCondition: ConditionThreadInactive];
}

- (void) searchWillStart: (PopplerTextSearch*)search;
{
   if (search != currentSearch)
      return;
   
   [self performSelectorOnMainThread: @selector(mySearchWillStart) withObject: nil waitUntilDone: NO];
}

- (void) search: (PopplerTextSearch*)search didFoundHit: (PopplerTextHit*)hit;
{
   [self performSelectorOnMainThread: @selector(mySearchDidFoundHit:) withObject: hit waitUntilDone: NO];
}

- (void) search: (PopplerTextSearch*)search didCompletePage: (PopplerPage*)page
{
   if (search != currentSearch)
      return;
   
   [self performSelectorOnMainThread: @selector(mySearchDidCompletePage:) withObject: page waitUntilDone: NO];
}

- (void) searchDidFinish: (PopplerTextSearch*)search;
{
   if (search != currentSearch)
      return;
   
   [self performSelectorOnMainThread: @selector(mySearchDidFinish) withObject: nil waitUntilDone: NO];
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation SearchController (Private)

- (void) myRestartSearch;
{
   NSAssert(document, @"no document");
   
   [searchThreadLock lockWhenCondition: ConditionThreadInactive];

   [currentSearch release];
   currentSearch = [[document newSearch] retain];
   
   if (![searchView hasSearchText]) {
      [searchThreadLock unlockWithCondition: ConditionThreadInactive];
      [document clearSelections];
      return;
   }
   
   NSDictionary* search = [NSDictionary dictionaryWithObjectsAndKeys: currentSearch, @"search", [searchView searchText], @"text", [NSNumber numberWithInt: [document pageIndex]], @"startPage", self, @"delegate", nil];

   [NSThread detachNewThreadSelector: @selector(myPerformSearch:) toTarget: self withObject: search];
   
   [searchThreadLock unlockWithCondition: ConditionThreadReady];
}

- (void) myRestartSearchAfterTime: (NSTimeInterval)interval;
{
   if (timer && [timer isValid])
      [timer invalidate];
   
   [timer release];
   timer = [NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(myRestartSearch) userInfo: nil repeats: NO];
   [timer retain];
}

- (void) myAbortCurrentSearch;
{
   [currentSearch stop];
}

- (void) myPerformSearch: (NSDictionary*)search;
{
   NSAssert([search objectForKey: @"search"], @"no search");
   NSAssert([search objectForKey: @"text"], @"no text");
   NSAssert([search objectForKey: @"startPage"], @"no start page");
   NSAssert([search objectForKey: @"delegate"], @"no delegate");
   
   [searchThreadLock lockWhenCondition: ConditionThreadReady];

   NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
   
   [[search objectForKey: @"search"] searchFor: [search objectForKey: @"text"] from: [[search objectForKey: @"startPage"] intValue] delegate: [search objectForKey: @"delegate"]];
   
   [pool release];

   [searchThreadLock unlockWithCondition: ConditionThreadInactive];
}

- (void) mySearchWillStart;
{
   pagesCompleted = 0;
   currentHit = -1;
   [hits release];
   hits = [[NSMutableArray alloc] init];
   [searchView showProgress: YES];
   [document clearSelections];
}

- (void) mySearchDidFoundHit: (PopplerTextHit*)hit;
{
   [hits addObject: hit];

   DocumentSelection* selection = [DocumentSelection textHitSelectionWithPageIndex: [[hit page] index] region: [hit hitArea]];
   [document addSelection: selection];
   
   if (currentHit == -1) {
      currentHit = 0;
      [document jumpToSelection: selection];
   }
}

- (void) mySearchDidCompletePage: (PopplerPage*)page;
{
   pagesCompleted++;
   [searchView setPercentCompleted: [self myPercentCompleted]];
}

- (void) mySearchDidFinish;
{
   [searchView showProgress: [self myPercentCompleted] >= 100];
}

- (int) myPercentCompleted
{
   return (int)((100 * pagesCompleted) / [document countPages]);
}

@end

