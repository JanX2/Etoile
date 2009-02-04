// Modified by Yen-Ju
/*
 *  MplayerInterface.m
 *  MPlayer OS X
 *
 *  Created by Jan Volf
 *	<javol@seznam.cz>
 *  Copyright (c) 2003 Jan Volf. All rights reserved.
 */

#import <MultimediaKit/MPlayerInterface.h>

// directly parsed mplayer output strings
// strings that are used to get certain data from output are not included
#define MI_PAUSED_STRING			"=====  PAUSE  ====="
#define MI_EXITING_STRING			"Exiting..."
#define MI_EXITING_QUIT_STRING		"Exiting... (Quit)"
#define MI_EXITING_EOF_STRING		"Exiting... (End of file)"
#define MI_OPENING_STRING			"Playing "
#define MI_AUDIO_FILE_STRING		"Audio file detected."
#define MI_STARTING_STRING			"Starting playback..."

#define MI_REFRESH_LIMIT			10

@implementation MplayerInterface
/************************************************************************************
 INIT & UNINIT
 ************************************************************************************/
- (id)init;
{
	[self initWithPathToPlayer:@"/usr/local/bin/mplayer"];
	return self;
}
/************************************************************************************/
- (id)initWithPathToPlayer:(NSString *)aPath
{
	if (![super init])
		return  nil;
	
	myPathToPlayer = [aPath retain];

	myInfo = [[NSMutableDictionary dictionary] retain];
	myCommandsBuffer = [[NSMutableArray array] retain];
	mySeconds = 0;
	myVolume = 100;
	myDropFrames = NO;
	myRebuildIndex = NO;
	myFullscreen = NO;
#ifndef GNUSTEP
	myVOModule = 0;
#endif
	
	//beta new
	myRootwin = NO;
	myTile = NO;
//	myadvolume = 30;
	myPostprocesing = NO;
	mynosound = NO;
	mySecondMonitor = NO;
	
	myMovieSize = NSMakeSize(0,0);
	myAspectRatio = 0;
	myMonitorAspect = 0;
	myCacheSize = 0;
	myState = 0;
	myLastUpdate = [NSDate timeIntervalSinceReferenceDate];
	settingsChanged = NO;
	restartingPlayer = NO;
	pausedOnRestart = NO;
	isRunning = NO;
	takeEffectImediately = NO;
	useIdentifyForPlayback = NO;
	myOutputReadMode = 0;
	myUpdateStatistics = NO;
	
	windowedVO = NO;
	
	return self;
}

/************************************************************************************/
// release any retained objects
- (void) dealloc
{
	if (myMplayerTask)
		[myMplayerTask release];
	if (myPathToPlayer)
		[myPathToPlayer release];
	if (myMovieFile)
		[myMovieFile release];
	if (mySubtitlesFile)
		[mySubtitlesFile release];
	if (myAudioExportFile)
		[myAudioExportFile release];
	if (myAudioFile)
		[myAudioFile release];
	if (myFontFile)
		[myFontFile release];
	if (mySubEncoding)
		[mySubEncoding release];
	if (myAddParams)
		[myAddParams release];
	if (myCommandsBuffer)
		[myCommandsBuffer release];
	if (myInfo)
		[myInfo release];
	
	[super dealloc];
}

/************************************************************************************
 PLAYBACK CONTROL
 ************************************************************************************/
