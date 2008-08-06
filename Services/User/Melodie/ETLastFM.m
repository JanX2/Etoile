#include <AppKit/AppKit.h>
#include <GNUstepBase/GSXML.h>
#include "ETLastFM.h"

NSString *baseurl = @"http://ws.audioscrobbler.com/2.0/?api_key=2cf6a70654e41e718aef1de6827c7300";

@implementation ETLastFM

+ (NSImage *) coverWithArtist: (NSString *)anArtist album: (NSString *)anAlbum;
{
	if (anArtist == nil || anAlbum == nil)
		return nil;
		
	NSImage *resultImage = nil;
	NSString *encArtist = [anArtist stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSString *encAlbum = [anAlbum stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSURL *request = [NSURL URLWithString: [NSString stringWithFormat:@"%@&method=album.getinfo&artist=%@&album=%@", baseurl, encArtist, encAlbum]];
	NSLog(@"LastFM: making request: %@", [request absoluteString]);
	
	GSXMLParser *parser = [GSXMLParser parserWithContentsOfURL: request];
	if ([parser parse])
	{
		GSXPathContext *ctx = [[GSXPathContext alloc] initWithDocument: [parser document]];
		GSXPathString *result = (GSXPathString *) [ctx evaluateExpression: @"string(/lfm/album/image[@size = 'large']/text())"];
		resultImage = [[NSImage alloc] initWithContentsOfURL: [NSURL URLWithString: [result stringValue]]];
		[ctx release];
	}
	return [resultImage autorelease];
}

@end
