#import <MultimediaKit/MMPlayer.h>
#import <MultimediaKit/MPlayerInterface.h>

/* Subclass MplayerInterface to prevent polluting MPlyaerInterface */
@interface MPlayer: MplayerInterface <MMPlayer>
{
  NSURL *url;
  NSSize size; /* Cache size */
}

/** MMPlayer protocol **/
- (void) play: (id) sender;
- (void) pause: (id) sender;
- (void) stop: (id) sender;
- (void) setURL: (NSURL *) url;
- (NSURL *) url;
- (void) setXWindow: (Window) xwin;
- (NSSize) size;

@end

