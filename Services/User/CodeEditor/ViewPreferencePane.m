#import "ViewPreferencePane.h"
#import "GNUstep.h"

@implementation ViewPreferencePane

- (void) showLineNumberAction: (id) sender
{
  [defaults setBool: [showLineNumberButton state]
            forKey: CodeEditorShowLineNumberDefaults];
}

- (id) init 
{
  self = [super init];

  if ([NSBundle loadNibNamed: @"ViewPreferencePane" owner: self] == NO) {
    NSLog(@"Failed to load nib file");
    [self dealloc];
    return nil;
  }
  ASSIGN(_mainView, [_window contentView]);
  RETAIN(_mainView);

  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
         @"01View", @"identifier",
         @"View", @"name",
         @"01View", @"path",
         [NSValue valueWithPointer: [self class]], @"class",
         self, @"instance", nil];
  [[PKPreferencePaneRegistry sharedRegistry] addPlugin: dict];

  ASSIGN(defaults, [NSUserDefaults standardUserDefaults]);

  return self;
}

- (void) dealloc
{
  DESTROY(defaults);
  [super dealloc];
}

- (void) willSelect
{
  BOOL b = [defaults boolForKey: CodeEditorShowLineNumberDefaults];
  [showLineNumberButton setState: b];
  anythingChanged = NO;
}

- (void) willUnselect
{
  if (anythingChanged == YES) {
  }
  anythingChanged = NO;
}

@end

NSString *const CodeEditorShowLineNumberDefaults = @"CodeEditorShowLineNumberDefaults";

