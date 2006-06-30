
#import "FeedParser.h"

@implementation FeedParser

// instantiation

+(id) parser
{
  return AUTORELEASE([[FeedParser alloc] init]);
}

-(id) init
{
  if ((self = [super init]) != nil) {
    delegate = nil;
  }
  
  return self;
}

// parsing

-(void) parseWithRootNode: (XMLRoot*) node
{
  NSLog(@"XXX: called -parseWithRootNode: in FeedParser. It should have been called in a subclass!");
}


//delegate

-(void) setDelegate: (id)aDelegate
{
  ASSIGN(delegate, aDelegate);
}

-(id) delegate
{
  RELEASE(delegate);
  delegate = nil;
}

@end
