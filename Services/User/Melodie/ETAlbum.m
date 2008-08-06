#import <EtoileFoundation/EtoileFoundation.h>
#import <IconKit/IconKit.h>

#import "ETAlbum.h"
#import "ETMusicFile.h"
#import "ETLastFM.h"

@implementation ETAlbum

+ (void) initialize
{
	[super initialize];

	NSDictionary *pt = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithInt: kCOStringProperty], kETArtistProperty,
		[NSNumber numberWithInt: kCOStringProperty], kETAlbumProperty,
		nil];
		
	[self addPropertiesAndTypes: pt];
	DESTROY(pt);
}

- (void) dealloc
{
	DESTROY(cover);
	[super dealloc];
}

- (BOOL) isOrdered
{
	return YES;
}

- (NSString *) name
{
	return [self valueForProperty: kETAlbumProperty];
}

- (NSString *) displayName
{
	return [self name];
}

- (NSImage *) icon
{
	if (cover == nil)
		cover = [[ETLastFM coverWithArtist: [self valueForProperty: kETArtistProperty]
	                                album: [self valueForProperty: kETAlbumProperty]] retain];
    if (cover == nil)
    	cover = [[[IKIcon iconWithIdentifier: @"audio-x-generic"] image] retain];
    	
	return cover;
}

@end