- (void) play
{
	NSMutableArray *params = [NSMutableArray array];

	// add movie file
	if (myMovieFile) {
		if ([[myMovieFile lastPathComponent] isEqualToString:@"VIDEO_TS"]) {
			[params addObject:@"dvd://"];
			[params addObject:@"-dvd-device"];
		}
		[params addObject:myMovieFile];
	}
	else
		return;
	
	// add subtitles file
	if (mySubtitlesFile) {
		[params addObject:@"-sub"];
		[params addObject:mySubtitlesFile];
	}
	else {
		//[params addObject:@"-noautosub"];
	}
	
	// add audioexport file
	if (myAudioExportFile) {
		[params addObject:@"-ao"];
		[params addObject:@"pcm"];
		[params addObject:@"-aofile"];
		[params addObject:myAudioExportFile];
	}

	
	//add audio file
	if (myAudioFile) {
		[params addObject:@"-ao"];
		[params addObject:@"pcm"];
		[params addObject:@"-audiofile"];
		[params addObject:myAudioFile];
	}
	
	
	// add font file
	if (myFontFile) {
		[params addObject:@"-font"];
		[params addObject:myFontFile];
	}
	// movie size
	if (myMovieSize.width != 0) {
		if (myMovieSize.height != 0) {
			[params addObject:@"-x"];
			[params addObject:[NSString stringWithFormat:@"%1.1f",myMovieSize.width]];
			[params addObject:@"-y"];
			[params addObject:[NSString stringWithFormat:@"%1.1f",myMovieSize.height]];
		}
		else {
			[params addObject:@"-xy"];
			[params addObject:[NSString stringWithFormat:@"%1.1f",myMovieSize.width]];
		}
	}
	// aspect ratio
	if (myAspectRatio > 0) {
		[params addObject:@"-aspect"];
		[params addObject:[NSString stringWithFormat:@"%1.4f", myAspectRatio]];
	}
	if (myMonitorAspect > 0) {
		[params addObject:@"-monitoraspect"];
		[params addObject:[NSString stringWithFormat:@"%1.4f", myMonitorAspect]];
	}


	// frame dropping
	if (myDropFrames)
		[params addObject:@"-framedrop"];
	// rebuilding index
	if (myRebuildIndex)
		[params addObject:@"-forceidx"];
	// fullscreen
	if (myFullscreen)
		[params addObject:@"-fs"];
	

	//BETA rootwin
	if (myRootwin) 
		[params addObject:@"-rootwin"];
	
		
	
	//BETA TILE
	if (myTile) {
		[params addObject:@"-vf"];
		[params addObject:@"tile"];
	}
		//nosound
	if (mynosound) {
		[params addObject:@"-nosound"];
	//	[params addObject:@"-af"];
	//	[params addObject:@"volume=40"];
	}
	
#ifdef GNUSTEP
	// x window to play on it 
	if (xwin) {
		[params addObject: @"-wid"];
		[params addObject: [NSString stringWithFormat: @"%d", xwin]];
	}
#else
	if(myVOModule == 0) //quartz/quicktime
	{
		if (mySecondMonitor)
		{
			[params addObject:@"-vo"];
			[params addObject:@"quartz:device_id=1"];
		}
		else
		{
			[params addObject:@"-vo"];
			[params addObject:@"quartz"];
		}
		windowedVO = YES;
	}
	else if(myVOModule == 1) //core video
	{
		if (mySecondMonitor)
		{
			[params addObject:@"-vo"];
			[params addObject:@"macosx:device_id=1"];
		}
		else
		{
			[params addObject:@"-vo"];
			[params addObject:@"macosx"];
		}
		windowedVO = YES;
	}
	else if(myVOModule == 2) //mplayer osx
	{
		[params addObject:@"-vo"];
		[params addObject:@"macosx:shared_buffer"];
		windowedVO = NO;
	}
	else
	{
		if (mySecondMonitor)
		{
			[params addObject:@"-vo"];
			[params addObject:@"quartz:device_id=1"];
		}
		else
		{
			[params addObject:@"-vo"];
			[params addObject:@"quartz"];
		}
		windowedVO = YES;
	}
#endif
	
	if (myPostprocesing) {
		[params addObject:@"-vf-add"];
		[params addObject:@"pp"];
	}
	
	// subtitles encoding
	if (mySubEncoding) {
		[params addObject:@"-subcp"];
		[params addObject:mySubEncoding];
	}
	// subtitles scale
	if (mySubScale != 0) {
		[params addObject:@"-subfont-text-scale"];
		[params addObject:[NSString stringWithFormat:@"%d",mySubScale]];
	}
	
	// cache settings
	if (myCacheSize != 0) {
		[params addObject:@"-cache"];
		[params addObject:[NSString stringWithFormat:@"%d",myCacheSize]];
	}
	// position from which to play
	if (mySeconds != 0) {
		[params addObject:@"-ss"];
		[params addObject:[NSString stringWithFormat:@"%1.1f",mySeconds]];
	}
	// set volume
/*	[params addObject:@"-aop"];
	[params addObject:[NSString stringWithFormat:@"list=volume:volume=%d", myVolume]];
*/	// append additional params
	if (myAddParams) {
		if ([myAddParams count] > 0)
			[params addObjectsFromArray:myAddParams];
	}
	
	[params addObject:@"-slave"];
	
	if (useIdentifyForPlayback)
		[params addObject:@"-identify"];
	
	[myInfo removeAllObjects];				// prepare it for getting new values
	[myCommandsBuffer removeAllObjects];	// empty buffer before launch
	settingsChanged = NO;					// every startup settings has been made
	
	[self runMplayerWithParams:params];
}
/************************************************************************************/
- (void) stop
{
	if (myMplayerTask) {
		switch (myState) {
		case kPlaying :
//			[myMplayerTask terminate];
			[self sendCommand:@"quit"];
			break;
		case kPaused :
			[myCommandsBuffer addObject:@"quit"];
			[self sendCommand:@"pause"];
			break;
		case kStopped:
			break;
		case kFinished:
			break;
		default :
			[myCommandsBuffer addObject:@"quit"];
			break;
		}
		[self waitUntilExit];
	}
}
/************************************************************************************/
- (void) pause
{
	if (myMplayerTask) {
		switch (myState) {
		case kPlaying:					// mplayer is just playing then pause it
			[self sendCommand:@"pause"];
//			myState = kPaused;
			break;
		case kPaused:					// mplayer is paused then unpause it
			[self sendCommand:@"pause"];
			break;
		case kStopped:					// if stopped do nothing
		case kFinished:					// if finished do nothing
			break;
		default:						// otherwise save command to the buffer
			[myCommandsBuffer addObject:@"pause"];
			break;
		}
	}
}
/************************************************************************************/
- (void) seek:(float)seconds mode:(int)aMode
{		
	switch (aMode) {
	case MIRelativeSeekingMode :
		mySeconds += seconds;
		break;
	case MIPercentSeekingMode :
		
		break;
	case MIAbsoluteSeekingMode :
		mySeconds = seconds;
		break;
	default :
		break;
	}
	
	if (myMplayerTask) {
		switch (myState) {
		case kPlaying:
			if(!myFullscreen) [self sendCommand:@"osd 0"];
			[self sendCommand:[NSString stringWithFormat:@"seek %1.1f %d",seconds, aMode]];
			[self sendCommand:@"osd 1"];
			break;
		case kPaused:
				[self sendCommand:@"pause"];
				if(!myFullscreen) [self sendCommand:@"osd 0"];
				[self sendCommand: [NSString stringWithFormat:@"seek %1.1f %d",seconds, aMode]];
				[self sendCommand:@"osd 1"];
				[self sendCommand:@"pause"];
			break;
		default :
			break;
		}
	}
}
/************************************************************************************/
- (void) performCommand:(NSString *)aCommand
{
	switch (myState) {
	case kPlaying:					// if is playing send it directly to player
		[self sendCommand:aCommand];
		break;
	case kStopped:					// if stopped do nothing
		break;
	default :						// otherwise save the command to the buffer
		[myCommandsBuffer addObject:aCommand];
		break;
	}
}

