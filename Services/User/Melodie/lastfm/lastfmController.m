#include <AppKit/AppKit.h>
#include <GNUstepBase/GSXML.h>
#include "lastfmController.h"

NSString *baseurl = @"http://ws.audioscrobbler.com/2.0/?api_key=2cf6a70654e41e718aef1de6827c7300";

@implementation lastfmController

- (void) get: (id)sender
{
	NSString *encArtist = [[artist stringValue] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSString *encAlbum = [[album stringValue] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];

	NSURL *request = [NSURL URLWithString: [NSString stringWithFormat:@"%@&method=album.getinfo&artist=%@&album=%@", baseurl, encArtist, encAlbum]];
	NSLog(@"requested: %@", [request absoluteString]);
	GSXMLParser *parser = [GSXMLParser parserWithContentsOfURL: request];
	if ([parser parse])
	{
		GSXPathContext *c = [[GSXPathContext alloc] initWithDocument: [parser document]];
		GSXPathString *result = [c evaluateExpression: @"string(/lfm/album/image[@size = 'large']/text())"];
		[image setImage: [[[NSImage alloc] initWithContentsOfURL: [NSURL URLWithString: [result stringValue]]] autorelease]];
	}
	else
		NSLog(@"error parsing file");
}

@end
