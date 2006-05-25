/** -*-objc-*-
 */

#import "RDFTests.h"

#define PATH = @"tests/wellformed/rdf/"

@implementation RDFTests

-(void)testChannelDesc
{
#warning Write me, I am half-written code! :-)

  RSSFeed* feed =
    [RSSFeed feedWithURL:
	       /** Okay, I took a break when working on this. :-)
		   I got Resource files in Resources/tests/wellformed/rdf/
		   If someone knows how to convert resource file names
		   into URLs without looking at the FoundationKit doc,
		   please fill it in. :-)
	       */
     ];
}

-(void)testChannelLink
  {
  }

-(void)testChannelTitle;
-(void)testItemDesc;
-(void)testItemLink;
-(void)testItemRDFAbout;
-(void)testItemTitle;
-(void)testRSS090ChannelTitle;
-(void)testRSS090ItemTitle;
-(void)testRSSV10;
-(void)testRSSV10NotDefaultNS;

@end