/************************************************************************************
 SETTINGS
 ************************************************************************************/
- (void) setMovieFile:(NSString *)aFile
{
	if (aFile) {
		if (![aFile isEqualToString:myMovieFile]) {
			[myMovieFile autorelease];
			myMovieFile = [aFile retain];
			settingsChanged = YES;
		}
	}
	else {
		if (myMovieFile) {
			[myMovieFile release];
			settingsChanged = YES;
		}
		myMovieFile = nil;
	}
}
/************************************************************************************/
- (void) setSubtitlesFile:(NSString *)aFile
{
	if (aFile) {
		if (![aFile isEqualToString:mySubtitlesFile]) {
			[mySubtitlesFile autorelease];
			mySubtitlesFile = [aFile retain];
			settingsChanged = YES;
		}
	}
	else {
		if (mySubtitlesFile) {
			[mySubtitlesFile release];
			settingsChanged = YES;
		}
		mySubtitlesFile = nil;
	}
}

//beta
/************************************************************************************/
- (void) setAudioExportFile:(NSString *)aFile
{
	if (aFile) {
		if (![aFile isEqualToString:myAudioExportFile]) {
			[myAudioExportFile autorelease];
			myAudioExportFile = [aFile retain];
			settingsChanged = YES;
		}
	}
	else {
		if (myAudioExportFile) {
			[myAudioExportFile release];
			settingsChanged = YES;
		}
		myAudioExportFile = nil;
	}
}


/************************************************************************************/
- (void) setAudioFile:(NSString *)aFile
{
	if (aFile) {
		if (![aFile isEqualToString:myAudioFile]) {
			[myAudioFile autorelease];
			myAudioFile = [aFile retain];
			settingsChanged = YES;
		}
	}
	else {
		if (myAudioFile) {
			[myAudioFile release];
			settingsChanged = YES;
		}
		myAudioFile = nil;
	}
}


/************************************************************************************/
- (void) setFontFile:(NSString *)aFile
{
	if (aFile) {
		if (![aFile isEqualToString:myFontFile]) {
			[myFontFile autorelease];
			myFontFile = [aFile retain];
			settingsChanged = YES;
		}
	}
	else {
		if (myFontFile) {
			[myFontFile release];
			settingsChanged = YES;
		}
		myFontFile = nil;
	}
}
/************************************************************************************/
/************************************************************************************/
- (void) setMovieSize:(NSSize)aSize
{
	if (aSize.width != myMovieSize.width ||  aSize.height != myMovieSize.height) {
		myMovieSize = aSize;
		settingsChanged = YES;
	}
}
- (NSSize) movieSize
{	
	return myMovieSize;
}
/************************************************************************************/
- (void) setAspectRatio:(double)ratio;
{
	if (myAspectRatio != ratio) {
		myAspectRatio = ratio;
		settingsChanged = YES;
	}
}

