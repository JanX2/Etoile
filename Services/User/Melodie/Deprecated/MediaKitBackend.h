#import <MediaKit/MKMusicPlayer.h>
#import "ETMusicBackend.h"

@interface MediaKitBackend : NSObject <ETMusicBackend> {
	MKMusicPlayer *player;
	id delegate;
}
@end
