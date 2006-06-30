// -*-objc-*-

#import "DOMParser.h"

@interface FeedParser : NSObject
{
  id delegate;
}

// instantiation

+(id) parser;
-(id) init;

// parsing

-(void) parseWithRootNode: (XMLRoot*) node;


//delegate

-(void) setDelegate: (id)aDelegate;
-(id) delegate;

@end