/************************************************************************************/
- (void) setMonitorAspectRatio:(double)ratio
{
	if (myMonitorAspect != ratio) {
		myMonitorAspect = ratio;
		settingsChanged = YES;
	}
}
/************************************************************************************/
- (void) setDropFrames:(BOOL)aBool
{
	if (myDropFrames != aBool) {
		myDropFrames = aBool;
		if (myState == kPlaying || myState == kPaused)
			[myCommandsBuffer addObject:@"frame_drop"];
	}
}
/************************************************************************************/
- (void) setRebuildIndex:(BOOL)aBool
{
	if (myRebuildIndex != aBool) {
		myRebuildIndex = aBool;
		settingsChanged = YES;
	}
}
/************************************************************************************/
////NEW BETA CODE
//rootwin
- (void) setRootwin:(BOOL)aBool
{
	if (myRootwin != aBool) {
		myRootwin = aBool;
		settingsChanged = YES;
	}
}
//TILE
- (void) setTile:(BOOL)aBool
{
	if (myTile != aBool) {
		myTile = aBool;
		settingsChanged = YES;
	}
}
//NOSOUND
- (void) setnosound:(BOOL)aBool
{
	if (mynosound != aBool) {
		mynosound = aBool;
		settingsChanged = YES;
	}
}
//SECONDMONITOR
- (void) setSecondMonitor:(BOOL)aBool
{
	if (mySecondMonitor != aBool) {
		mySecondMonitor = aBool;
		settingsChanged = YES;
	}
}
//Video Out
- (void) setVideoOutModule:(int)module
{
#ifndef GNUSTEP
	if (myVOModule != module)
	{
		myVOModule = module;
		settingsChanged = YES;
	}
#endif
}
//postprocesing
- (void) setPostprocesing:(BOOL)aBool
{
	if (myPostprocesing != aBool) {
		myPostprocesing = aBool;
		settingsChanged = YES;
	}
}
////VIDEO_TS
/*
- (void) setVIDEO_TS:(BOOL)aBool
{
	if (myVIDEO_TS != aBool) {
		myVIDEO_TS = aBool;
		settingsChanged = YES;
	}
}
*/

/************************************************************************************/
- (void) setFullscreen:(BOOL)aBool
{
	if (myFullscreen != aBool) {
		myFullscreen = aBool;
		if (myState == kPlaying || myState == kPaused) {
			[myCommandsBuffer addObject:@"vo_fullscreen"];
			takeEffectImediately = YES;
		}
	}
}
- (BOOL) fullscreen
{
	return myFullscreen;
}
/************************************************************************************/
/************************************************************************************/
- (void) setSubtitlesEncoding:(NSString *)aEncoding
{
	if (aEncoding) {
		if (![aEncoding isEqualToString:mySubEncoding]) {
			[mySubEncoding release];
			mySubEncoding = [aEncoding retain];
			settingsChanged = YES;
		}
	}
}
/************************************************************************************/
- (void) setSubtitlesScaleMode:(unsigned int)aMode
{
	if (mySubScaleMode != aMode) {
		mySubScaleMode = aMode;
		settingsChanged = YES;
	}
	mySubScaleMode = aMode;
}
/************************************************************************************/
- (void) setSubtitlesScale:(unsigned int)aScale
{
	if (mySubScale != aScale) {
		mySubScale = aScale;
		settingsChanged = YES;
	}
}
/************************************************************************************/
- (void) setSubtitlesOutline:(unsigned int)aOutline
{
	if (mySubOutline != aOutline) {
		mySubOutline = aOutline;
		settingsChanged = YES;
	}
}
/************************************************************************************/
/************************************************************************************/
- (void) setVolume:(unsigned int)percents
{
	if (myVolume != percents) {
		myVolume = percents;
		if (myState == kPlaying || myState == kPaused)
			[myCommandsBuffer addObject:[NSString stringWithFormat:
					@"volume %d 1",myVolume]];
	}
}
/************************************************************************************/
- (void) setCacheSize:(unsigned int)kilobytes
{
	if (myCacheSize != kilobytes) {
		myCacheSize = kilobytes;
		settingsChanged = YES;
	}
}
/************************************************************************************/
- (void) setAdditionalParams:(NSArray *)params
{
	if (myAddParams && params) {
		if (![myAddParams isEqualToArray:params]) {
			if (myAddParams)
				[myAddParams release];
			
			if (params)
				myAddParams = [[NSArray arrayWithArray:params] retain];
			else
				myAddParams = nil;
			
			settingsChanged = YES;
		}
		return;
	}
	if (myAddParams == nil && params) {
		myAddParams = [[NSArray arrayWithArray:params] retain];
		settingsChanged = YES;
		return;
	}
	if (myAddParams && params == nil) {
		[myAddParams release];
		myAddParams = nil;
		settingsChanged = YES;
		return;
	}
}
/************************************************************************************/
/************************************************************************************/
- (void) applySettingsWithRestart:(BOOL)restartIt
{
	if ([self isRunning]) {
		if (settingsChanged && restartIt) {
			// all settings will be applied by restarting player
			restartingPlayer = YES;		// set it not to send termination notification
			[self play];				// restart playback if player is running
			takeEffectImediately = NO;
		}
		else {
			// only settings that don't need restart will be applied
			if ([myCommandsBuffer count] > 0) {
				NSMutableArray *commands = [NSMutableArray array];
				if (myState == kPaused) {
					if (takeEffectImediately) {
						[commands addObject:@"pause"];
						
						if(!myFullscreen) [commands addObject:@"osd 0"];
						[commands addObjectsFromArray:myCommandsBuffer];
						[commands addObject:@"osd 1"];
						[commands addObject:@"pause"];
						[self sendCommands:commands];
						[myCommandsBuffer removeAllObjects];
						takeEffectImediately = NO;
					}
					// else the commands will be sent on unpausing
				}
				else {
					if(!myFullscreen) [commands addObject:@"osd 0"];
					[commands addObjectsFromArray:myCommandsBuffer];
					[commands addObject:@"osd 1"];
					[self sendCommands:commands];
					[myCommandsBuffer removeAllObjects];
				}
			}
		}
	}
	
}
/************************************************************************************/
- (void) waitUntilExit
{
	if (isRunning) {
		[myMplayerTask waitUntilExit];
//		[self mplayerTerminated];		// remove observers to not recieve notif.
	}
}
/************************************************************************************
 INFO
 ************************************************************************************/
