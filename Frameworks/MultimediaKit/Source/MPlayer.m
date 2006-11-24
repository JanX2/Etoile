#import <MultimediaKit/MPlayer.h>

@implementation MPlayer
- (id) init;
{
  /* Try to find the mplayer */
  NSEnumerator *e = [[[[[NSProcessInfo processInfo] environment] objectForKey: @"PATH"] componentsSeparatedByString: @":"] objectEnumerator];
  NSString *path;
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL isDir, found = NO;
  while ((path = [[e nextObject] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]])) {
    path = [path stringByAppendingPathComponent: @"mplayer"];
    if ([fm fileExistsAtPath: path isDirectory: &isDir] && (isDir == NO)) {
      found = YES;
      break;
    }
  }
  if (found == YES) {
    //NSLog(@"Use MPlayer at %@", path);
    [self initWithPathToPlayer: path];
  } else {
    NSLog(@"Cannot find mplayer");
    [self dealloc];
    return nil;
  }
  return self;
}

/** MMPlayer protocol **/
- (void) play: (id) sender
{
  if (myState == kPaused) {
    // mplayer is paused then unpause it
    [self pause];
  } else {
    [self play];
  }
}

- (void) stop: (id) sender
{
  [self stop];
}

- (void) pause: (id) sender
{
  if (myState == kPlaying) {
      [self pause];
  }
}

- (void) setURL: (NSURL *) u
{
  ASSIGN(url, u);
  if ([url isFileURL]) {
    [self setMovieFile: [url path]];
  } else {
    [self setMovieFile: [url absoluteString]];
  }
  [self loadInfoBeforePlayback: YES];
}

- (NSURL *) url
{
  return url;
}

- (void) setXWindow: (Window) w
{
  xwin = w;
}

- (NSSize) size
{
  if (myMplayerTask == nil) {
    /* It is never played. Need to load the information */
    NSLog(@"load info");
    [self loadInfo];
  } 

  NSDictionary *dict = [self info];
  int w = 0, h = 0;
  id object;
  
  object = [dict objectForKey: @"ID_VIDEO_WIDTH"];
  if (object) {
    w = [object intValue];
  }

  object = [dict objectForKey: @"ID_VIDEO_HEIGHT"];
  if (object) {
    h = [object intValue];
  }
  return NSMakeSize(w, h);
}

- (void) setVolumeInPercentage: (unsigned int) volume
{
  [self setVolume: volume];
  [self applySettingsWithRestart: NO];
}

- (unsigned int) volumeInPercentage
{
  return myVolume;
}

@end

