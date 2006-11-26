#import "CETextView.h"
#import "CELineNumberView.h"
#import "SyntaxManager.h"
#import "CodeParser.h"
#import "SyntaxHandler.h"
#import "FontPreferencePane.h"
#import "ViewPreferencePane.h"
#import "GNUstep.h"
#import <OgreKit/OgreKit.h>

static int untitled_count = 0;

@interface CETextView (Private)
- (void) fontDefaultsChanged: (NSNotification *) not;
@end

@implementation CETextView

- (void) highlightSyntax: (id) sender
{
  if (path) {
    SyntaxHandler *handler = [[SyntaxManager syntaxManager] syntaxHandlerForFile: path];
    NSLog(@"handler %@", handler);
    CodeParser *parser = [[CodeParser alloc] initWithHandler: handler
                                                      string: [self string]];
    [handler setString: [self textStorage]];
    [[self textStorage] beginEditing];
    [parser parse];
    [[self textStorage] endEditing];
    DESTROY(parser);
    NSLog(@"Done");
  }
}

- (void) showLineNumber: (id) sender
{
  showLineNumber = !showLineNumber;
  [self setShowLineNumber: showLineNumber];
}

- (void) save: (id) sender
{
  NSString *p = [self path];
  if (p) {
    [self saveFileAtPath: p];
  } else {
    [self saveAs: sender];
  }
}

- (void) saveAs: (id) sender
{
  NSSavePanel *panel = [NSSavePanel savePanel];
  int result = [panel runModal];
  if (result == NSOKButton) {
    ASSIGN(path, [panel filename]);
    ASSIGN(displayName, [path lastPathComponent]);
    [self saveFileAtPath: path];
  }
}

- (void) saveTo: (id) sender
{
  /* Almost the same as -saveAs:, but do not change the path and displayName */
  NSSavePanel *panel = [NSSavePanel savePanel];
  int result = [panel runModal];
  if (result == NSOKButton) {
    [self saveFileAtPath: [panel filename]];
  }
}

- (void) showFindPanel: (id) sender
{
  OgreTextFinder *textFinder = [OgreTextFinder sharedTextFinder];
  [textFinder setTargetToFindIn: self];
  [textFinder showFindPanel: sender]; 
}

- (void) setShowLineNumber: (BOOL) show
{
  int width = 40;
  showLineNumber = show;
  if (lineNumberView == nil) {
    NSRect rect = NSZeroRect;
    rect.size = [self maxSize];
    rect.size.width = width;
    lineNumberView = [[CELineNumberView alloc] initWithFrame: rect];
    [lineNumberView setTextView: self];
    [lineNumberView updateLineNumber: self];
  }
  if (showLineNumber) {
    [self setTextContainerInset: NSMakeSize(width, 0)];
    [self addSubview: lineNumberView];
  } else {
    [self setTextContainerInset: NSMakeSize(0, 0)];
    [lineNumberView removeFromSuperview];
  }
}

- (void) saveFileAtPath: (NSString *) absolute_path
{
  NSData *data = [[self string] dataUsingEncoding: [NSString defaultCStringEncoding]];
  [data writeToFile: absolute_path atomically: YES];
  isEdited = NO;
  [[NSNotificationCenter defaultCenter]
              postNotificationName: CETextViewFileChangedNotification
              object: self];
}

- (void) loadFileAtPath: (NSString *) absolute_path
{
  ASSIGN(path, absolute_path);
  ASSIGN(displayName, [path lastPathComponent]);
  NSData *data = [NSData dataWithContentsOfFile: absolute_path];
  /* We should check the encoding here ? */
  NSString *string = [[NSString alloc] initWithData: data 
                     encoding: [NSString defaultCStringEncoding]];
  [self setString: string];
  DESTROY(string);

  [[NSNotificationCenter defaultCenter]
              postNotificationName: CETextViewFileChangedNotification
              object: self];

  if (showLineNumber) {
    [lineNumberView updateLineNumber: self];
  }
}

- (NSString *) path
{
  return path;
}

- (NSString *) displayName
{
  if (displayName == nil) {
    if (untitled_count > 0) {
      ASSIGN(displayName, ([NSString stringWithFormat: _(@"Untitled %d"), untitled_count]));
    } else {
      ASSIGN(displayName, _(@"Untitled"));
    }
    untitled_count++;
  }
  return displayName;
}

- (BOOL) isEdited
{
  return isEdited;
}

/* Overrider */
- (void) didChangeText
{
  isEdited = YES;
}

- (id) initWithFrame: (NSRect) frame
{
  self = [super initWithFrame: frame];

  ASSIGN(defaults, [NSUserDefaults standardUserDefaults]);
  isEdited = NO;

  [[NSNotificationCenter defaultCenter]
                addObserver: self
                selector: @selector(fontDefaultsChanged:)
                name: CodeEditorFontChangeNotification
                object: nil];
  /* Set font */
  [self fontDefaultsChanged: nil];

  [self setShowLineNumber: [defaults boolForKey: CodeEditorShowLineNumberDefaults]];
  
  return self;
}

- (void) dealloc
{
  DESTROY(defaults);
  DESTROY(path);
  DESTROY(displayName);
  DESTROY(font);
  DESTROY(lineNumberView);
  [super dealloc];
}

/* Notification */
- (void) fontDefaultsChanged: (NSNotification *) not
{
  int size = [defaults integerForKey: CodeEditorFontSizeDefaults];
  if (size == 0)
    size = 12;
  NSString *name = [defaults stringForKey: CodeEditorFontNameDefaults];
  if (name) {
    ASSIGN(font, [NSFont fontWithName: name size: size]);
  } else {
    ASSIGN(font, [[NSFontManager sharedFontManager]  
                           convertFont: [NSFont systemFontOfSize: size]
                           toHaveTrait: NSFixedPitchFontMask]);
  }
  [self setFont: font];
}

@end

NSString *const CETextViewFileChangedNotification = @"CETextViewFileChangedNotification";

