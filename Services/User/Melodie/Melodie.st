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

	addFiles: sender [
	| openPanel fm |
		openPanel := NSOpenPanel openPanel.
		openPanel setAllowsMultipleSelection: 1.
		openPanel setCanChooseDirectories: 0.
		openPanel runModalForTypes: (self KnownExtensions).
		
		fm := NSFileManager defaultManager.
		openPanel filenames foreach: [ :file |
			"TODO: restore the recursive directory add feature. fileExistsAtPath:isDirectory: takes a pointer for isDirectory."

			self addToMainModel:  (ETMusicFile alloc initWithPath: file).
			"mainModel addObject:  (ETMusicFile alloc initWithPath: file)."
		].

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
