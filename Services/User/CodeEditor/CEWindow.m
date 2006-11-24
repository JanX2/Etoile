#import "CEWindow.h"
#import "CETextView.h"
#import "CETabView.h"
#import "GNUstep.h"

@implementation CEWindow

/* Private */
- (NSScrollView *) _newScrollView: (NSRect) rect; 
{
  rect.origin = NSMakePoint(0, 0);
  NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame: rect];
  [scrollView setBorderType: NSBezelBorder];
  [scrollView setHasHorizontalScroller: YES];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [[scrollView contentView] setAutoresizesSubviews:YES];

  rect.size = [scrollView contentSize];
  CETextView *view = [[CETextView alloc] initWithFrame: rect];
  [view setMinSize: NSMakeSize(0,0)];
  [view setMaxSize: NSMakeSize(1e7, 1e7)];
  [view setRichText: NO];
  [view setSelectable: YES];
  [view setImportsGraphics: NO];
  [view setUsesFontPanel: NO];
  [view setUsesRuler: NO];
  [view setVerticallyResizable: YES];
  [view setHorizontallyResizable: YES];
  [view setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
  [textViews addObject: view];
#ifdef GNUSTEP
  [[view textContainer] setContainerSize: NSMakeSize(1e7, 1e7)];
#endif

  [scrollView setDocumentView: view];
  [self makeFirstResponder: view];
  DESTROY(view);
  return AUTORELEASE(scrollView);
}
/* End of private */

- (void) setTitleWithPath: (NSString *) p
{
  NSString *last = [p lastPathComponent];
  NSString *dir = [p stringByDeletingLastPathComponent];
  NSString *dash = [NSString stringWithUTF8String: "\u2014"];
  [self setTitle: [NSString stringWithFormat: @"%@ %@ %@", last, dash, dir]];
}

- (void) removeTextView: (CETextView *) textView
{
  if ([textViews count] == 1) {
    /* close window */
    [self close];
    return;
  }

  /* Find the right tab item */
  NSEnumerator *e = [[tabView tabViewItems] objectEnumerator];
  NSTabViewItem *item;
  while ((item = [e nextObject])) {
    if ([[item view] documentView] == textView) {
      [tabView removeTabViewItem: item];
      [textViews removeObject: textView];
      break;
    }
  }
  if ([textViews count] == 1) {
    /* Put up the scroll view */
    item = [tabView tabViewItemAtIndex: 0];
    NSScrollView *view = [item view];
    RETAIN(view);
    [tabView removeTabViewItem: item];
    [tabView removeFromSuperview];
//    [view setFrame: NSMakeRect(0, 0, 50, 50)];
    [view setFrame: [[self contentView] bounds]];
    [[self contentView] addSubview: view];
    [self makeFirstResponder: view];
    RELEASE(view);
  }
}

- (CETextView *) mainTextView
{
  if ([textViews count] == 1) {
    return [textViews objectAtIndex: 0];
  } 
  return [[[tabView selectedTabViewItem] view] documentView];
}

- (CETextView *) createNewTextViewWithFileAtPath: (NSString *) path
{
  NSScrollView *scrollView;
  if ([textViews count] == 1) {
    if (tabView == nil) { 
      tabView = [[CETabView alloc] initWithFrame: [[self contentView] bounds]];
      [tabView setAutoresizingMask: (NSViewWidthSizable | NSViewHeightSizable)];
      [tabView setDelegate: self];
    }
    scrollView = [[[self contentView] subviews] objectAtIndex: 0];;
    RETAIN(scrollView);
    [scrollView removeFromSuperview];
    [scrollView setFrame: [tabView contentRect]];
    [tabView setFrame: [[self contentView] bounds]];
    [[self contentView] addSubview: tabView];
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier: [NSString stringWithFormat: @"%p", scrollView]]; /* Hope it is unique */
    [item setView: scrollView];
    [item setLabel: [[scrollView documentView] displayName]];
    [tabView addTabViewItem: item];
    DESTROY(item);
    DESTROY(scrollView);
  } 

  if (tabView == nil) {
    NSLog(@"Internal Error: no tab view");
    return;
  }

  scrollView = [self _newScrollView: [tabView contentRect]];

  NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier: [NSString stringWithFormat: @"%p", scrollView]]; /* Hope it is unique */
  [item setView: scrollView];
  [tabView addTabViewItem: item];
  if (path) {
    [[scrollView documentView] loadFileAtPath: path];
  } 
  [item setLabel: [[scrollView documentView] displayName]];
  [tabView selectLastTabViewItem: self];
  DESTROY(item);
  [self makeFirstResponder: [scrollView documentView]];
  return [scrollView documentView];
}

- (NSArray *) textViews
{
  return textViews;
}

/* Action */
- (void) previousTab: (id) sender
{
  [tabView selectPreviousTabViewItem: sender];
}

- (void) nextTab: (id) sender
{
  [tabView selectNextTabViewItem: sender];
}

/* Override */
- (BOOL) windowShouldClose: (id) sender
{
  /* Make sure all text views is saved */
  NSEnumerator *e = [textViews objectEnumerator];
  CETextView *view;
  while ((view = [e nextObject])) {
    if ([view isEdited]) {
      int result = NSRunAlertPanel(@"Window will be closed", @"There are unsaved documents. Are you sure to close this window ?", @"Cancel", @"Close Anyway", nil, nil);
      if (result == NSAlertDefaultReturn) {
        /* Cancel */
        return NO;
      } 
    }
  }
  return YES;
}

- (id) initWithContentRect: (NSRect) rect 
                 styleMask: (unsigned int)aStyle
                   backing: (NSBackingStoreType)bufferingType
                     defer: (BOOL)flag
{
  self = [super initWithContentRect: rect
                          styleMask: aStyle
                            backing: bufferingType
                              defer: flag];

  NSScrollView *scrollView = [self _newScrollView: rect];
  [[self contentView] addSubview: scrollView];

  textViews = [[NSMutableArray alloc] initWithObjects: [scrollView documentView], nil];

  [[NSNotificationCenter defaultCenter]
             addObserver: self
             selector: @selector(textViewFileChanged:)
             name: CETextViewFileChangedNotification
             object: nil];

  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  DESTROY(textViews);
  DESTROY(tabView);
  [super dealloc];
}

/* TabView delegate */
- (void) tabView: (NSTabView *) tv
         didSelectTabViewItem: (NSTabViewItem *) tabViewItem
{
  NSString *p = [[[tabViewItem view] documentView] path];
  [self makeFirstResponder: [[tabViewItem view] documentView]];
  if (p) {
    [self setTitleWithPath: [[[tabViewItem view] documentView] path]];
  } else {
    [self setTitle: [[[tabViewItem view] documentView] displayName]];
  }
}

/* Notifications */
- (void) textViewFileChanged: (NSNotification *) not
{
  /* Try to set up the display name and make tab view in front */
  CETextView *view = [not object];
  if ([view window] != self)
    return;

  if ([textViews count] == 1) {
    [self setTitle: [view displayName]];
    return;
  } 
  NSEnumerator *e = [[tabView tabViewItems] objectEnumerator];
  NSTabViewItem *item;
  while ((item = [e nextObject])) {
    if ([[item view] documentView] == view) {
      [item setLabel: [view displayName]];
      [tabView selectTabViewItem: item];
      return;
    }
  }
}

@end

