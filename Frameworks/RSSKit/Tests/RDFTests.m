/** -*-objc-*-
 */

#import "RDFTests.h"

#define PATH @"tests/wellformed/rdf/"

@implementation RDFTests

-(void)testChannelDesc
{
  RSSFeed* feed =
    [RSSFeed feedWithResource: PATH @"rdf_channel_description.xml"];
  
  [feed fetch];
  
  if ([[feed description] isEqualToString: @"Example description"]) {
    UKPass();
  } else {
    UKFail();
  }
}

-(void)testChannelLink
  {
  }

-(void)testChannelTitle
  {
  }

-(void)testItemDesc
  {
  }

-(void)testItemLink
  {
  }

-(void)testItemRDFAbout
  {
  }

-(void)testItemTitle
  {
  }

-(void)testRSS090ChannelTitle
  {
  }

-(void)testRSS090ItemTitle
  {
  }

-(void)testRSSV10
  {
  }

-(void)testRSSV10NotDefaultNS
  {
  }

@end