- (void) loadInfoBeforePlayback:(BOOL)aBool
{
	useIdentifyForPlayback = aBool;
}
/************************************************************************************/
- (NSDictionary *) loadInfo
{
	// clear the dictionary
	[myInfo removeAllObjects];
	
	// run mplayer for identify
	if (myMovieFile)
		[self runMplayerWithParams:[NSArray arrayWithObjects:myMovieFile, @"-identify", @"-frames",@"0", @"-ao", @"null", @"-vo", @"null", nil]];
	
	// wait until it exits
	[self waitUntilExit];
	
	if ([myInfo count] > 0)
		return myInfo;
	return nil;
}
/************************************************************************************/
- (NSDictionary *) info
{
	return myInfo;
}
/************************************************************************************/
- (int) status
{	
	return myState;		
}
/************************************************************************************/
- (float) seconds
{	
	return mySeconds;
}
/************************************************************************************/
- (BOOL) changesNeedsRestart
{
	if (myState > 0)
		return settingsChanged;
	return NO;
}
/************************************************************************************/
- (BOOL)isRunning
{	
	return isRunning;
}

- (BOOL)isWindowed
{	
	return windowedVO;
}
/************************************************************************************
 STATISTICS
 ************************************************************************************/
- (void) setUpdateStatistics:(BOOL)aBool
{
	myUpdateStatistics = aBool;
}
/************************************************************************************/
- (float) syncDifference
{
	return mySyncDifference;
}
/************************************************************************************/
- (int) cpuUsage
{
	return myCPUUsage;
}
/************************************************************************************/
- (int) cacheUsage
{
	return myCacheUsage;
}
/************************************************************************************/
- (int) droppedFrames
{
	return myDroppedFrames;
}
/************************************************************************************/
- (int) postProcLevel
{
	return myPostProcLevel;
}

/************************************************************************************
 ADVENCED
 ************************************************************************************/
- (void)sendCommand:(NSString *)aCommand
{
	[self sendToMplayersInput:[aCommand stringByAppendingString:@"\n"]];
}
/************************************************************************************/
- (void)sendCommands:(NSArray *)aCommands
{
	int i;
	for (i=0; i < [aCommands count]; i++) {
		[self sendToMplayersInput:[[aCommands objectAtIndex:i]
				stringByAppendingString:@"\n"]];
	}
}
/************************************************************************************/
- (void)runMplayerWithParams:(NSArray *)aParams
{
	NSMutableDictionary *env;

	// terminate mplayer if it is running
	if (myMplayerTask) {
		if (myState == kPaused && restartingPlayer)
			pausedOnRestart = YES;
		else
			pausedOnRestart = NO;
		[self stop];
		[myMplayerTask release];
	}
	
	// if no path or movie file specified the return
	if (!myPathToPlayer || !myMovieFile)
		return;
	
	// initialize  mplayer task object
	myMplayerTask=[[NSTask alloc] init];
	
	// create standard input and output for application
	[myMplayerTask setStandardInput: [NSPipe pipe]];
	[myMplayerTask setStandardOutput: [NSPipe pipe]];
	
	// add observer for termination of mplayer
	[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(mplayerTerminated) 
			name:NSTaskDidTerminateNotification
			object:myMplayerTask];
	// add observer for available data at mplayers output 
	[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(readOutputC:)
			name:NSFileHandleReadCompletionNotification
			object:[[myMplayerTask standardOutput] fileHandleForReading]];

	// set launch path and params
	[myMplayerTask setLaunchPath:myPathToPlayer];
	// set launch arguments
	
	[myMplayerTask setArguments:aParams];
	
	// get current environment and make appropriate changes
	env = [[[NSProcessInfo processInfo] environment] mutableCopy];
	[env autorelease];
	// enable bind-at-launch behavior for dyld to use DLL codecs
    [env setObject:@"1" forKey:@"DYLD_BIND_AT_LAUNCH"];
    [myMplayerTask setEnvironment:env];

	//Print Command line to console
	NSLog(@"Path to MPlayer: %s", [myPathToPlayer UTF8String] );
	int count = 0;
	
	for(count = 0; count < [aParams count]; count++ )
		NSLog(@"Arg: %s", [[aParams objectAtIndex:count] UTF8String] );

	// activate notification for available data at output
	[[[myMplayerTask standardOutput] fileHandleForReading]
			readInBackgroundAndNotify];
	// reset output read mode
	myOutputReadMode = 0;
	// launch mplayer task
	[myMplayerTask launch];
	isRunning = YES;
}
/************************************************************************************/
- (void)sendToMplayersInput:(NSString *)aCommand
{
    if (myMplayerTask) {
		if ([myMplayerTask isRunning]) {
			NSFileHandle *thePipe = [[myMplayerTask standardInput] fileHandleForWriting];
			[thePipe writeData:[aCommand dataUsingEncoding:NSASCIIStringEncoding]];
		}
	}
}
/************************************************************************************/
// should be removed!
- (void)terminateMplayer
{
	if (myMplayerTask) {
		if (isRunning) {
			[myMplayerTask terminate];
			[myMplayerTask waitUntilExit];
			[self mplayerTerminated];
		}
	}
}


