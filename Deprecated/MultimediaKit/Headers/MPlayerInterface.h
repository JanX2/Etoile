// Modified by Yen-Ju Chen
/*
 *  MplayerInterface.h
 *  MPlayer OS X
 *
 *	version 1.1
 *
 *	Description:
 *		Interface to MPlayer binary application that is supposed to simplify the access
 *	to the application controlls and state values while handling inconsistent states of
 *	player
 *
 *  Created by Jan Volf
 *	<javol@seznam.cz>
 
 *  Copyright (c) 2003 Jan Volf. All rights reserved.
 */


#import <AppKit/AppKit.h>
 
// Notifications posted by MplayerInterface
	// 	@"MIPlayerTerminatedNotification"	mplayer has been terminated
	// 	@"MIInfoReadyNotification"			notification has been updated
	// 	@"MIStateUpdatedNotification"		status updated

// status update notification info keys
	//	@"PlayerStatus"				NSNumber - int (player status constants)
	//	@"MovieSeconds"				NSNumber - float
	//	@"SyncDifference"			NSNumber - float
	//	@"DroppedFrames"			NSNumber - int
	//	@"PostProcessingLevel"		NSNumber - int
	//	@"CPUUsage"					NSNumber - float percents
	//	@"CacheUsage"				NSNumber - float percents

// keys to mplayer info dictionary (all represents NSString objects)
	//	@"ID_FILENAME"				file path
	//	@"ID_FILE_FORMAT"			media format (AVI,MOV....)
	//	@"ID_VIDEO_FORMAT"			video codec
	//	@"ID_VIDEO_BITRATE"
	//	@"ID_VIDEO_WIDTH"
	//	@"ID_VIDEO_HEIGHT"
	//	@"ID_VIDEO_FPS"
	//	@"ID_VIDEO_ASPECT"
	//	@"ID_AUDIO_CODEC"
	//	@"ID_AUDIO_FORMAT"
	//	@"ID_AUDIO_BITRATE"			Bits per second
	//	@"ID_AUDIO_RATE"			kHz
	//	@"ID_AUDIO_NCH"				number of channels
	//	@"ID_LENGTH"				length in seconds

// player status constants
#define kFinished					-1	// terminated by reaching end-of-file
#define kStopped					0	// terminated by not reaching EOF
#define kPlaying					1
#define kPaused						2
#define kOpening					3
#define kBuffering					4
#define kIndexing					5

// seeking modes
#define	MIRelativeSeekingMode		0	// relative seeking in seconds 
#define	MIPercentSeekingMode		1	// absolute seeking in percents
#define	MIAbsoluteSeekingMode		2	// absolute seeking in seconds

// default constants
#define kDefaultMovieSize 			NSMakeSize(0,0)

@interface MplayerInterface : NSObject
{
// Properties
	// file paths
	NSString *myPathToPlayer;
	NSString *myMovieFile;
	NSString *mySubtitlesFile;
	NSString *myAudioFile;
	NSString *myAudioExportFile;
	NSString *myFontFile;
	
	// visual properties
	NSSize myMovieSize;
	double myAspectRatio;			// 0 =  no aspect, 4:3 = 1.3333, 16:9 = 1.7777
	double myMonitorAspect;
	BOOL myDropFrames;
	BOOL myRebuildIndex;
	BOOL myFullscreen;
	BOOL myRootwin;
	BOOL myTile;
	BOOL mynosound;
	BOOL mySecondMonitor;
	BOOL myPostprocesing;
#ifdef GNUSTEP
	int xwin;
#else
	int myVOModule;
#endif

	
	// subtitles properties
	NSString *mySubEncoding;
	unsigned int mySubScaleMode;
	unsigned int mySubScale;
	unsigned int mySubOutline;
	
	// misc properties
	unsigned int myCacheSize;
	

	NSArray *myAddParams;
	
	// state variables
	int	myState;				// player state
	unsigned int myVolume;		// volume 0-100
	
	//beta
	unsigned int myadvolume;
	float mySeconds;			// actual/saved seconds
	
	// statistics
	BOOL myUpdateStatistics;		// if set the following properties are periodicaly updated
	float mySyncDifference;		// difference in secconds between audion and video
	int myCPUUsage;			// overal player CPU usage
	int myCacheUsage;			// cache usage
	int	myDroppedFrames;		// number of dropped frames since last key frame
	int myPostProcLevel;		// actual level of postprocessing
	
