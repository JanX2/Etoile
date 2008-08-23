NSObject subclass: EtoileTunesController
[
	| window  mainContainer  playlistContainer search  musicPlayerController URLTextField addURLWindow mainModel  playlistModel |

	KnownExtensions	[
		^ {'mp3'. 'ogg'. 'flac'. 'aac'. 'm4a'}.
	]

	LIBRARYPATH [
		^ 'MelodieLibrary'.	
	]

	deserialize [
	| deserializer |
		'Deserializing..' log.
		deserializer := (ETSerializer serializerWithBackend: (ETSerializerBackendBinary class)
		                                             forURL: (NSURL fileURLWithPath: (self LIBRARYPATH))) deserializer.
		deserializer setVersion: 0.
		mainModel := deserializer restoreObjectGraph.
	]

	newMainModel [
		mainModel := ETPlaylist alloc init.
	]

	serialize [
	| pool serializer |
		"'Serializing..' log.
		pool := NSAutoreleasePool new.
		serializer := ETSerializer serializerWithBackend: (ETSerializerBackendBinary class)
	                                                  forURL: (NSURL fileURLWithPath: (self LIBRARYPATH))."
		"FIXME: use a serialization method that doesn't need a C string"
		"serializer serializeObject:mainModel withName: 'library'."
		"pool release."
	]

	init [
		'init' log.
		(NSFileManager defaultManager fileExistsAtPath: (self LIBRARYPATH)) ifTrue:[ self deserialize.].
		mainModel = nil ifTrue: [ self newMainModel. ].
		playlistModel := ETPlaylist alloc init.
		^ self.
	]

	dealloc [
		mainModel release.
		playlistModel release.
		super dealloc.
	]

	applicationWillTerminate: aNotification [
		self serialize.
	]

	addToMainModel: obj [
		'Adding song: ' log.
		obj log.
		mainModel addObject: obj.
	]

	addPath: pathArg [
	| path |
		path := pathArg.
		(self KnownExtensions containsObject: (path pathExtension))
			ifTrue: [ self addToMainModel: (ETMusicFile alloc initWithPath: path). ]
			ifFalse: [ 'unknown extension: ' log. path log. ].
	]

	addFiles: sender [
	| openPanel filename fm |
		openPanel := NSOpenPanel openPanel.
		openPanel setAllowsMultipleSelection: 0.
		openPanel setCanChooseDirectories: 1.
		openPanel runModalForTypes: (self KnownExtensions).
			
		filename := openPanel filenames lastObject.
		fm := NSFileManager defaultManager.
		(fm enumeratorAtPath: filename) allObjects foreach: [ :subFile | self addPath: (filename stringByAppendingPathComponent: subFile). ].
		"(fm enumeratorAtPath: filename) allObjects foreach: [ :subFile |  mainModel addObject: subFile. ]."

		mainContainer reloadAndUpdateLayout.
	]


	addURL: sender [
	| string |
		addURLWindow orderOut: self.
		string := URLTextField stringValue stringByAddingPercentEscapesUsingEncoding: 4. 
		mainModel addObject: (ETMusicFile alloc initWithURL:(NSURL URLWithString:string)).
		mainContainer reloadAndUpdateLayout.
	]

	newPlaylist: sender [
	| newPlaylist |
		newPlaylist := ETPlaylist alloc init.
		newPlaylist addObject:(ETMusicFile alloc initWithURL:(NSURL URLWithString: 'http://scfire-chi0l-1.stream.aol.com/stream/1018')).
		playlistModel addObject: newPlaylist.
		playlistContainer reloadAndUpdateLayout.
	]

	awakeFromNib [
	| layoutObject |
		layoutObject := ETOutlineLayout layout.
	
		layoutObject setDisplayName: 'Title' forProperty: 'kETTitleProperty'.
		layoutObject setDisplayName: 'Artist' forProperty: 'kETArtistProperty'.
		layoutObject setDisplayName: 'Album' forProperty: 'kETAlbumProperty'.
		layoutObject setDisplayName: 'URL' forProperty: 'kETURLProperty'.
	
		layoutObject setDisplayedProperties:
		    {'icon'. 'kETTitleProperty'. 'kETArtistProperty'. 'kETAlbumProperty'. 'kETURLProperty' }.

		mainContainer setSource: (mainContainer layoutItem).
		mainContainer layoutItem setRepresentedObject: mainModel.
		mainContainer setLayout: layoutObject.
		mainContainer setHasVerticalScroller: 1.
		mainContainer setTarget: self.
		mainContainer reloadAndUpdateLayout.
		mainContainer setDoubleAction: 'doubleClickInContainer:'.

		playlistContainer setSource: (playlistContainer layoutItem).
		playlistContainer layoutItem setRepresentedObject: playlistModel.
		playlistContainer setLayout: (ETOutlineLayout layout).
		playlistContainer setHasVerticalScroller: 0.
		playlistContainer setTarget: self.
		playlistContainer setDoubleAction: 'doubleClickInContainer:'.
	]
	
	doubleClickInContainer: sender [
		 'Got double-click on ' log.
		sender doubleClickedItem log.
		' in ' log.
		sender log.

		musicPlayerController playObject: (sender doubleClickedItem) start: 1.
	]
]

NSObject subclass: MusicPlayerController
[
	| positionSlider volumeSlider songLabel playPauseButton previousButton nextButton
	  uiUpdateTimer player |
	
	init [
		player := MKMusicPlayer alloc initWithDefaultDevice inNewThread.
		player retain.

		uiUpdateTimer := NSTimer scheduledTimerWithTimeInterval: 1
		                                                 target: self
		                                               selector: 'timerEvent:'
		                                               userInfo: nil
		                                                repeats: 1.
		^ self.
	]

	dealloc [
		uiUpdateTimer invalidate.
		player release.
		super dealloc.
	]

	awakeFromNib [
		playPauseButton setImage: ((IKIcon iconWithIdentifier: 'media-playback-start') image).
		nextButton setImage: ((IKIcon iconWithIdentifier: 'go-next') image).
		previousButton setImage: ((IKIcon iconWithIdentifier: 'go-previous') image).	
		volumeSlider setIntValue: (player volume).
	]

	play [
		player play.
	]

	pause [
		player pause.
		playPauseButton setImage: ((IKIcon iconWithIdentifier: 'media-playback-start') image).
	]

	playPause: sender [
		player isPlaying ifTrue: [ self pause. ]
		                ifFalse: [ self play. ].
	]

	setPosition: sender [
		player seekTo: (positionSlider intValue).
	]

	setVolume: sender [
		player setVolume: (volumeSlider intValue).
	]

	next: sender [
		player next.
	]

	previous: sender
	[
		'TODO: previous' log.
	]

	playObject: anObject start: shouldStart [
		'Playing URL: ' log.
		anObject representedObject URL log.
		player stop.
		player addURL: (anObject representedObject URL).
		shouldStart ifTrue: [ self play. ].
		player play.
	]

	setIconToPlay [
		" Workaround until ivar access from within blocks works."
		 playPauseButton setImage: ((IKIcon iconWithIdentifier: 'media-playback-pause') image).
	]

	setIconToPause [
		 playPauseButton setImage: ((IKIcon iconWithIdentifier: 'media-playback-start') image).
	]

	timerEvent: sender [
		player isPlaying ifTrue: ['playing' log. self setIconToPlay. ] 
		                  ifFalse: ['paused' log. self setIconToPause. ].
		positionSlider setMaxValue: (player duration).
		positionSlider setIntValue: (player currentPosition).
	]
]