/************************************************************************************
 NOTIFICATION HANDLERS
 ************************************************************************************/
- (void)mplayerTerminated
{
	int returnCode, bReadLog;
	
	// remove observers
	if (isRunning) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
				name: NSTaskDidTerminateNotification object:myMplayerTask];
		
		if (!restartingPlayer && myState > 0) {
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
			
			myState = kStopped;
			// save value to userInfo
			[userInfo setObject:[NSNumber numberWithInt:myState] forKey:@"PlayerStatus"];
			// post notification
			[[NSNotificationCenter defaultCenter]
					postNotificationName:@"MIStateUpdatedNotification"
					object:self
					userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
		}
		restartingPlayer = NO;
		isRunning = NO;
	}
	
	returnCode = [myMplayerTask terminationStatus];
	
	//abnormal mplayer task termination
	if (returnCode != 0)
	{
		NSLog(@"Abnormal playback error. mplayer returned error code: %d", returnCode);
		bReadLog = NSRunAlertPanel(@"Playback Error", @"Abnormal playback termination. Check log file for more information.", @"Open Log", @"Continue", nil);
		
		//Open Log file
		if(bReadLog)
		{
			NSTask *finderOpenTask;
			NSArray *finderOpenArg;
			NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/MPlayerOSX.log"];

			finderOpenArg = [NSArray arrayWithObject:logPath];
			finderOpenTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:finderOpenArg];
			
			if (!finderOpenTask)
				NSLog(@"Failed to launch the console.app");
		}
	}
}
/************************************************************************************/

/**
 * This method is notified whenever the Mplayer-task's file handle for reading has data.
 * The notification object has its data in the userInfo dictionary saved using the
 * NSFileHandleNotificationDataItem key.
 */