	// internal use
	NSTask *myMplayerTask;
	double myLastUpdate;			// date when last update notificationa was sent
	BOOL settingsChanged;			// changed settings that requires player restart
	BOOL takeEffectImediately;		// changes have to take effect even in paused mode
	BOOL restartingPlayer;			// set when player is teminated to be restarted
	BOOL pausedOnRestart;			// set when paused during attemp to restart player
	BOOL isRunning;					// set off after recieving termination notification
	BOOL useIdentifyForPlayback;	// sets whether -identify is sent on starting playback
	BOOL windowedVO;
	int myOutputReadMode;				// defines playback output form 
	NSMutableArray *myCommandsBuffer;	// store cmds that cannot be send immediatelly
	NSMutableDictionary *myInfo;	// dict filled by -identify command
}
// interface
// init and uninit
- (id) init;										// init
- (id) initWithPathToPlayer:(NSString *)aPath;		// init with movie file path

// playback controls (take effect imediately)
- (void) play;										// play item from saved time
- (void) stop;										// stops playback
- (void) pause;										// pause / unpause playback
- (void) seek:(float)seconds mode:(int)aMode;		// seek in movie
- (void) performCommand:(NSString *)aCommand;

// settings (take effect by using applySettingsWithRestart: message)
// setting files
- (void) setMovieFile:(NSString *)aFile;
- (void) setSubtitlesFile:(NSString *)aFile;
- (void) setAudioFile:(NSString *)aFile;
//beta
- (void) setAudioExportFile:(NSString *)aFile;

- (void) setFontFile:(NSString *)aFile;

// setting visuals
- (void) setMovieSize:(NSSize)aSize;				// set height to 0 to keep aspect ratio)
- (NSSize) movieSize;
- (void) setAspectRatio:(double)ratio;


- (void) setMonitorAspectRatio:(double)ratio;
- (void) setDropFrames:(BOOL)aBool;					// sets frame dropping
//
- (void) setRootwin:(BOOL)aBool;					// video on background
- (void) setTile:(BOOL)aBool;					// video as small screenshots
- (void) setnosound:(BOOL)aBool;					// disable audio output
- (void) setSecondMonitor:(BOOL)aBool;					// use second monitor -vo quartz:device_id=1
- (void) setPostprocesing:(BOOL)aBool;					// -vf pp
//- (void) setVIDEO_TS:(BOOL)aBool;					// dvd folder



- (void) setRebuildIndex:(BOOL)aBool;				// take effect after restarting playback
- (void) setFullscreen:(BOOL)aBool;					// set deafault playback mode to fullscreen
- (BOOL) fullscreen;
- (void) setVideoOutModule:(int)module;

// subtitles settings (don't work during playback)
- (void) setSubtitlesEncoding:(NSString *)aEncoding;// sets subtitles file encoding
- (void) setSubtitlesScaleMode:(unsigned int)aMode;	// sets subtitle scale mode (see man mplayer)
- (void) setSubtitlesScale:(unsigned int)aScale;	// sets subtitle scale in % (see man mplayer)
- (void) setSubtitlesOutline:(unsigned int)aOutline;// font outline in points

// misc settings (don't work during playback)
- (void) setVolume:(unsigned int)percents;			// set audio volume
- (void) setCacheSize:(unsigned int)kilobytes;		// set to 0 to disable it
- (void) setAdditionalParams:(NSArray *)params;		// allow to send it additional parameters

// other methods
- (void) applySettingsWithRestart:(BOOL)restartIt;	// applyes settings that require restart
- (void) waitUntilExit;

// info
- (void) loadInfoBeforePlayback:(BOOL)aBool;		// enables using of -identify param for playback
- (NSDictionary *) loadInfo;						// gets info returned by -identify (don't work during playback)
- (NSDictionary *) info;							// returns the content of info dictionary 
- (int) status;
- (float) seconds;									// returns number of seconds, elapsed
- (BOOL) changesNeedsRestart;						// retuns YES if changes needs restart
- (BOOL) isRunning;
- (BOOL) isWindowed;

// statistics
- (void) setUpdateStatistics:(BOOL)aBool;			// sets whether to update stats
- (float) syncDifference;
- (int) cpuUsage;
- (int) cacheUsage;
- (int) droppedFrames;
- (int) postProcLevel;

// advenced
- (void)sendCommand:(NSString *)aCommand;
- (void)sendCommands:(NSArray *)aCommands;
- (void)runMplayerWithParams:(NSArray *)aParams;
- (void)sendToMplayersInput:(NSString *)aCommand;
- (void)terminateMplayer;

// notification handlers
- (void) mplayerTerminated;
- (void) readOutputC:(NSNotification *)notification;
@end
