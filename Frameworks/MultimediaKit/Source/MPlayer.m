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

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver: self
         selector: @selector(playStateChanged:)
             name: @"MIStateUpdatedNotification"
           object: self];
  [nc addObserver: self
         selector: @selector(playStateChanged:)
             name: @"MIPlayerTerminatedNotification"
           object: self];
  [nc addObserver: self
         selector: @selector(infoReady:)
             name: @"MIInfoReadyNotification"
           object: self];

  firstTimePlay = YES;
  size = NSMakeSize(0, 0);

  return self;
}

/** MMPlayer protocol **/
- (void) play: (id) sender
{
  if (firstTimePlay == YES) {
    [self loadInfoBeforePlayback: YES];
  } else {
    [self loadInfoBeforePlayback: NO];
  }
  if (myState == kPaused) {
    // mplayer is paused then unpause it
    [self pause];
  } else {
    /* Always start from beginning */
    [self seek: 0 mode: MIAbsoluteSeekingMode];
    [self play];
  }
  firstTimePlay = NO;
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
    return NSMakeSize(0, 0);
  } 

  if (size.width == 0) {
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
  
    size = NSMakeSize(w, h);
  } 
  return size;
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

/* Notification */
- (void) playStateChanged: (NSNotification *) not
{
  NSString *name = nil;
  if ([[not name] isEqualToString: @"MIPlayerTerminatedNotification"]) {
    name = MMPlayerStopNotification;
  } else {
    id object = [[not userInfo] objectForKey: @"PlayerStatus"];
    if (object == nil) return;
    int status = [object intValue];
    //NSLog(@"status %d", status);
    switch (status) {
      case kFinished:  // terminated by reaching end-of-file
        name = MMPlayerStopNotification;
        break;
      case kStopped:  // terminated by not reaching EOF
        name = MMPlayerStopNotification;
        break;
      case kPlaying:
        name = MMPlayerStartPlayingNotification;
        break;
      case kPaused:
        name = MMPlayerPausedNotification;
        break;
      case kOpening:
        break;
      case kBuffering:
        break;
      case kIndexing:
        break;
    }
  }
  if (name) {
    [[NSNotificationCenter defaultCenter]
              postNotificationName: name 
              object: self];
  }
}

- (void) infoReady: (NSNotification *) not
{
  [[NSNotificationCenter defaultCenter]
              postNotificationName: MMPlayerInformationAvailableNotification
              object: self];
}

@end