- (void)readOutputC:(NSNotification *)notification
{
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	unsigned dataLength = [(NSData *)[[notification userInfo]
			objectForKey:@"NSFileHandleNotificationDataItem"] length] / sizeof(char);
	char *stringPtr = NULL;
	char *dataPtr = malloc([(NSData *)[[notification userInfo]
			objectForKey:@"NSFileHandleNotificationDataItem"] length] + sizeof(char));
	
	// load data and terminate it with null character
	[[[notification userInfo] objectForKey:@"NSFileHandleNotificationDataItem"]
				getBytes:(void *)dataPtr];
	*(dataPtr+dataLength) = '\0';
	
	// register for another read
	[[[myMplayerTask standardOutput] fileHandleForReading]
			readInBackgroundAndNotify];	
	
	while (1) {
		char *tempPtr;
		
		// get the one line of data
		if (stringPtr == NULL)
			stringPtr = strtok((char *)dataPtr,"\n\r");
		else
			stringPtr = strtok(NULL,"\n\r");
		
		if  (stringPtr == NULL)
			break;
		
		if (strstr(stringPtr, "A:") == stringPtr ||
				strstr(stringPtr, "V:") == stringPtr) {
			double timeDifference = ([NSDate timeIntervalSinceReferenceDate] - myLastUpdate);
				
			// parse the output according to the preset mode
			if (timeDifference >= 1.0f) {
				float audioCPUUsage = 0;
				int videoCPUUsage = 0, voCPUUsage = 0;
				int hours = 0, mins = 0;
				myLastUpdate = [NSDate timeIntervalSinceReferenceDate];
				
				if (myUpdateStatistics) {
					switch (myOutputReadMode) {
					case 0:
					case 1:
						if (sscanf(stringPtr, "A: %f V: %*f A-V: %f ct: %*f %*d/%*d %d%% %d%% %f%% %d %d %d%%",
								&mySeconds, &mySyncDifference, &videoCPUUsage, &voCPUUsage,
								&audioCPUUsage, &myDroppedFrames, &myPostProcLevel,
								&myCacheUsage) >= 7) {
							myCPUUsage = (int)(audioCPUUsage + videoCPUUsage + voCPUUsage);
							myOutputReadMode = 1;
							break;
						}
					case 2:			// only video
						// TODO: Test the next line is correct
						if (sscanf(stringPtr, "V: %f %*d/%d*%% %d%% %*f%% %d %d %d%%",
								&mySeconds, &videoCPUUsage, &voCPUUsage, &myDroppedFrames,
								&myPostProcLevel, &myCacheUsage) >= 5) {
							myCPUUsage = (int)(videoCPUUsage + voCPUUsage);
							myOutputReadMode = 2;
							break;
						}
					case 3:			// only audio
						if (sscanf(stringPtr, "A: %d:%2d:%f %f%% %d%%", &hours, &mins,
								&mySeconds, &audioCPUUsage, &myCacheUsage) >= 4) {
							myCPUUsage = (int)audioCPUUsage;
							mySeconds =+ (3600 * hours + 60 * mins);
						}
						else if (sscanf(stringPtr, "A: %2d:%f %f%% %d%%", &mins,
								&mySeconds, &audioCPUUsage, &myCacheUsage) >= 3) {
							myCPUUsage = (int)audioCPUUsage;
							mySeconds =+ 60 * mins;
						}
						else if (sscanf(stringPtr, "A: %f %f%% %d%%", &mySeconds,
								&audioCPUUsage, &myCacheUsage) >= 2) {
							myCPUUsage = (int)audioCPUUsage;
						}
						else {
							myOutputReadMode = 0;
							break;
						}
						myOutputReadMode = 3;
						break;
					default :
						break;
					}
				}
				else {
					switch (myOutputReadMode) {
					case 0:
					case 1:
						if (sscanf(stringPtr, "A: %f V: %*f A-V: %f", &mySeconds,
								&mySyncDifference) == 2) {
							myOutputReadMode = 1;
							break;
						}
					case 2:
						if (sscanf(stringPtr, "V: %f ", &mySeconds) == 1) {
							myOutputReadMode = 2;
							break;
						}
					case 3:
						if (sscanf(stringPtr, "A: %d:%2d:%f ", &hours, &mins,
								&mySeconds) == 3) {
							mySeconds += (3600 * hours + 60 * mins);
							myOutputReadMode = 3;
							break;
						}
						else if (sscanf(stringPtr, "A: %2d:%f ", &mins, &mySeconds) == 2) {
							mySeconds += 60 * mins;
							myOutputReadMode = 3;
							break;
						}
						else if (sscanf(stringPtr, "A: %f ", &mySeconds) == 1) {
							myOutputReadMode = 3;
							break;
						}
					default :
						break;
					}
				}
				
				// if the line was parsed then post notification and continue on next line
				if (myOutputReadMode > 0) {
					// if it was not playing before (launched or unpaused)
					if (myState != kPlaying) {
						myState = kPlaying;
						[userInfo setObject:[NSNumber numberWithInt:myState] forKey:@"PlayerStatus"];
						
						// perform commands buffer
						if(!myFullscreen) [self sendCommand:@"osd 0"];
						[self sendCommands:myCommandsBuffer];
						[self sendCommand:@"osd 1"];
						[myCommandsBuffer removeAllObjects];	// clear command buffer
			
						continue; 							// continue on next line
					}
			
					// post notification
					[[NSNotificationCenter defaultCenter]
							postNotificationName:@"MIStateUpdatedNotification"
							object:self
							userInfo:nil];
					[userInfo removeAllObjects];
					continue;
				}
				else
					myOutputReadMode = 0;
			}
			else
				continue;
		}
/*	
		// if we don't have output mode try to parse playback output and get output mode
		if (myOutputReadMode == 0) {
			float aFloat;
			int aInt;
			if (sscanf(stringPtr,
					"A: %f V: %*f A-V: %f ct: %*f %*d/%*d %d%% %d%% %*f%% %d %d %d%%",
					&aFloat, &aFloat, &aInt, &aInt, &aInt, &aInt, &aInt) == 7)
				myOutputReadMode = 1;			// audio and video
			else if (sscanf(stringPtr, "V: %f %*d %d%% %d%% %*f%% %d %d %d%%",
					&aFloat, &aInt, &aInt, &aInt, &aInt, &aInt) == 6)
				myOutputReadMode = 2;			// only video
			else if (sscanf(stringPtr, "A: %d:%2d:%f %f%% %d%%",
					&aInt, &aInt, &aFloat, &aFloat, &aInt) == 3)
				myOutputReadMode = 3;			// only audio in hours:minutes:seconds
			else if (sscanf(stringPtr, "A: %2d:%f %f%% %d%%",
					&aInt, &aFloat, &aFloat, &aInt) == 3)
				myOutputReadMode = 4;			// only audio in minutes:second
			else if (sscanf(stringPtr, "A: %f %f%% %d%%",
					&aFloat, &aFloat, &aInt) == 3)
				myOutputReadMode = 5;			// only audio in seconds
		}
*/		
		//  =====  PAUSE  ===== test for paused state
		if (strstr(stringPtr, MI_PAUSED_STRING) != NULL) {
			myState = kPaused;		
			[userInfo setObject:[NSNumber numberWithInt:myState] forKey:@"PlayerStatus"];
			printf("%s\n",stringPtr);
			
			continue; 							// continue on next line
		}

		// Exiting... test for player termination
		if ((tempPtr = strstr(stringPtr, MI_EXITING_STRING)) != NULL) {
			// if user quits player
			if (strncmp(tempPtr, MI_EXITING_QUIT_STRING, 17) == 0)
				myState = kStopped;
			// if player reaches end of file
			if (strncmp(tempPtr, MI_EXITING_EOF_STRING, 24) == 0)
				myState = kFinished;
			// remove observer for output
				// it's here because the NSTask sometimes do not terminate
				// as it is supposed to do
			[[NSNotificationCenter defaultCenter] removeObserver:self
					name: NSFileHandleReadCompletionNotification
					object:[[myMplayerTask standardOutput] fileHandleForReading]];

			// when player is not restarting
			if (!restartingPlayer) {
				// save value to userInfo
				[userInfo setObject:[NSNumber numberWithInt:myState] forKey:@"PlayerStatus"];
			}

			myOutputReadMode = 0;				// reset output read mode
			
			restartingPlayer = NO;
			printf("%s\n",stringPtr);
			continue;							// continue on next line
		}
		
		// if player is playing then do not bother with parse anything else
		if (myOutputReadMode > 0)
			continue;
		
		
		// mplayer starts to open a file
		if (strncmp(stringPtr, MI_OPENING_STRING, 8) == 0) {
			myState = kOpening;
			[userInfo setObject:[NSNumber numberWithInt:myState] forKey:@"PlayerStatus"];
			printf("%s\n",stringPtr);
			continue; 							// continue on next line	
		}
		
		// filling cache
		if (strncmp(stringPtr, "Cache fill:", 11) == 0) {
			float cacheUsage;
			myState = kBuffering;
			[userInfo setObject:[NSNumber numberWithInt:myState] forKey:@"PlayerStatus"];
			if (sscanf(stringPtr, "Cache fill: %f%%", &cacheUsage) == 1) {
				[userInfo setObject:[NSNumber numberWithFloat:cacheUsage]
						forKey:@"CacheUsage"];
				myCacheUsage = cacheUsage;
			}
			// if the string is longer then supposed divide it and continue
			printf("%s\n",stringPtr);
			if (strlen(stringPtr) > 32) {
				*(stringPtr + 31) = '\0';
				stringPtr = (stringPtr + 32);
			}
			else								// if string is not longer than supposed
				continue; 						// continue on next line
		}
		// get format of audio
		if (strstr(stringPtr, MI_AUDIO_FILE_STRING) != NULL) {
			[myInfo setObject:@"Audio" forKey:@"ID_FILE_FORMAT"];
			continue; 							// continue on next line	
		}
		// get format of movie
		tempPtr = strstr(stringPtr, " file format detected.");
		if (tempPtr != NULL) {
			*(tempPtr) = '\0';
			[myInfo setObject:[NSString stringWithCString:stringPtr] forKey:@"ID_FILE_FORMAT"];
			continue; 							// continue on next line	
		}

		// rebuilding index
		if ((tempPtr = strstr(stringPtr, "Generating Index:")) != NULL) {
			int cacheUsage;
			myState = kIndexing;
			[userInfo setObject:[NSNumber numberWithInt:myState] forKey:@"PlayerStatus"];
			if (sscanf(tempPtr, "Generating Index: %d", &cacheUsage) == 1) {
				[userInfo setObject:[NSNumber numberWithInt:cacheUsage]
						forKey:@"CacheUsage"];
				myCacheUsage = cacheUsage;
			}
			printf("%s\n",stringPtr);
			continue; 							// continue on next line	
		}
		
		// getting -identif parameters
		if (strncmp(stringPtr, "ID_", 3) == 0)
		{
			char *valString = strchr(stringPtr, '=');	// find the equation mark
			if (valString != NULL)
			{
				*valString = '\0';					// replace it with null char
				valString++;						// and the value starts by next char
				/* Make sure the value exists.
				 * It will be nil if the encoding is not right.
				 */
				NSString *value, *key;
				value = [NSString stringWithCString: valString];
				key = [NSString stringWithCString: stringPtr];
				if ((value != nil) && (key != nil))
				[myInfo setObject: value forKey: key];
			}
			continue; 							// continue on next line	
		}
		
		// mplayer is starting playback
		if (strstr(stringPtr, MI_STARTING_STRING) != NULL) {
			myState = kPlaying;
			myLastUpdate = [NSDate timeIntervalSinceReferenceDate];
			[userInfo setObject:[NSNumber numberWithInt:myState] forKey:@"PlayerStatus"];
	
			// perform commands buffer
			if(!myFullscreen) [self sendCommand:@"osd 0"];
			[self sendCommand:[NSString stringWithFormat:@"volume %d 1",myVolume]];
			[self sendCommands:myCommandsBuffer];
			[self sendCommand:@"osd 1"];
			if (pausedOnRestart)
				[self sendCommand:@"pause"];
			[myCommandsBuffer removeAllObjects];
	
			// post status playback start
			[[NSNotificationCenter defaultCenter]
					postNotificationName:@"MIInfoReadyNotification"
					object:self
					userInfo:nil];
			printf("%s\n",stringPtr);
			continue;
		}
		
		// print unused output
		printf("%s\n",stringPtr);
	} // while
	
	// post notification if there is anything in user info
	if ([userInfo count] > 0) {
		// post notification
		[[NSNotificationCenter defaultCenter]
				postNotificationName:@"MIStateUpdatedNotification"
				object:self
				userInfo:userInfo];
		[userInfo removeAllObjects];
	}

	free((char *)dataPtr);
}

@end

/************************************************************************************/
